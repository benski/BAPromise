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
    
    public typealias Fulfilled = (ValueType) -> Void
    public typealias Rejected = (Error) -> Void
    public typealias Always = () -> Void
    
    public class PromiseBlock {
        var done: Fulfilled?
        var observed: Fulfilled?
        var rejected: Rejected?
        var always: Always?
        var queue: DispatchQueue?
        let cancellationToken: PromiseCancelToken
        
        init(cancellationToken: PromiseCancelToken) {
            self.cancellationToken = cancellationToken
        }
        var shouldKeepPromise: Bool {
            get {
                return done != nil || always != nil || rejected != nil
            }
        }
        
        private func internalCall(with object: PromiseResult<ValueType>) {
            guard !cancellationToken.cancelled else { return }
            
            if case let .failure(error) = object {
                rejected?(error)
            } else if case let .success(value) = object {
                done?(value)
                observed?(value)
            }
            always?()
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
    
    @discardableResult func then(_ onFulfilled: Fulfilled? = nil,
                                 observed: Fulfilled? = nil,
                                 rejected: Rejected? = nil,
                                 always: Always? = nil,
                                 queue: DispatchQueue) -> PromiseCancelToken {
        let cancellationToken = PromiseCancelToken()
        let blocks = PromiseBlock(cancellationToken: cancellationToken)
        blocks.queue = queue
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
        returnedPromise.cancelled({ cancellationToken?.cancel() }, on: queue)

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
    
    func map<ReturnType>(_ onFulfilled: @escaping ((ValueType) throws -> ReturnType),
                          queue : DispatchQueue) -> Promise<ReturnType> {
        var cancellationToken: PromiseCancelToken? = nil
        let returnedPromise = Promise<ReturnType>()
        returnedPromise.cancelled({ cancellationToken?.cancel() }, on: queue)
        
        cancellationToken = self.then({ value -> Void in
            do {
                let chained = try onFulfilled(value)
                returnedPromise.fulfill(with: .success(chained))
            } catch let error {
                returnedPromise.fulfill(with: .failure(error))
            }
        }, queue: queue)
        
        return returnedPromise
    }
}

// Join
extension Promise {
    // we can't currently have a templated extension (e.g. extension Array where Element = Promise<_>) so we have to do it this way
    class func when(promises: [Promise<ValueType>]) -> Promise<Array<ValueType>> {
        guard promises.count > 0 else { return Promise<Array<ValueType>>([]) }
        var cancelTokens = [PromiseCancelToken]()
        
        let returnedPromise = Promise<Array<ValueType>> ()
        var results = Array<ValueType?>(repeating:nil, count:promises.count)
        
        returnedPromise.cancelled({
            for token in cancelTokens {
                token.cancel()
            }
        }, on: Promise.queue)
        
        var remaining = promises.count
        
        for (offset, promise) in promises.enumerated() {
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
            }, queue: Promise.queue)
            cancelTokens.append(token)
        }
        
        return returnedPromise
    }
    
    class func join(promises: [Promise<ValueType>]) -> Promise<Array<PromiseResult<ValueType>>> {
        guard promises.count > 0 else { return Promise<Array<PromiseResult<ValueType>>>([]) }
        var cancelTokens = [PromiseCancelToken]()
        
        let returnedPromise = Promise<Array<PromiseResult<ValueType>>> ()
        var results = Array<PromiseResult<ValueType>?>(repeating:nil, count:promises.count)
        
        var remaining = promises.count
        
        returnedPromise.cancelled({
            for token in cancelTokens {
                token.cancel()
            }
        }, on: Promise.queue)
        
        for (offset, promise) in promises.enumerated() {
            let token = promise.then({ (value) in
                results[offset] = .success(value)
            }, rejected: { (error) in
                results[offset] = .failure(error)
            }, always: {
                remaining = remaining - 1
                if remaining == 0 {
                    returnedPromise.fulfill(with: .success(results.compactMap({$0})))
                }
            }, queue: Promise.queue)
            cancelTokens.append(token)
        }
        
        return returnedPromise
    }
}
