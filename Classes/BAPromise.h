//
//  BAPromise.h
//  BAPromise
//
//  Created by Ben Allison
//  Copyright (c) 2013 Ben Allison. MIT License. See LICENSE
//

#import <Foundation/Foundation.h>

/* block definitions */
typedef void (^BAPromiseOnFulfillBlock)(id _Nullable value);
typedef void (^BAPromiseOnRejectedBlock)(NSError * _Nonnull error);
typedef id _Nullable (^BAPromiseThenRejectedBlock)(NSError * _Nonnull error);
typedef dispatch_block_t BAPromiseFinallyBlock;

// cancel token for promise
@interface BACancelToken : NSObject
-(void)cancel;
-(void)cancelled:(nonnull dispatch_block_t)onCancel;
@end

// promise consumer API
@interface BAPromise<__covariant T> : BACancelToken
-(nonnull BACancelToken *)done:(void (^_Nullable)(T _Nullable obj))onFulfilled
                      observed:(void (^_Nullable)(T _Nullable obj))onObserved
                      rejected:(nullable BAPromiseOnRejectedBlock)onRejected
                       finally:(nullable BAPromiseFinallyBlock)onFinally
                         queue:(nullable dispatch_queue_t)queue
                        thread:(nullable NSThread *)thread;

/* then (promise chaining) */
-(nonnull BAPromise *)then:(id _Nullable (^_Nullable)(T _Nullable obj))thenBlock
          rejected:(nullable BAPromiseThenRejectedBlock)failureBlock
           finally:(nullable BAPromiseFinallyBlock)finallyBlock
             queue:(nullable dispatch_queue_t)myQueue
            thread:(nullable NSThread *)thread;

/* helper methods to simplify API usage */
-(nonnull BACancelToken *)done:(void (^ _Nullable)(T _Nullable obj))onFulfilled;
-(nonnull BACancelToken *)done:(void (^ _Nullable)(T _Nullable obj))onFulfilled
              rejected:(nullable BAPromiseOnRejectedBlock)onRejected;
-(nonnull BACancelToken *)done:(void (^ _Nullable)(T _Nullable obj))onFulfilled
               finally:(nullable BAPromiseFinallyBlock)onFinally;
-(nonnull BACancelToken *)done:(void (^ _Nullable)(T _Nullable obj))onFulfilled
              rejected:(nullable BAPromiseOnRejectedBlock)onRejected
                 queue:(nullable dispatch_queue_t)queue;
-(nonnull BACancelToken *)done:(void (^ _Nullable)(T _Nullable obj))onFulfilled
                      rejected:(nullable BAPromiseOnRejectedBlock)onRejected
                       finally:(nullable BAPromiseFinallyBlock)onFinally;
-(nonnull BACancelToken *)rejected:(nullable BAPromiseOnRejectedBlock)onRejected;
-(nonnull BACancelToken *)rejected:(nullable BAPromiseOnRejectedBlock)onRejected
                   finally:(nullable BAPromiseFinallyBlock)onFinally;
-(nonnull BACancelToken *)finally:(nullable BAPromiseFinallyBlock)onFinally;
-(nonnull BACancelToken *)done:(void (^ _Nullable)(T _Nullable obj))onFulfilled
              observed:(void (^ _Nullable)(T _Nullable obj))onObserved
              rejected:(nullable BAPromiseOnRejectedBlock)onRejected
               finally:(nullable BAPromiseFinallyBlock)onFinally
                 queue:(nullable dispatch_queue_t)queue;
-(nonnull BACancelToken *)done:(void (^ _Nullable)(T _Nullable obj))onFulfilled
                thread:(nullable NSThread *)thread;

-(nonnull BAPromise *)then:(id _Nullable (^ _Nullable)(T _Nullable obj))onFulfilled;
-(nonnull BAPromise *)then:(id _Nullable (^ _Nullable)(T _Nullable obj))onFulfilled
             queue:(nullable dispatch_queue_t)queue;
-(nonnull BAPromise *)then:(id _Nullable (^ _Nullable)(T _Nullable obj))onFulfilled
          rejected:(nullable BAPromiseThenRejectedBlock)onRejected;
-(nonnull BAPromise *)then:(id _Nullable (^ _Nullable)(T _Nullable obj))onFulfilled
          rejected:(nullable BAPromiseThenRejectedBlock)onRejected
           finally:(nullable BAPromiseFinallyBlock)onFinally
             queue:(nullable dispatch_queue_t)queue;
-(nonnull BAPromise *)then:(id _Nullable (^ _Nullable)(T _Nullable obj))onFulfilled
                   finally:(nullable BAPromiseFinallyBlock)onFinally;
-(nonnull BAPromise *)then:(id _Nullable (^ _Nullable)(T _Nullable obj))onFulfilled
                   finally:(nullable BAPromiseFinallyBlock)onFinally
                     queue:(nullable dispatch_queue_t)queue;
-(nonnull BAPromise *)thenRejected:(nullable BAPromiseThenRejectedBlock)onRejected;
-(nonnull BAPromise *)then:(id _Nullable (^ _Nullable)(T _Nullable obj))thenBlock
            thread:(nullable NSThread *)thread;
-(nonnull BAPromise *)then:(id _Nullable (^ _Nullable)(T _Nullable obj))thenBlock
          rejected:(nullable BAPromiseThenRejectedBlock)failureBlock
            thread:(nullable NSThread *)thread;

// promise producer API
-(void)fulfillWithObject:(nullable T)obj;
-(void)rejectWithError:(nonnull NSError *)error;
-(void)fulfillWithObject:(nullable T)object orRejectWithError:(nullable NSError *)error;
-(void (^ _Nonnull)(_Nullable T object,  NSError * _Nullable error))completionBlock;

+(nonnull instancetype)fulfilledPromise:(nullable T)obj;
+(nonnull instancetype)rejectedPromise:(nonnull NSError *)error;

// Unfortunate signature thanks to objc fukcing block syntax.
// This method takes one block "resolver" as a parameter, which takes two blocks "fulfill" and "reject".
+(nonnull instancetype)promiseWithResolver:(void (^ __nonnull)(void (^ __nonnull fulfill)(__nonnull T), void (^ __nonnull reject)(NSError * __nonnull)))resolver NS_SWIFT_NAME(init(_:));

/* helper methods to streamline syntax for nil objects*/
-(void)fulfill;
-(void)reject;

/* private! */
@property (nonatomic, strong, readonly) dispatch_queue_t queue;
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

/**
 *   @brief combines an array of Promise objects and non-Promise object into a Promise that returns a single array of non-Promise objects
 *
 *   e.g. [@1, @2, SomePromise, @4].
 *      if SomePromise resolves to @3, the returned promise will resolve to
 *        [@1, @2, @3, @4]
 *
 */
-(nonnull BAPromise<NSArray *> *)flattenPromises;

@end
