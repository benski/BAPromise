//
//  BAPromise.m
//  BAPromise
//
//  Created by Ben Allison
//  Copyright (c) 2013 Ben Allison. MIT License. See LICENSE
//

#import "BAPromise.h"

static dispatch_queue_t ba_dispatch_get_current_queue()
{
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
    return dispatch_get_current_queue();
#pragma GCC diagnostic pop
}

typedef void (^BAPromiseOnFulfilledBlock)(id obj);
typedef id (^BAPromiseThenBlock)(id obj);

typedef NS_ENUM(NSInteger, BAPromiseState) {
    BAPromise_Unfulfilled,
    BAPromise_Fulfilled,
    BAPromise_Rejected,
    BAPromise_Canceled,
};

@interface BACancelToken ()
@property (nonatomic, strong) dispatch_queue_t queue;
@property (nonatomic) BAPromiseState promiseState;
@property (atomic) BOOL cancelled;
@property (nonatomic, copy) dispatch_block_t onCancel;
@end

@implementation BACancelToken
-(instancetype)init
{
    self = [super init];
    if (self) {
        _queue = dispatch_queue_create(nil, DISPATCH_QUEUE_SERIAL);
        _promiseState = BAPromise_Unfulfilled;
        self.cancelled = NO;
    }
    return self;
}

-(void)cancelled:(dispatch_block_t)onCancel
{
    dispatch_queue_t currentQueue = ba_dispatch_get_current_queue();
    dispatch_block_t wrappedCancelBlock = ^ {
        dispatch_async(currentQueue, ^{
            onCancel();
        });
    };
    
    dispatch_async(_queue, ^{
        if (_promiseState != BAPromise_Rejected && _promiseState != BAPromise_Fulfilled) {
            if (self.cancelled) {
                wrappedCancelBlock();
            } else {
                self.onCancel = wrappedCancelBlock;
            }
        }
    });
}

-(void)cancel
{
    self.cancelled = YES;
    dispatch_async(self.queue, ^{
        if (self.onCancel) {
            self.onCancel();
            self.onCancel=nil;
        }
    });
}
@end

@interface BAPromiseBlocks : NSObject
@property (nonatomic, copy) BAPromiseOnFulfilledBlock done;
@property (nonatomic, copy) BAPromiseOnFulfilledBlock observed;
@property (nonatomic, copy) BAPromiseOnRejectedBlock rejected;
@property (nonatomic, copy) BAPromiseFinallyBlock finally;
@end

@implementation BAPromiseBlocks
- (BOOL)shouldKeepPromise
{
    return self.done != nil || self.finally != nil || self.rejected != nil;
}

- (void)callBlocksWithObject:(id)object
{
    if ([object isKindOfClass:NSError.class]) {
        if (self.rejected) {
            self.rejected(object);
        }
    } else {
        if (self.done) {
            self.done(object);
        }
        if (self.observed) {
            self.observed(object);
        }
    }
    if (self.finally) {
        self.finally();
    }
}
@end


@interface BAPromise ()
@property (nonatomic, strong) NSMutableArray<BAPromiseBlocks *> *blocks;
@property (nonatomic, strong) id fulfilledObject;
@end

@implementation BAPromise

-(BACancelToken *)done:(BAPromiseOnFulfilledBlock)onFulfilled
              observed:(BAPromiseOnFulfilledBlock)onObserved
              rejected:(BAPromiseOnRejectedBlock)onRejected
               finally:(BAPromiseFinallyBlock)onFinally
                 queue:(dispatch_queue_t)queue
{
    return [self done:onFulfilled
             observed:onObserved
             rejected:onRejected
              finally:onFinally
                queue:queue
               thread:nil];
}

-(void)ba_runBlock:(dispatch_block_t)block
{
    block();
}

