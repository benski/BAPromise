//
//  BAPromise.h
//  BAPromise
//
//  Created by Ben Allison
//  Copyright (c) 2013 Ben Allison. MIT License. See LICENSE
//

#import <Foundation/Foundation.h>

/* block definitions */
typedef void (^BAPromiseOnRejectedBlock)(NSError *error);
typedef id (^BAPromiseThenRejectedBlock)(NSError *error);
typedef dispatch_block_t BAPromiseFinallyBlock;

// cancel token for promise
@interface BACancelToken : NSObject
-(void)cancel;
-(void)cancelled:(dispatch_block_t)onCancel;
@end

// promise consumer API
@interface BAPromise<__covariant T> : BACancelToken
-(BACancelToken *)done:(void (^)(T obj))onFulfilled
              observed:(void (^)(T obj))onObserved
              rejected:(BAPromiseOnRejectedBlock)onRejected
               finally:(BAPromiseFinallyBlock)onFinally
                 queue:(dispatch_queue_t)queue
                thread:(NSThread *)thread;

/* then (promise chaining) */
-(BAPromise *)then:(BAPromiseThenBlock)thenBlock
          rejected:(BAPromiseThenRejectedBlock)failureBlock
           finally:(BAPromiseFinallyBlock)finallyBlock
             queue:(dispatch_queue_t)myQueue
            thread:(NSThread *)thread;

/* helper methods to simplify API usage */
-(BACancelToken *)done:(void (^)(T obj))onFulfilled;
-(BACancelToken *)done:(void (^)(T obj))onFulfilled
              rejected:(BAPromiseOnRejectedBlock)onRejected;
-(BACancelToken *)done:(void (^)(T obj))onFulfilled
               finally:(BAPromiseFinallyBlock)onFinally;
-(BACancelToken *)done:(void (^)(T obj))onFulfilled
              rejected:(BAPromiseOnRejectedBlock)onRejected
                 queue:(dispatch_queue_t)queue;
-(BACancelToken *)done:(void (^)(T obj))onFulfilled
              rejected:(BAPromiseOnRejectedBlock)onRejected
               finally:(BAPromiseFinallyBlock)onFinally;
-(BACancelToken *)rejected:(BAPromiseOnRejectedBlock)onRejected;
-(BACancelToken *)rejected:(BAPromiseOnRejectedBlock)onRejected
                   finally:(BAPromiseFinallyBlock)onFinally;
-(BACancelToken *)finally:(BAPromiseFinallyBlock)onFinally;
-(BACancelToken *)done:(void (^)(T obj))onFulfilled
              observed:(void (^)(T obj))onObserved
              rejected:(BAPromiseOnRejectedBlock)onRejected
               finally:(BAPromiseFinallyBlock)onFinally
                 queue:(dispatch_queue_t)queue;

-(BAPromise *)then:(id (^)(T obj))onFulfilled;
-(BAPromise *)then:(id (^)(T obj))onFulfilled
             queue:(dispatch_queue_t)queue;
-(BAPromise *)then:(id (^)(T obj))onFulfilled
          rejected:(BAPromiseThenRejectedBlock)onRejected;
-(BAPromise *)then:(id (^)(T obj))onFulfilled
          rejected:(BAPromiseThenRejectedBlock)onRejected
           finally:(BAPromiseFinallyBlock)onFinally
             queue:(dispatch_queue_t)queue;
@end

// promise producer API
@interface BAPromiseClient<__covariant T> : BAPromise<T>
-(void)fulfillWithObject:(T)obj;
-(void)rejectWithError:(NSError *)error;

+(instancetype)fulfilledPromise:(T)obj;
+(instancetype)rejectedPromise:(NSError *)error;

/* helper methods to streamline syntax for nil objects*/
-(void)fulfill;
-(void)reject;
@end

@interface NSArray (BAPromiseJoin)
-(BAPromise<NSArray *> *)whenPromises;
-(BAPromise<NSArray *> *)joinPromises;
@end
