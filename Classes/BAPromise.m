//
//  BAPromise.m
//  BAPromise
//
//  Created by Ben Allison
//  Copyright (c) 2013 Ben Allison. MIT License. See LICENSE
//

#import "BAPromise.h"

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
@property (nonatomic, strong) dispatch_block_t onCancel;
@end

@implementation BACancelToken
-(instancetype)init
{
    self = [super init];
    if (self) {
        _queue = dispatch_queue_create(nil, DISPATCH_QUEUE_SERIAL);
        _promiseState = BAPromise_Unfulfilled;
        _cancelled = NO;
    }
    return self;
}

-(void)cancelled:(dispatch_block_t)onCancel
{
    dispatch_queue_t currentQueue = dispatch_get_current_queue();
    dispatch_block_t wrappedCancelBlock = ^ {
        dispatch_async(currentQueue, ^{
            onCancel();
        });
    };
    
    dispatch_async(_queue, ^{
        if (_promiseState != BAPromise_Rejected && _promiseState != BAPromise_Fulfilled) {
            if (_cancelled) {
                wrappedCancelBlock();
            } else {
                _onCancel = wrappedCancelBlock;
            }
        }
    });
}

-(void)cancel
{
    _cancelled = YES;
    dispatch_async(self.queue, ^{
        
        if (self.onCancel) {
            self.onCancel();
            self.onCancel=nil;
        }
    });
}
@end

@interface BAPromise ()
@property (nonatomic, strong) NSMutableArray *doneBlocks;
@property (nonatomic, strong) NSMutableArray *observerBlocks;
@property (nonatomic, strong) NSMutableArray *rejectedBlocks;
@property (nonatomic, strong) NSMutableArray *finallyBlocks;
@property (nonatomic, strong) id fulfilledObject;
@end

@implementation BAPromise