-(BACancelToken *)done:(BAPromiseOnFulfilledBlock)onFulfilled
              observed:(BAPromiseOnFulfilledBlock)onObserved
              rejected:(BAPromiseOnRejectedBlock)onRejected
               finally:(BAPromiseFinallyBlock)onFinally
                 queue:(dispatch_queue_t)queue
                thread:(NSThread *)thread
{
    BAPromiseOnFulfilledBlock wrappedDoneBlock, wrappedObservedBlock;
    BAPromiseOnRejectedBlock wrappedRejectedBlock;
    BAPromiseFinallyBlock wrappedFinallyBlock;
    
    BACancelToken *cancellationToken = [BACancelToken new];
    
    __weak typeof(self) weakSelf = self;
    // wrap the passed in blocks to dispatch to the appropriate queue and check for cancellaltion
    if (onFulfilled) {
        wrappedDoneBlock = ^(id obj) {
            if (thread) {
                [weakSelf performSelector:@selector(ba_runBlock:) onThread:thread withObject:^{
                    if (!cancellationToken.cancelled) {
                        onFulfilled(obj);
                    }
                } waitUntilDone:NO];
            } else {
                dispatch_async(queue, ^{
                    if (!cancellationToken.cancelled) {
                        onFulfilled(obj);
                    }
                });
            }
        };
    }
    
    if (onObserved) {
        wrappedObservedBlock = ^(id obj) {
            if (thread) {
                [weakSelf performSelector:@selector(ba_runBlock:) onThread:thread withObject:^{
                    if (!cancellationToken.cancelled) {
                        onObserved(obj);
                    }
                } waitUntilDone:NO];
            } else {
                dispatch_async(queue, ^{
                    if (!cancellationToken.cancelled) {
                        onObserved(obj);
                    }
                });
            }
        };
    }
    
    if (onRejected) {
        wrappedRejectedBlock = ^(id obj) {
            if (thread) {
                [weakSelf performSelector:@selector(ba_runBlock:) onThread:thread withObject:^{
                    if (!cancellationToken.cancelled) {
                        onRejected(obj);
                    }
                } waitUntilDone:NO];
            } else {
                dispatch_async(queue, ^{
                    if (!cancellationToken.cancelled) {
                        onRejected(obj);
                    }
                });
            }
        };
    }
    
    if (onFinally) {
        wrappedFinallyBlock = ^{
            if (thread) {
                [weakSelf performSelector:@selector(ba_runBlock:) onThread:thread withObject:^{
                    if (!cancellationToken.cancelled) {
                        onFinally();
                    }
                } waitUntilDone:NO];
            } else {
                dispatch_async(queue, ^{
                    if (!cancellationToken.cancelled) {
                        onFinally();
                    }
                });
            }
        };
    }
    BAPromiseBlocks *blocks = BAPromiseBlocks.new;
    blocks.done = wrappedDoneBlock;
    blocks.observed = wrappedObservedBlock;
    blocks.rejected = wrappedRejectedBlock;
    blocks.finally = wrappedFinallyBlock;
    
    [cancellationToken cancelled:^{
        typeof(self) strongSelf = weakSelf;
        if (strongSelf) {
            dispatch_async(strongSelf.queue, ^{
                @autoreleasepool {
                    [strongSelf.blocks removeObjectIdenticalTo:blocks];
                    
                    BOOL strongCount = NO;
                    for (BAPromiseBlocks *block in strongSelf.blocks) {
                        if ([block shouldKeepPromise]) {
                            strongCount = YES;
                            break;
                        }
                    }
                    if (!strongCount) {
                        [strongSelf cancel];
                    }
                }
            });
        }
    }];
    
    
    dispatch_async(self.queue, ^{
        switch(self.promiseState) {
            case BAPromise_Unfulfilled:
                      // save the blocks for later
                if (!self.blocks) {
                    self.blocks = NSMutableArray.new;
                }
                [self.blocks addObject:blocks];
                break;
                
            case BAPromise_Fulfilled:
            case BAPromise_Rejected:
            case BAPromise_Canceled:
                [blocks callBlocksWithObject:self.fulfilledObject];
                break;
        }
    });
    return cancellationToken;
}

-(BACancelToken *)done:(BAPromiseOnFulfilledBlock)onFulfilled
{
    return [self done:onFulfilled
             observed:nil
             rejected:nil
              finally:nil
                queue:ba_dispatch_get_current_queue()];
}

