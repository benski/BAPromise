//
//  BAPromise.swift
//  OS X
//
//  Created by Ben Allison on 6/15/18.
//  Copyright © 2018 Ben Allison. All rights reserved.
//

import Foundation


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
              queue : DispatchQueue) {
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
    }
    
    lazy var blocks: Array<PromiseBlock> = []
}
