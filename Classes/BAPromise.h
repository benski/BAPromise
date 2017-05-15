//
//  BAPromise.h
//  BAPromise
//
//  Created by Ben Allison
//  Copyright (c) 2013 Ben Allison. MIT License. See LICENSE
//

#import <Foundation/Foundation.h>

/* block definitions */
typedef void (^BAPromiseOnFulfillBlock)(id value);
typedef void (^BAPromiseOnRejectedBlock)(NSError *error);
typedef id (^BAPromiseThenRejectedBlock)(NSError *error);
typedef dispatch_block_t BAPromiseFinallyBlock;

// cancel token for promise
@interface BACancelToken : NSObject
-(void)cancel;
-(void)cancelled:(dispatch_block_t)onCancel;
@end

// promise consumer API
NS_SWIFT_NAME(Promise)
@interface BAPromise<__covariant T> : BACancelToken
-(BACancelToken *)done:(void (^)(T obj))onFulfilled
              observed:(void (^)(T obj))onObserved
              rejected:(BAPromiseOnRejectedBlock)onRejected
               finally:(BAPromiseFinallyBlock)onFinally
                 queue:(dispatch_queue_t)queue
                thread:(NSThread *)thread;

/* then (promise chaining) */
-(BAPromise *)then:(id (^)(T obj))thenBlock
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
-(BACancelToken *)done:(void (^)(T obj))onFulfilled
                thread:(NSThread *)thread;

-(BAPromise *)then:(id (^)(T obj))onFulfilled;
-(BAPromise *)then:(id (^)(T obj))onFulfilled
             queue:(dispatch_queue_t)queue;
-(BAPromise *)then:(id (^)(T obj))onFulfilled
          rejected:(BAPromiseThenRejectedBlock)onRejected;
-(BAPromise *)then:(id (^)(T obj))onFulfilled
          rejected:(BAPromiseThenRejectedBlock)onRejected
           finally:(BAPromiseFinallyBlock)onFinally
             queue:(dispatch_queue_t)queue;
-(BAPromise *)then:(id (^)(T obj))onFulfilled
           finally:(BAPromiseFinallyBlock)onFinally;
-(BAPromise *)thenRejected:(BAPromiseThenRejectedBlock)onRejected;
-(BAPromise *)then:(id (^)(T obj))thenBlock
            thread:(NSThread *)thread;
-(BAPromise *)then:(id (^)(T obj))thenBlock
          rejected:(BAPromiseThenRejectedBlock)failureBlock
            thread:(NSThread *)thread;

// promise producer API
-(void)fulfillWithObject:(T)obj;
-(void)rejectWithError:(NSError *)error;

+(instancetype)fulfilledPromise:(T)obj;
+(instancetype)rejectedPromise:(NSError *)error;

// Unfortunate signature thanks to objc fukcing block syntax.
// This method takes one block "resolver" as a parameter, which takes two blocks "fulfill" and "reject".
+(nonnull instancetype)promiseWithResolver:(void (^ __nonnull)(void (^ __nonnull fulfill)(__nonnull T), void (^ __nonnull reject)(NSError * __nonnull)))resolver NS_SWIFT_NAME(init(_:));

/* helper methods to streamline syntax for nil objects*/
-(void)fulfill;
-(void)reject;

@end

__attribute__((deprecated))
@interface BAPromiseClient<__covariant T> : BAPromise<T>
@end

@interface NSArray (BAPromiseJoin)
/**
 *   @brief rejects if any single promise in the array rejects.
 *
 *   Method guarantees that the order of the resultant array is the same as the order of promises in the original array.
 */
-(nonnull BAPromise<NSArray *> *)whenPromises;
/**
 *   @brief rejects only if all promises reject. Otherwise, the fulfilled NSArray value will contain NSError entries in the appropriate array position for promises that have rejected.
 *
 *   Method guarantees that the order of the resultant array is the same as the order of promises in the original array.
 *    @code
 *    BAPromise <NSString *> *firstPromise = [[BAPromise alloc] init];
 *    BAPromise <NSString *> *secondPromise = [[BAPromise alloc] init];
 *    BAPromise <NSArray <NSString *>*> *promises = [@[firstPromise, secondPromise] joinPromises];
 *    
 *    [promises then:^id(NSArray *strings) {
 *          NSLog(@"firstPromise %@", strings[0]);
 *          NSLog(@"firstPromise is kind Of NSString %d", [strings[0] isKindOfClass:[NSString class]]);
 *          NSLog(@"secondPromise %@", strings[1]);
 *          NSLog(@"secondPromise is kind Of NSString %d", [strings[1] isKindOfClass:[NSString class]]);
 *          return nil;
 *     }];
 *     [firstPromise fulfillWithObject:@"Hello"];
 *     [secondPromise rejectWithError:nil];
 *
 *    // firstPromise Hello
 *    // firstPromise is kind Of NSString 1
 *    // secondPromise <null>
 *    // secondPromise is kind Of NSString 0
 *    @endcode
 */
-(nonnull BAPromise<NSArray *> *)joinPromises;
@end