-(BACancelToken *)done:(BAPromiseOnFulfilledBlock)onFulfilled
              rejected:(BAPromiseOnRejectedBlock)onRejected
{
    return [self done:onFulfilled
             observed:nil
             rejected:onRejected
              finally:nil
                queue:ba_dispatch_get_current_queue()];
}


-(BACancelToken *)done:(BAPromiseOnFulfilledBlock)onFulfilled
               finally:(BAPromiseFinallyBlock)onFinally
{
    return [self done:onFulfilled
             observed:nil
             rejected:nil
              finally:onFinally
                queue:ba_dispatch_get_current_queue()];
}

-(BACancelToken *)done:(BAPromiseOnFulfilledBlock)onFulfilled
              rejected:(BAPromiseOnRejectedBlock)onRejected
                 queue:(dispatch_queue_t)queue
{
    return [self done:onFulfilled
             observed:nil
             rejected:onRejected
              finally:nil
                queue:queue];
}

-(BACancelToken *)done:(BAPromiseOnFulfilledBlock)onFulfilled
              rejected:(BAPromiseOnRejectedBlock)onRejected
               finally:(BAPromiseFinallyBlock)onFinally
{
    return [self done:onFulfilled
             observed:nil
             rejected:onRejected
              finally:onFinally
                queue:ba_dispatch_get_current_queue()];
}

-(BACancelToken *)rejected:(BAPromiseOnRejectedBlock)onRejected
{
    return [self done:nil
             observed:nil
             rejected:onRejected
              finally:nil
                queue:ba_dispatch_get_current_queue()];
}

-(BACancelToken *)rejected:(BAPromiseOnRejectedBlock)onRejected
                   finally:(BAPromiseFinallyBlock)onFinally
{
    return [self done:nil
             observed:nil
             rejected:onRejected
              finally:onFinally
                queue:ba_dispatch_get_current_queue()];
}


-(BACancelToken *)finally:(BAPromiseFinallyBlock)onFinally
{
    return [self done:nil
             observed:nil
             rejected:nil
              finally:onFinally
                queue:ba_dispatch_get_current_queue()];
}

#pragma mark - Then

-(BAPromise *)then:(BAPromiseThenBlock)thenBlock
          rejected:(BAPromiseThenRejectedBlock)failureBlock
           finally:(BAPromiseFinallyBlock)finallyBlock
             queue:(dispatch_queue_t)myQueue
{
    return [self then:thenBlock
             rejected:failureBlock
              finally:finallyBlock
                queue:myQueue
               thread:nil];
}

-(BAPromise *)then:(BAPromiseThenBlock)thenBlock
           finally:(BAPromiseFinallyBlock)finallyBlock
{
    return [self then:thenBlock
             rejected:nil
              finally:finallyBlock
                queue:ba_dispatch_get_current_queue()
               thread:nil];
}

-(BAPromise *)thenRejected:(BAPromiseThenRejectedBlock)onRejected
{
    return [self then:nil
             rejected:onRejected
              finally:nil
                queue:ba_dispatch_get_current_queue()
               thread:nil];
}