-(BACancelToken *)done:(BAPromiseOnFulfilledBlock)onFulfilled
              observed:(BAPromiseOnFulfilledBlock)onObserved
              rejected:(BAPromiseOnRejectedBlock)onRejected
               finally:(BAPromiseFinallyBlock)onFinally
                 queue:(dispatch_queue_t)queue
{
    BAPromiseOnFulfilledBlock wrappedDoneBlock, wrappedObservedBlock;
    BAPromiseOnRejectedBlock wrappedRejectedBlock;
    BAPromiseFinallyBlock wrappedFinallyBlock;
    
    BACancelToken *cancellationToken;
    
    cancellationToken = [BACancelToken new];
    __weak BACancelToken *weakCancellationToken = cancellationToken;
    
    // wrap the passed in blocks to dispatch to the appropriate queue and check for cancellaltion
    if (onFulfilled) {
        wrappedDoneBlock = ^(id obj) {
            dispatch_async(queue, ^{
                if (!weakCancellationToken.cancelled) {
                    onFulfilled(obj);
                }
            });
        };
    }
    
    if (onObserved) {
        wrappedObservedBlock = ^(id obj) {
            dispatch_async(queue, ^{
                if (!weakCancellationToken.cancelled) {
                    onObserved(obj);
                }
            });
        };
    }
    
    if (onRejected) {
        wrappedRejectedBlock = ^(id obj) {
            dispatch_async(queue, ^{
                if (!weakCancellationToken.cancelled) {
                    onRejected(obj);
                }
            });
        };
    }
    
    if (onFinally) {
        wrappedFinallyBlock = ^{
            dispatch_async(queue, ^{
                if (!weakCancellationToken.cancelled) {
                    onFinally();
                }
            });
        };
    }
    
    [cancellationToken cancelled:^{
        dispatch_async(self.queue, ^{
            if (onFulfilled) {
                [self.doneBlocks removeObjectIdenticalTo:wrappedDoneBlock];
            }
            
            if (onObserved) {
                [self.observerBlocks removeObjectIdenticalTo:wrappedObservedBlock];
            }
            
            if (onRejected) {
                [self.rejectedBlocks removeObjectIdenticalTo:wrappedRejectedBlock];
            }
            
            if (onFinally) {
                [self.finallyBlocks removeObjectIdenticalTo:wrappedFinallyBlock];
            }
            
            if (self.doneBlocks.count == 0
                && self.finallyBlocks.count == 0) {
                [self cancel];
            }
        });
    }];
    
    
    dispatch_async(self.queue, ^{
        switch(self.promiseState) {
            case BAPromise_Unfulfilled:
                // save the blocks for later
                if (wrappedDoneBlock) {
                    if (!_doneBlocks) {
                        _doneBlocks = [[NSMutableArray alloc] init];
                    }
                    [_doneBlocks addObject:wrappedDoneBlock];
                }
                
                if (wrappedObservedBlock) {
                    if (!_observerBlocks) {
                        _observerBlocks = [[NSMutableArray alloc] init];
                    }
                    [_observerBlocks addObject:wrappedObservedBlock];
                }
                
                if (wrappedRejectedBlock) {
                    if (!_rejectedBlocks) {
                        _rejectedBlocks = [[NSMutableArray alloc] init];
                    }
                    [_rejectedBlocks addObject:wrappedRejectedBlock];
                }
                
                if (wrappedFinallyBlock) {
                    if (!_finallyBlocks) {
                        _finallyBlocks = [[NSMutableArray alloc] init];
                    }
                    [_finallyBlocks addObject:wrappedFinallyBlock];
                }
                break;
                
            case BAPromise_Fulfilled:
                if (wrappedDoneBlock) {
                    // it was already fulfilled then call it now
                    wrappedDoneBlock(_fulfilledObject);
                }
                
                if (wrappedObservedBlock) {
                    wrappedObservedBlock(_fulfilledObject);
                }
                
                if (wrappedFinallyBlock) {
                    wrappedFinallyBlock();
                }
                break;
                
            case BAPromise_Rejected:
            case BAPromise_Canceled:
                // if it was already rejected, but no failureBlock was set, then call it now
                if (wrappedRejectedBlock) {
                    wrappedRejectedBlock(_fulfilledObject);
                }
                
                if (wrappedFinallyBlock) {
                    wrappedFinallyBlock();
                }
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
                queue:dispatch_get_current_queue()];
}

-(BACancelToken *)done:(BAPromiseOnFulfilledBlock)onFulfilled
              rejected:(BAPromiseOnRejectedBlock)onRejected
{
    return [self done:onFulfilled
             observed:nil
             rejected:onRejected
              finally:nil
                queue:dispatch_get_current_queue()];
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
                queue:dispatch_get_current_queue()];
}

-(BACancelToken *)rejected:(BAPromiseOnRejectedBlock)onRejected
{
    return [self done:nil
             observed:nil
             rejected:onRejected
              finally:nil
                queue:dispatch_get_current_queue()];
}

-(BACancelToken *)finally:(BAPromiseFinallyBlock)onFinally
{
    return [self done:nil
             observed:nil
             rejected:nil
              finally:onFinally
                queue:dispatch_get_current_queue()];
}

#pragma mark - Then

-(BAPromise *)then:(BAPromiseThenBlock)thenBlock
          rejected:(BAPromiseThenRejectedBlock)failureBlock
           finally:(BAPromiseFinallyBlock)finallyBlock
             queue:(dispatch_queue_t)myQueue
{
    __block BACancelToken *cancellationToken=nil;
    BAPromiseClient *returnedPromise = [[BAPromiseClient alloc] init];
    [returnedPromise cancelled:^{
        dispatch_async(myQueue, ^{
            if (cancellationToken)
                [cancellationToken cancel];
        });
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
    } observed:nil
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
                queue:dispatch_get_current_queue()];
}

-(BAPromise *)then:(BAPromiseThenBlock)onFulfilled
          rejected:(BAPromiseThenRejectedBlock)onRejected
{
    return [self then:onFulfilled
             rejected:onRejected
              finally:nil
                queue:dispatch_get_current_queue()];
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
    } else {
        dispatch_async(self.queue, ^{
            if (self.promiseState == BAPromise_Unfulfilled) {
                self.promiseState = BAPromise_Fulfilled;
                self.fulfilledObject = obj;
                
                // remove references we'll never call now
                self.rejectedBlocks = nil;
                
                for (BAPromiseOnFulfilledBlock done in self.doneBlocks) {
                    done(obj);
                }
                self.doneBlocks = nil;
                
                for (BAPromiseOnFulfilledBlock done in self.observerBlocks) {
                    done(obj);
                }
                self.observerBlocks = nil;
                
                for (BAPromiseFinallyBlock finally in self.finallyBlocks) {
                    finally();
                }
                self.finallyBlocks = nil;
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
            // remove references we'll never call now
            self.doneBlocks = nil;
            self.onCancel = nil;
            for (BAPromiseOnRejectedBlock rejected in self.rejectedBlocks) {
                rejected(error);
            }
            self.rejectedBlocks = nil;
            
            for (BAPromiseFinallyBlock finally in self.finallyBlocks) {
                finally();
            }
            self.finallyBlocks = nil;
        }
    });
}

-(void)reject
{
    [self rejectWithError:[[NSError alloc] init]];
}
@end

@implementation NSArray (BAPromiseJoin)

-(BAPromise *)joinPromises
{
    BAPromiseClient *returnedPromise = [[BAPromiseClient alloc] init];
    dispatch_queue_t myQueue = returnedPromise.queue;
    NSMutableArray *cancellationTokens = [[NSMutableArray alloc] initWithCapacity:self.count];
    
    // propagate cancellation
    [returnedPromise cancelled:^{
        for (BACancelToken *token in cancellationTokens) {
            dispatch_async(myQueue, ^{
                [token cancel];
            });
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

@end
