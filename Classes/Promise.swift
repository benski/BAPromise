//
//  BAPromise.swift
//  OS X
//
//  Created by Ben Allison on 6/15/18.
//  Copyright © 2018 Ben Allison. All rights reserved.
//

import Foundation

internal class AtomicCancel {
    
    public var isCanceled: Bool {
        atomic_thread_fence(memory_order_seq_cst)
        return underlying == 0 ? false : true
    }
    
    public func cancel() {
        OSAtomicIncrement32Barrier(&underlying);
    }
    
    public init() {
        underlying = 0
    }
    
     private var underlying: Int32
}

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

/// this is mostly used for Unit Tests
extension PromiseResult : Equatable where ValueType: Equatable {
    public static func == (lhs: PromiseResult<ValueType>, rhs: PromiseResult<ValueType>) -> Bool {
        if case let .success(l) = lhs, case let .success(r) = rhs {
            return l == r
        }
        return false
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

extension Array {
    public func successes <ValueType>() -> [ValueType] where Element == PromiseResult<ValueType> {
        return compactMap {
             switch $0 {
             case .success(let value): return value
             default: return nil
             }
         }
    }
}

public class PromiseCancelToken {
    
    public typealias Canceled = () -> Void
    
    internal let cancelFlag: AtomicCancel = AtomicCancel()
    static let queue = DispatchQueue(label: "com.github.benski.promise")
    var onCancel : Canceled?
    
    public func cancelled(_ onCancel: @escaping Canceled, on queue: DispatchQueue) {
        let wrappedBlock = {
            queue.async {
                onCancel()
            }
        }
        
        PromiseCancelToken.queue.async {
            if self.cancelFlag.isCanceled {
                wrappedBlock()
            } else {
                self.onCancel = wrappedBlock
            }
        }
    }
    
    public func cancel() {
        cancelFlag.cancel()
        PromiseCancelToken.queue.async {
            self.onCancel?()
            self.onCancel = nil
        }
    }
}

extension Thread {
    @objc func baRunBlock(_ block: @escaping () -> Void) {
        block()
    }

    func baAsync(_ block: @escaping () -> Void) {
        perform(#selector(baRunBlock), on: self, with: block, waitUntilDone: false)
    }
}

public class Promise<ValueType> : PromiseCancelToken {
    
    public typealias Fulfilled = (ValueType) -> Void
    public typealias Observed = (PromiseResult<ValueType>) -> Void
    public typealias Rejected = (Error) -> Void
    public typealias Always = () -> Void
    
    var fulfilledObject: PromiseResult<ValueType>?

    public override init() {
        super.init()
    }
    
    public class PromiseBlock {
        var done: Fulfilled?
        var observed: Observed?
        var rejected: Rejected?
        var always: Always?
        var queue: DispatchQueue?
        var thread: Thread?
        let cancellationToken: PromiseCancelToken
        
        init(cancellationToken: PromiseCancelToken,
             queue: DispatchQueue) {
            self.cancellationToken = cancellationToken
            self.queue = queue
        }

        init(cancellationToken: PromiseCancelToken,
             thread: Thread) {
            self.cancellationToken = cancellationToken
            self.thread = thread
        }

        var shouldKeepPromise: Bool {
            return done != nil || always != nil || rejected != nil
        }
        
        func call(with object: PromiseResult<ValueType>) {
            let block = {
                guard !self.cancellationToken.cancelFlag.isCanceled else { return }

                self.observed?(object)
                if case let .failure(error) = object {
                    self.rejected?(error)
                } else if case let .success(value) = object {
                    self.done?(value)
                }
                self.always?()
            }
            if let queue = queue {
                queue.async(execute: block)
            } else if let thread = thread {
                thread.baAsync(block)
            }
        }
    }
    
    internal func internalThen(_ onFulfilled: Fulfilled? = nil,
                                 observed: Observed? = nil,
                                 rejected: Rejected? = nil,
                                 always: Always? = nil,
                                 queue: DispatchQueue? = nil,
                                 thread: Thread? = nil) -> PromiseCancelToken {
        let cancellationToken = PromiseCancelToken()
        let blocks: PromiseBlock
        if let queue = queue {
            blocks = PromiseBlock(cancellationToken: cancellationToken, queue: queue)
        } else if let thread = thread {
            blocks = PromiseBlock(cancellationToken: cancellationToken, thread: thread)
        } else {
            blocks = PromiseBlock(cancellationToken: cancellationToken, queue: .main)
        }
        blocks.done = onFulfilled
        blocks.observed = observed
        blocks.rejected = rejected
        blocks.always = always
        
        cancellationToken.cancelled({ [weak self, weak blocks] in
                guard let strongBlocks = blocks else { return }
                strongBlocks.done = nil
                strongBlocks.observed = nil
                strongBlocks.rejected = nil
                strongBlocks.always = nil
                
                guard let strongSelf = self else { return }
                if !strongSelf.blocks.contains(where: { $0.shouldKeepPromise }) {
                    strongSelf.cancel()
                }
            }, on: Promise.queue)

        Promise.queue.async {
            if let fulfilledObject = self.fulfilledObject, fulfilledObject.resolved {
                blocks.call(with: fulfilledObject)
            } else {
                self.blocks.append(blocks)
            }
        }
        
        return cancellationToken
    }

    @discardableResult public func then(_ onFulfilled: Fulfilled? = nil,
                                 observed: Observed? = nil,
                                 rejected: Rejected? = nil,
                                 always: Always? = nil,
                                 queue: DispatchQueue) -> PromiseCancelToken {
        return internalThen(onFulfilled, observed: observed, rejected: rejected, always: always, queue: queue, thread: nil)
    }

    @discardableResult public func then(_ onFulfilled: Fulfilled? = nil,
                                 observed: Observed? = nil,
                                 rejected: Rejected? = nil,
                                 always: Always? = nil,
                                 thread: Thread) -> PromiseCancelToken {
        return internalThen(onFulfilled, observed: observed, rejected: rejected, always: always,thread: thread)
    }
    
    fileprivate lazy var blocks: Array<PromiseBlock> = []

    public override func cancelled(_ onCancel: @escaping Canceled, on queue: DispatchQueue) {
        let wrappedBlock = {
            queue.async {
                onCancel()
            }
        }
        
        PromiseCancelToken.queue.async {
            guard let fulfilledObject = self.fulfilledObject, fulfilledObject.resolved else {
                if self.cancelFlag.isCanceled {
                    wrappedBlock()
                } else {
                    self.onCancel = wrappedBlock
                }
                return
            }
        }
    }
}

// MARK: - Completable ( Promise<Void> )

public typealias Completable = Promise<Void>

extension Promise {
    public class func completed() -> Completable {
        return Promise<Void>(())
    }
}

// MARK: - Creation
extension Promise {
    public convenience init(_ value: ValueType) {
        self.init()
        self.fulfilledObject = .success(value)
    }
    
    public convenience init(error: Error) {
        self.init()
        self.fulfilledObject = .failure(error)
    }
}
// fulfillment
extension Promise {
    
    public func fulfill(with: PromiseResult<ValueType>) {
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
            if self.cancelFlag.isCanceled {
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
    
    public func then<ReturnType>(_ onFulfilled: @escaping ((ValueType) throws -> PromiseResult<ReturnType>),
                          rejected : @escaping ThenRejected<ReturnType> = { return .failure($0) },
                          always: Always? = nil,
                          queue : DispatchQueue) -> Promise<ReturnType> {
        let returnedPromise = Promise<ReturnType>()

        let cancellationToken = self.then({ value -> Void in
            do {
                let chained = try onFulfilled(value)
                returnedPromise.fulfill(with: chained)
            } catch let error {
                returnedPromise.fulfill(with: .failure(error))
            }
        }, rejected: { error in
            let chained = rejected(error)
            returnedPromise.fulfill(with: chained)
        }, always: always,
           queue: queue)
        
        returnedPromise.cancelled({
            cancellationToken.cancel()
        }, on: queue)
        
        return returnedPromise
    }
    
    // a simpler method to use when doing type conversion
    public func map<ReturnType>(_ onFulfilled: @escaping ((ValueType) throws -> ReturnType),
                          queue : DispatchQueue) -> Promise<ReturnType> {
        return then({ (value) -> PromiseResult<ReturnType> in
            let chained = try onFulfilled(value)
            return .success(chained)
        }, queue: queue)
    }
    
    public func flatMap<ReturnType>(_ onFulfilled: @escaping ((ValueType) throws -> Promise<ReturnType>),
                         queue : DispatchQueue) -> Promise<ReturnType> {
        return then({ (value) -> PromiseResult<ReturnType> in
            let chained = try onFulfilled(value)
            return .promise(chained)
        }, queue: queue)
    }
}

// Join
extension Array {
    public func when<ValueType>() -> Promise<Array<ValueType>> where Element == Promise<ValueType> {
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
    
    public func join <ValueType>() -> Promise<Array<PromiseResult<ValueType>>> where Element == Promise<ValueType> {
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
    
    /// helper method to return only successes from a join()
    public func compactJoin<ValueType>() -> Promise<Array<ValueType>> where Element == Promise<ValueType> {
        return join().map({ $0.successes() }, queue: PromiseCancelToken.queue)
    }
}

extension Array where Element == Completable {
    public func join() -> Completable {
        guard self.count > 0 else { return .completed() }
        var cancelTokens = [PromiseCancelToken]()
        
        let returnedPromise = Completable()
        var remaining = self.count
        
        returnedPromise.cancelled({
            for token in cancelTokens {
                token.cancel()
            }
        }, on: PromiseCancelToken.queue)
        
        for promise in self {
            let token = promise.then(always: {
                remaining = remaining - 1
                if remaining == 0 {
                    returnedPromise.fulfill(with: .success)
                }
            }, queue: PromiseCancelToken.queue)
            cancelTokens.append(token)
        }
        
        return returnedPromise
    }
}
