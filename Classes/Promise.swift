//
//  BAPromise.swift
//  OS X
//
//  Created by Ben Allison on 6/15/18.
//  Copyright © 2018 Ben Allison. All rights reserved.
//

import Foundation

public enum PromiseResult<ValueType> {
    case success(ValueType)
    case promise(Promise<ValueType>)
    case failure(Error)
    
    var resolved: Bool {
        switch(self) {
        case .success, .failure:
            return true
        default:
            return false
        }
    }
    
    init(error: Error) {
        self = .failure(error)
    }
    
    init(promise: Promise<ValueType>) {
        self = .promise(promise)
    }
    
    init(value: ValueType) {
        self = .success(value)
    }
    
}

extension PromiseResult where ValueType == Void {
    static var success: PromiseResult {
        return .success(())
    }
    
    init() {
        self = .success(())
    }
}

public class PromiseCancelToken {
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
            if self.cancelled {
                wrappedBlock()
            } else {
                self.onCancel = wrappedBlock
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

public class Promise<ValueType> : PromiseCancelToken {
    
    var fulfilledObject: PromiseResult<ValueType>?
    
    public class PromiseBlock {
        var done : ((ValueType) -> Void)?
        var observed : ((ValueType) -> Void)?
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
        
        private func internalCall(with object: PromiseResult<ValueType>) {
            if !self.cancellationToken.cancelled {
                if case let .failure(error) = object {
                    rejected?(error)
                } else if case let .success(value) = object {
                    done?(value)
                    observed?(value)
                }
                always?()
            }
        }
        
        func call(with object: PromiseResult<ValueType>) {
            if let queue = queue {
                queue.async {
                    self.internalCall(with: object)
                }
            } else {
                internalCall(with: object)
            }
        }
    }
    
    @discardableResult func then(_ onFulfilled: ((ValueType) -> Void)? = nil,
                                 observed: ((ValueType) -> Void)? = nil,
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

        if let fulfilledObject = self.fulfilledObject, fulfilledObject.resolved {
            blocks.call(with: fulfilledObject)
        } else {
            Promise.queue.async {
                if let fulfilledObject = self.fulfilledObject, fulfilledObject.resolved {
                    blocks.call(with: fulfilledObject)
                } else {
                    self.blocks.append(blocks)
                }
            }
        }
        
        return cancellationToken
    }
    
    lazy var blocks: Array<PromiseBlock> = []

    override func cancelled(_ onCancel: @escaping () -> Void, on queue: DispatchQueue) {
        let wrappedBlock = {
            queue.async {
                onCancel()
            }
        }
        
        PromiseCancelToken.queue.async {
            guard let fulfilledObject = self.fulfilledObject, fulfilledObject.resolved else {
                if self.cancelled {
                    wrappedBlock()
                } else {
                    self.onCancel = wrappedBlock
                }
                return
            }
        }
    }

}

// fulfillment
extension Promise {
    
    func fulfill(with: PromiseResult<ValueType>) {
        switch(with) {
        case .success, .failure:
            Promise.queue.async {
                if let fulfilledObject = self.fulfilledObject, fulfilledObject.resolved { return }
                self.fulfilledObject = with
                for block in self.blocks {
                    block.call(with: with)
                }
                // remove references we'll never call now
                self.blocks.removeAll()
                self.onCancel = nil
            }
            
        case .promise(let promise):
            if self.cancelled {
                promise.cancel()
            } else {
                let cancellationToken = promise.then({ self.fulfill(with: .success($0)) },
                                                     rejected: { self.fulfill(with: .failure($0)) },
                                                     queue: Promise.queue)
                
                self.cancelled({ cancellationToken.cancel() }, on: Promise.queue)
            }
        }
    }
}

// Then
extension Promise {
    func then(_ onFulfilled: ((ValueType) -> PromiseResult<ValueType>)? = nil,
              rejected : ((Error) -> PromiseResult<ValueType>)? = nil,
              queue : DispatchQueue) -> Promise {
        var cancellationToken: PromiseCancelToken? = nil
        let returnedPromise = Promise()
        returnedPromise.cancelled({ cancellationToken?.cancel() }, on: queue)

        cancellationToken = self.then({ value -> Void in
            let chained = onFulfilled?(value) ?? .success(value)
            returnedPromise.fulfill(with: chained)
        }, rejected: { error in
            let chained = rejected?(error) ?? .failure(error)
            returnedPromise.fulfill(with: chained)
        }, queue: queue)
        
        return returnedPromise
    }
}
