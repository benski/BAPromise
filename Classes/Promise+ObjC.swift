//
//  Promise+ObjC.swift
//  OS X
//
//  Created by Ben Allison on 8/21/18.
//  Copyright © 2018 Ben Allison. All rights reserved.
//

import Foundation

extension Promise where ValueType : AnyObject {
    public func objcPromise() -> BAPromise<ValueType> {
        let baPromise = BAPromise<ValueType>()
        let token = self.then({ (value) in
            baPromise.fulfill(with: value)
        }, rejected: { (error) in
            baPromise.rejectWithError(error)
        }, queue: baPromise.queue ?? DispatchQueue.main)
        baPromise.cancelled {
            token.cancel()
        }
        return baPromise
    }
}
