//
//  BAPromise.m
//  BAPromise
//
//  Created by Ben Allison on 6/22/15.
//  Copyright (c) 2015 Ben Allison. All rights reserved.
//

#import "BAPromise.h"

@interface BACancelToken ()
@property (nonatomic, strong) dispatch_queue_t queue;
@property (nonatomic) BAPromiseState promiseState;
@property (nonatomic) BOOL cancelled;
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
@end

@interface BAPromise ()
@property (nonatomic, strong) NSMutableArray *doneBlocks;
@property (nonatomic, strong) NSMutableArray *observerBlocks;
@property (nonatomic, strong) NSMutableArray *rejectedBlocks;
@property (nonatomic, strong) NSMutableArray *finallyBlocks;
@property (nonatomic, strong) id fulfilledObject;
@end

@implementation BAPromise
-(instancetype)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

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

@end

@implementation BAPromiseClient
-(void)fulfillWithObject:(id)obj
{
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
@end
