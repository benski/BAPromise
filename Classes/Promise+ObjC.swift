//
//  Promise+ObjC.swift
//  OS X
//
//  Created by Ben Allison on 8/21/18.
//  Copyright © 2018 Ben Allison. All rights reserved.
//

import Foundation

public class BAPromiseNilError : Error {
    
}

extension Promise where ValueType : AnyObject {
    public func objcPromise() -> BAPromise<ValueType> {
        let baPromise = BAPromise<ValueType>()
        let token = self.then({ (value) in
            baPromise.fulfill(with: value)
        }, rejected: { (error) in
            baPromise.rejectWithError(error)
        }, queue: baPromise.queue)

        baPromise.cancelled {
            token.cancel()
        }
        return baPromise
    }
    /* benski> I have not yet figured out how to get the compiler to genericize this on Optional<ValueType>
     so as a workaround, this goes down the rejection path with a BAPromiseNilErrors if the ObjC promise fulfills with a nil */
    public convenience init(from: BAPromise<ValueType>) {
        self.init()
        let cancelToken:BACancelToken = from.done({ (value: ValueType?) in
            if let value = value {
                self.fulfill(with: .success(value))
            } else {
                self.fulfill(with: .failure(BAPromiseNilError()))
            }
        }, rejected:{ error in
            self.fulfill(with: .failure(error))
        }, finally:{
            // noop
        })
        self.cancelled({
            cancelToken.cancel()
        }, on: DispatchQueue.main)
    }
}

public protocol PromiseTypeOptional: ExpressibleByNilLiteral {
    associatedtype WrappedType: AnyObject
    var baOptional: WrappedType? { get }
}

extension Optional: PromiseTypeOptional where Wrapped: AnyObject {
    public var baOptional: Wrapped? {
        return self
    }
}

extension Promise where ValueType: PromiseTypeOptional {
    // This lets a Promise<T?> convert to BAPromise<T>
    public func objcPromise() -> BAPromise<ValueType.WrappedType> {
        let baPromise = BAPromise<ValueType.WrappedType>()
        let token = self.then({ (value) in
            baPromise.fulfill(with: value.baOptional)
        }, rejected: { (error) in
            baPromise.rejectWithError(error)
        }, queue: baPromise.queue)

        baPromise.cancelled {
            token.cancel()
        }
        return baPromise
    }
}

extension Completable {
    public convenience init<T>(from: BAPromise<T>) {
        self.init()
        let cancelToken = from.done({ (value: T?) in
            self.fulfill(with: .success(()))
        }, rejected:{ error in
            self.fulfill(with: .failure(error))
        }, finally:{

        })
        self.cancelled({
            cancelToken.cancel()
        }, on: DispatchQueue.main)
    }
}
