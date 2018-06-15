//
//  BAPromise.swift
//  OS X
//
//  Created by Ben Allison on 6/15/18.
//  Copyright © 2018 Ben Allison. All rights reserved.
//

import Foundation


class PromiseCancelToken {
    var cancelled : Bool = false
}

class Promise : PromiseCancelToken {

    enum PromiseState {
        case .unfulfilled
        case .fulfilled
        case .rejected
        case .canceled
    }
    
    class PromiseBlock {
        var done : ((Any) -> Void)?
        var observed : ((Any) -> Void)?
        var rejected : ((Error) -> Void)?
        var always : (() -> Void)?
        var queue : DispatchQueue?
        let cancellationToken : PromiseCancelToken
        
        let shouldKeepPromise {
            get {
                return done != nil || finally != nil || rejected != nil
            }
        }
        
        func call(with object: Any) {
            if let queue = queue {
                if !cancellationToken.cancelled {
                    if let error = object as? Error {
                        if let rejected = rejected {
                            rejected(error)
                        }
                    } else {
                        if let done = done {
                            done(object)
                        }
                        
                        if let observed = observed {
                            observed(object)
                        }
                    }
                    if let finally = finally {
                        finally()
                    }
                }
            }
        }
    }
    
    let queue : dispatch_queue_t = DispatchQueue()
    
    
    
}
