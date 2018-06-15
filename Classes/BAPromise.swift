//
//  BAPromise.swift
//  OS X
//
//  Created by Ben Allison on 6/15/18.
//  Copyright © 2018 Ben Allison. All rights reserved.
//

import Foundation


public class PromiseCancelToken {
    var cancelled : Bool = false
}

public class Promise : PromiseCancelToken {

    enum PromiseState {
        case unfulfilled
        case fulfilled
        case rejected
        case canceled
    }
    
    class PromiseBlock {
        var done : ((Any) -> Void)?
        var observed : ((Any) -> Void)?
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
        
        func call(with object: Any) {
            if let queue = queue {
                queue.async {
                    if !self.cancellationToken.cancelled {
                        if let error = object as? Error {
                            if let rejected = self.rejected {
                                rejected(error)
                            }
                        } else {
                            if let done = self.done {
                                done(object)
                            }
                            
                            if let observed = self.observed {
                                observed(object)
                            }
                        }
                        if let always = self.always {
                            always()
                        }
                    }
                }
            }
        }
    }
    
    let queue = DispatchQueue(label: "Promise")
    
    
    
}
