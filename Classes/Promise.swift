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
    
    public class PromiseBlock {
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
        
        private func internalCall(with object: Any) {
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
        
        func call(with object: Any) {
            if let queue = queue {
                queue.async {
                    self.internalCall(with: object)
                }
            } else {
                internalCall(with: object)
            }
        }
    }
    
    let queue = DispatchQueue(label: "Promise")
    
    
    
}