-(BAPromise *)then:(BAPromiseThenBlock)thenBlock
          rejected:(BAPromiseThenRejectedBlock)failureBlock
           finally:(BAPromiseFinallyBlock)finallyBlock
             queue:(dispatch_queue_t)myQueue
            thread:(NSThread *)thread
{
    __block BACancelToken *cancellationToken=nil;
    BAPromiseClient *returnedPromise = [[BAPromiseClient alloc] init];
    [returnedPromise cancelled:^{
        if (thread) {
            [thread performSelector:@selector(ba_runBlock:) onThread:thread withObject:^{
                [cancellationToken cancel];
            } waitUntilDone:NO];
        } else {
            dispatch_async(myQueue, ^{
                [cancellationToken cancel];
            });
        }
    }];
    
    cancellationToken = [self done:^(id obj) {
        id chainedValue = thenBlock(obj);
        if ([chainedValue isKindOfClass:[NSError class]]) {
            // returning an NSError from the 'then' block
            // turns the fulfillment into a rejection
            [returnedPromise rejectWithError:(NSError *)chainedValue];
        } else {
            [returnedPromise fulfillWithObject:chainedValue];
        }
    }  observed:nil
                          rejected:^(NSError *error) {
                              if (failureBlock != nil) {
                                  error = failureBlock(error);
                                  if ([error isKindOfClass:[NSError class]]) {
                                      // returning anything other than an NSError from the 'rejected' block
                                      // turns the rejection back into a fulfillment
                                      [returnedPromise rejectWithError:error];
                                  } else {
                                      [returnedPromise fulfillWithObject:error];
                                  }
                              } else {
                                  [returnedPromise rejectWithError:error];
                              }
                          } finally:^{
                              if (finallyBlock) {
                                  finallyBlock();
                              }
                          } queue:myQueue];
    
    return returnedPromise;
}

-(BAPromise *)then:(BAPromiseThenBlock)onFulfilled
{
    return [self then:onFulfilled
             rejected:nil
              finally:nil
                queue:ba_dispatch_get_current_queue()];
}

-(BAPromise *)then:(BAPromiseThenBlock)onFulfilled
             queue:(dispatch_queue_t)queue
{
    return [self then:onFulfilled
             rejected:nil
              finally:nil
                queue:queue];
}

-(BAPromise *)then:(BAPromiseThenBlock)onFulfilled
          rejected:(BAPromiseThenRejectedBlock)onRejected
{
    return [self then:onFulfilled
             rejected:onRejected
              finally:nil
                queue:ba_dispatch_get_current_queue()];
}

@end

@implementation BAPromiseClient
+(BAPromiseClient *)fulfilledPromise:(id)obj
{
    BAPromiseClient *promise = [[BAPromiseClient alloc] init];
    [promise fulfillWithObject:obj];
    return promise;
}

+(BAPromiseClient *)rejectedPromise:(NSError *)error
{
    BAPromiseClient *promise = [[BAPromiseClient alloc] init];
    [promise rejectWithError:error];
    return promise;
}

-(void)fulfillWithObject:(id)obj
{
    if ([obj isKindOfClass:[BAPromise class]]) {
        BAPromise *promise = (BAPromise *)obj;
        if (self.cancelled) {
            [promise cancel];
        } else {
            BACancelToken *cancellationToken;
            
            dispatch_queue_t myQueue = promise.queue;
            
            cancellationToken = [promise done:^(id obj) {
                [self fulfillWithObject:obj];
            } rejected:^(NSError *error) {
                [self rejectWithError:error];
            } queue:myQueue];
            
            [self cancelled:^{
                dispatch_async(myQueue, ^{
                    [cancellationToken cancel];
                });
            }];
        }
    } else {
        dispatch_async(self.queue, ^{
            if (self.promiseState == BAPromise_Unfulfilled) {
                self.promiseState = BAPromise_Fulfilled;
                self.fulfilledObject = obj;
                
                for (BAPromiseBlocks *blocks in self.blocks) {
                    [blocks callBlocksWithObject:obj];
                }
                // remove references we'll never call now
                self.blocks = nil;
                self.onCancel = nil;
            }
        });
    }
}

-(void)fulfill
{
    [self fulfillWithObject:nil];
}

-(void)rejectWithError:(NSError *)error
{
    dispatch_async(self.queue, ^{
        if (self.promiseState == BAPromise_Unfulfilled) {
            self.promiseState = BAPromise_Rejected;
            self.fulfilledObject = error;
            for (BAPromiseBlocks *blocks in self.blocks) {
                [blocks callBlocksWithObject:error];
            }
            // remove references we'll never call now
            self.blocks = nil;
            self.onCancel = nil;
        }
    });
}

-(void)reject
{
    [self rejectWithError:[[NSError alloc] init]];
}

@end

@implementation NSArray (BAPromiseJoin)

