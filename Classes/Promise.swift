//
//  BAPromise.swift
//  OS X
//
//  Created by Ben Allison on 6/15/18.
//  Copyright © 2018 Ben Allison. All rights reserved.
//

import Foundation

public enum PromiseResult {
    case success(Any?)
    case promise(Promise)
    case failure(Error)
}

public class PromiseCancelToken {
    enum PromiseState {
        case unfulfilled
        case fulfilled
        case rejected
        case canceled
    }
    
    var promiseState: PromiseState = .unfulfilled
    var cancelled: Bool = false
    static let queue = DispatchQueue(label: "com.github.benski.promise")
    var onCancel : (() -> Void)?
    
    func cancelled(_ onCancel: @escaping () -> Void, on queue: DispatchQueue) {
        let wrappedBlock = {
            queue.async {
                onCancel()
            }
        }
        
        PromiseCancelToken.queue.async {
            if self.promiseState != .rejected && self.promiseState != .fulfilled {
                if self.cancelled {
                    wrappedBlock()
                } else {
                    self.onCancel = wrappedBlock
                }
            }
        }
    }
    
    func cancel() {
        cancelled = true
        OSMemoryBarrier()
        PromiseCancelToken.queue.async {
            self.onCancel?()
            self.onCancel = nil
        }
    }
}

public class Promise : PromiseCancelToken {
    
    var fulfilledObject: Any?
    
    public class PromiseBlock {
        var done : ((Any?) -> Void)?
        var observed : ((Any?) -> Void)?
        var rejected : ((Error) -> Void)?
        var always : (() -> Void)?
        var queue : DispatchQueue?
        let cancellationToken : PromiseCancelToken
        
        init(cancellationToken: PromiseCancelToken) {
            self.cancellationToken = cancellationToken
        }
        var shouldKeepPromise: Bool {
            get {
                return done != nil || always != nil || rejected != nil
            }
        }
        
        private func internalCall(with object: Any?) {
            if !self.cancellationToken.cancelled {
                if let error = object as? Error {
                    rejected?(error)
                } else {
                    done?(object)
                    observed?(object)
                }
                always?()
            }
        }
        
        func call(with object: Any?) {
            if let queue = queue {
                queue.async {
                    self.internalCall(with: object)
                }
            } else {
                internalCall(with: object)
            }
        }
    }
    
    func done(_ onFulfilled: ((Any?) -> Void)? = nil,
              observed: ((Any?) -> Void)? = nil,
              rejected : ((Error) -> Void)? = nil,
              always : (() -> Void)? = nil,
              queue : DispatchQueue) -> PromiseCancelToken {
        let cancellationToken = PromiseCancelToken()
        let blocks = PromiseBlock(cancellationToken: cancellationToken)
        blocks.queue = queue
        blocks.done = onFulfilled
        blocks.observed = observed
        blocks.rejected = rejected
        blocks.always = always
        
        cancellationToken.cancelled({ [weak self, unowned blocks] in
            Promise.queue.async {
                if let `self` = self {                    
                    blocks.done = nil
                    blocks.observed = nil
                    blocks.rejected = nil
                    blocks.always = nil
                    
                    var strongCount = false
                    for block in `self`.blocks {
                        if block.shouldKeepPromise {
                            strongCount = true
                            break
                        }
                    }
                    if strongCount {
                        `self`.cancel()
                    }
                }
            }
        }, on: queue)
        
        switch(promiseState) {
        case .fulfilled, .rejected, .canceled:
            blocks.call(with: fulfilledObject)
        default:
            Promise.queue.async {
                switch(self.promiseState) {
                case .unfulfilled:
                    self.blocks.append(blocks)
                case .fulfilled, .rejected, .canceled:
                    blocks.call(with: self.fulfilledObject)
                }
            }
        }
        return cancellationToken
    }
    
    lazy var blocks: Array<PromiseBlock> = []
}

// fulfillment
extension Promise {
    
    func fulfill(with: PromiseResult) {
        switch(with) {
        case .success(let value):
            Promise.queue.async {
                guard self.promiseState == .unfulfilled else { return }
                self.fulfilledObject = value
                self.promiseState = .fulfilled
                for block in self.blocks {
                    block.call(with: value)
                }
                // remove references we'll never call now
                self.blocks.removeAll()
                self.onCancel = nil
            }
            
        case .failure(let error):
            Promise.queue.async {
                guard self.promiseState == .unfulfilled else { return }
                self.fulfilledObject = error
                self.promiseState = .rejected
                for block in self.blocks {
                    block.call(with: error)
                }
                // remove references we'll never call now
                self.blocks.removeAll()
                self.onCancel = nil
            }
            
        case .promise(let promise):
            if self.cancelled {
                promise.cancel()
            } else {
                let cancellationToken = promise.done({ self.fulfill(with: .success($0)) },
                                                     rejected: { self.fulfill(with: .failure($0)) },
                                                     queue: Promise.queue)
                
                self.cancelled({ cancellationToken.cancel() }, on: Promise.queue)
            }
        }
    }
}

// Then
extension Promise {
    func then(_ onFulfilled: ((Any?) -> PromiseResult)? = nil,
              rejected : ((Error) -> PromiseResult)? = nil,
              queue : DispatchQueue) -> Promise {
        var cancellationToken: PromiseCancelToken? = nil
        let returnedPromise = Promise()
        returnedPromise.cancelled({ cancellationToken?.cancel() }, on: queue)

        cancellationToken = self.done({ value in
            let chained = onFulfilled?(value) ?? .success(value)
            returnedPromise.fulfill(with: chained)
        }, rejected: { error in
            let chained = rejected?(error) ?? .failure(error)
            returnedPromise.fulfill(with: chained)
        }, queue: queue)
        
        return returnedPromise
    }
}
