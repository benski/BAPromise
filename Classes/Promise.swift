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
    
    public typealias Canceled = () -> Void
    
    internal var cancelled: Bool = false
    static let queue = DispatchQueue(label: "com.github.benski.promise")
    var onCancel : Canceled?
    
    func cancelled(_ onCancel: @escaping Canceled, on queue: DispatchQueue) {
        let wrappedBlock = {
            queue.async {
                onCancel()
            }
        }
        
        PromiseCancelToken.queue.async {
            atomic_thread_fence(memory_order_acquire)
            if self.cancelled {
                wrappedBlock()
            } else {
                self.onCancel = wrappedBlock
            }
        }
    }
    
    func cancel() {
        cancelled = true
        atomic_thread_fence(memory_order_release)
        PromiseCancelToken.queue.async {
            self.onCancel?()
            self.onCancel = nil
        }
    }
}

public class Promise<ValueType> : PromiseCancelToken {
    
    public typealias Fulfilled = (ValueType) -> Void
    public typealias Rejected = (Error) -> Void
    public typealias Always = () -> Void
    
    var fulfilledObject: PromiseResult<ValueType>?

    public class PromiseBlock {
        var done: Fulfilled?
        var observed: Fulfilled?
        var rejected: Rejected?
        var always: Always?
        var queue: DispatchQueue
        let cancellationToken: PromiseCancelToken
        
        init(cancellationToken: PromiseCancelToken,
             queue: DispatchQueue) {
            self.cancellationToken = cancellationToken
            self.queue = queue
        }
        var shouldKeepPromise: Bool {
            return done != nil || always != nil || rejected != nil
        }
        
        func call(with object: PromiseResult<ValueType>) {
            queue.async {
                guard !self.cancellationToken.cancelled else { return }
                
                if case let .failure(error) = object {
                    self.rejected?(error)
                } else if case let .success(value) = object {
                    self.done?(value)
                    self.observed?(value)
                }
                self.always?()
            }
        }
    }
    
    @discardableResult func then(_ onFulfilled: Fulfilled? = nil,
                                 observed: Fulfilled? = nil,
                                 rejected: Rejected? = nil,
                                 always: Always? = nil,
                                 queue: DispatchQueue) -> PromiseCancelToken {
        let cancellationToken = PromiseCancelToken()
        let blocks = PromiseBlock(cancellationToken: cancellationToken, queue: queue)
        blocks.done = onFulfilled
        blocks.observed = observed
        blocks.rejected = rejected
        blocks.always = always
        
        cancellationToken.cancelled({ [weak self, weak blocks] in
            Promise.queue.async {
                guard let strongBlocks = blocks else { return }
                strongBlocks.done = nil
                strongBlocks.observed = nil
                strongBlocks.rejected = nil
                strongBlocks.always = nil
                
                guard let strongSelf = self else { return }
                if !strongSelf.blocks.contains(where: { $0.shouldKeepPromise }) {
                    strongSelf.cancel()
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
    
    fileprivate lazy var blocks: Array<PromiseBlock> = []

    override func cancelled(_ onCancel: @escaping Canceled, on queue: DispatchQueue) {
        let wrappedBlock = {
            queue.async {
                onCancel()
            }
        }
        
        PromiseCancelToken.queue.async {
            guard let fulfilledObject = self.fulfilledObject, fulfilledObject.resolved else {
                atomic_thread_fence(memory_order_acquire)
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

// creation
extension Promise {
    convenience init(_ value: ValueType) {
        self.init()
        self.fulfilledObject = .success(value)
    }
    
    convenience init(_ error: Error) {
        self.init()
        self.fulfilledObject = .failure(error)
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
            atomic_thread_fence(memory_order_acquire)
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
    public typealias ThenRejected<ReturnType> = (Error) -> PromiseResult<ReturnType>
    
    func then<ReturnType>(_ onFulfilled: @escaping ((ValueType) throws -> PromiseResult<ReturnType>),
                          rejected : @escaping ThenRejected<ReturnType> = { return .failure($0) },
                          queue : DispatchQueue) -> Promise<ReturnType> {
        var cancellationToken: PromiseCancelToken? = nil
        let returnedPromise = Promise<ReturnType>()
        returnedPromise.cancelled({
            cancellationToken?.cancel()            
        }, on: queue)

        cancellationToken = self.then({ value -> Void in
            do {
                let chained = try onFulfilled(value)
                returnedPromise.fulfill(with: chained)
            } catch let error {
                returnedPromise.fulfill(with: .failure(error))
            }
        }, rejected: { error in
            let chained = rejected(error)
            returnedPromise.fulfill(with: chained)
        }, queue: queue)
        
        return returnedPromise
    }
    
    // a simpler method to use when doing type conversion
    func map<ReturnType>(_ onFulfilled: @escaping ((ValueType) throws -> ReturnType),
                          queue : DispatchQueue) -> Promise<ReturnType> {
        return then({ (value) -> PromiseResult<ReturnType> in
            let chained = try onFulfilled(value)
            return .success(chained)
        }, queue: queue)
    }
}

// Join
extension Array {
    func when<ValueType>() -> Promise<Array<ValueType>> where Element == Promise<ValueType> {
        guard self.count > 0 else { return Promise<Array<ValueType>>([]) }
        var cancelTokens = [PromiseCancelToken]()
        
        let returnedPromise = Promise<Array<ValueType>> ()
        var results = Array<ValueType?>(repeating:nil, count:self.count)
        
        returnedPromise.cancelled({
            for token in cancelTokens {
                token.cancel()
            }
        }, on: PromiseCancelToken.queue)
        
        var remaining = self.count
        
        for (offset, promise) in self.enumerated() {
            let token = promise.then({ (value) in
                results[offset] = value
                remaining = remaining - 1
                if remaining == 0 {
                    returnedPromise.fulfill(with: .success(results.compactMap {$0}))
                }
            }, rejected: { (error) in
                returnedPromise.fulfill(with: .failure(error))
                for token in cancelTokens {
                    token.cancel()
                }
            }, queue: PromiseCancelToken.queue)
            cancelTokens.append(token)
        }
        
        return returnedPromise
    }
    
    func join <ValueType>() -> Promise<Array<PromiseResult<ValueType>>> where Element == Promise<ValueType>  {
        guard self.count > 0 else { return Promise<Array<PromiseResult<ValueType>>>([]) }
        var cancelTokens = [PromiseCancelToken]()
        
        let returnedPromise = Promise<Array<PromiseResult<ValueType>>> ()
        var results = Array<PromiseResult<ValueType>?>(repeating:nil, count:self.count)
        
        var remaining = self.count
        
        returnedPromise.cancelled({
            for token in cancelTokens {
                token.cancel()
            }
        }, on: PromiseCancelToken.queue)
        
        for (offset, promise) in self.enumerated() {
            let token = promise.then({ (value) in
                results[offset] = .success(value)
            }, rejected: { (error) in
                results[offset] = .failure(error)
            }, always: {
                remaining = remaining - 1
                if remaining == 0 {
                    returnedPromise.fulfill(with: .success(results.compactMap({$0})))
                }
            }, queue: PromiseCancelToken.queue)
            cancelTokens.append(token)
        }
        
        return returnedPromise
    }
}
