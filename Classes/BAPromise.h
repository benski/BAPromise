//
//  BAPromise.h
//  BAPromise
//
//  Created by Ben Allison on 6/22/15.
//  Copyright (c) 2015 Ben Allison. All rights reserved.
//

#import <Foundation/Foundation.h>

/* block definitions */
typedef void (^BAPromiseOnFulfilledBlock)(id obj);
typedef void (^BAPromiseOnRejectedBlock)(NSError *error);
typedef id (^BAPromiseThenBlock)(id obj);
typedef NSError *(^BAPromiseThenRejectedBlock)(NSError *error);
typedef dispatch_block_t BAPromiseFinallyBlock;

// cancel token for promise
@interface BACancelToken : NSObject
-(void)cancel;
-(void)cancelled:(dispatch_block_t)onCancel;
@end

// promise consumer API
@interface BAPromise : BACancelToken
-(BACancelToken *)done:(BAPromiseOnFulfilledBlock)onFulfilled
              observed:(BAPromiseOnFulfilledBlock)onObserved
              rejected:(BAPromiseOnRejectedBlock)onRejected
               finally:(BAPromiseFinallyBlock)onFinally
                 queue:(dispatch_queue_t)queue;

/* helper methods to simplify API usage */
-(BACancelToken *)done:(BAPromiseOnFulfilledBlock)onFulfilled;
-(BACancelToken *)done:(BAPromiseOnFulfilledBlock)onFulfilled
              rejected:(BAPromiseOnRejectedBlock)onRejected;
-(BACancelToken *)rejected:(BAPromiseOnRejectedBlock)onRejected;

/* then (promise chaining) */
-(BAPromise *)then:(BAPromiseThenBlock)onFulfilled
          rejected:(BAPromiseThenRejectedBlock)onRejected
           finally:(BAPromiseFinallyBlock)onFinally
             queue:(dispatch_queue_t)queue;
@end

// promise producer API
@interface BAPromiseClient : BAPromise
-(void)fulfillWithObject:(id)obj;
-(void)rejectWithError:(NSError *)error;

/* helper methods to streamline syntax for nil objects*/
-(void)fulfill;
-(void)reject;
@end

@interface NSArray (PromiseJoin)
-(BAPromise *)joinPromises;
@end