-(BAPromise *)whenPromises
{
    // an empty array should return a promise that fulfills with 'nil'.
    // We shortcut the rest of the method here because there are no other promises to trigger our returned promise
    if (self.count == 0) {
        return [BAPromiseClient fulfilledPromise:nil];
    }
    
    BAPromiseClient *returnedPromise = [[BAPromiseClient alloc] init];
    dispatch_queue_t myQueue = returnedPromise.queue;
    NSMutableArray *cancellationTokens = [[NSMutableArray alloc] initWithCapacity:self.count];
    
    // propagate cancellation
    [returnedPromise cancelled:^{
        for (BACancelToken *token in cancellationTokens) {
            [token cancel];
        }
    }];
    
    NSUInteger totalCount=self.count;
    NSMutableArray *results = [[NSMutableArray alloc] initWithCapacity:totalCount];
    for (NSUInteger i=0;i<self.count;i++) {
        [results addObject:[NSNull null]];
    }
    
    // manually looping so we have an index
    __block NSUInteger fulfilledCount=0;
    [self enumerateObjectsUsingBlock:^(BAPromiseClient *promise, NSUInteger idx, BOOL *stop) {
        // these are guaranteed to occur on a serial queue, so there is no need to synchronize
        BACancelToken *token = [promise done:^(id obj) {
            if (obj) {
                results[idx] = obj;
            }
            
            if (++fulfilledCount == totalCount) { // this is safe because these callbacks all happen on the same serial dispatch queuue
                [returnedPromise fulfillWithObject:results];
            }
        } rejected:^(NSError *error) {
            [returnedPromise rejectWithError:error];
            // cancel all the other promises (cancelling the rejected promise at this point is safe, see testCancelPromiseAfterRejection)
            [cancellationTokens enumerateObjectsUsingBlock:^(BACancelToken *token, NSUInteger idx, BOOL *stop) {
                [token cancel];
            }];
        } queue:myQueue];
        [cancellationTokens addObject:token];
    }];
    
    return returnedPromise;
}

-(BAPromise *)joinPromises
{
    // an empty array should return a promise that fulfills with 'nil'.
    // We shortcut the rest of the method here because there are no other promises to trigger our returned promise
    if (self.count == 0) {
        return [BAPromiseClient fulfilledPromise:nil];
    }
    
    BAPromiseClient *returnedPromise = [[BAPromiseClient alloc] init];
    dispatch_queue_t myQueue = returnedPromise.queue;
    NSMutableArray *cancellationTokens = [[NSMutableArray alloc] initWithCapacity:self.count];
    
    // propagate cancellation
    [returnedPromise cancelled:^{
        for (BACancelToken *token in cancellationTokens) {
            [token cancel];
        }
    }];
    
    NSUInteger totalCount=self.count;
    NSMutableArray *results = [[NSMutableArray alloc] initWithCapacity:totalCount];
    for (NSUInteger i=0;i<self.count;i++) {
        [results addObject:[NSNull null]];
    }
    
    // manually looping so we have an index
    __block NSUInteger fulfilledCount=0;
    __block BOOL success = NO;
    [self enumerateObjectsUsingBlock:^(BAPromiseClient *promise, NSUInteger idx, BOOL *stop) {
        // these are guaranteed to occur on a serial queue, so there is no need to synchronize
        BACancelToken *token = [promise done:^(id obj) {
            success = YES;
            if (obj) {
                results[idx] = obj;
            }
            
            if (++fulfilledCount == totalCount) { // this is safe because these callbacks all happen on the same serial dispatch queuue
                [returnedPromise fulfillWithObject:results];
            }
        } rejected:^(NSError *error) {
            if (error) {
                results[idx] = error;
            }
            
            if (++fulfilledCount == totalCount) { // this is safe because these callbacks all happen on the same serial dispatch queuue
                if (success) { // if we had any successful promises, we'll return the array
                    [returnedPromise fulfillWithObject:results];
                } else { // otherwise we return an error
                    [returnedPromise rejectWithError:error]; // TODO(benski) combine all errors in some way
                }
            }
        } queue:myQueue];
        [cancellationTokens addObject:token];
    }];
    
    return returnedPromise;
}

@end
