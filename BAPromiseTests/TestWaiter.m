//
//  TestWaiter.m
//  BAPromise
//
//  Created by Ben Allison on 6/22/15.
//  Copyright (c) 2015 Ben Allison. All rights reserved.
//

#import "TestWaiter.h"

@interface TestWaiter ()
@property (nonatomic, strong) dispatch_group_t group;
@end

@implementation TestWaiter
-(instancetype)init
{
    self = [super init];
    _group = dispatch_group_create();
    return self;
}

-(void)enter
{
    dispatch_group_enter(_group);
}

-(void)leave
{
    dispatch_group_leave(_group);
}

-(BOOL)waitForSeconds:(double)seconds
{
    __block BOOL done = NO;
    __block BOOL didTimeOut = NO;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        didTimeOut = dispatch_group_wait(_group, dispatch_time(DISPATCH_TIME_NOW, seconds*NSEC_PER_SEC));
        done = YES;
    });
    
    while (!done) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate distantPast]];
    }
    return didTimeOut;
}

@end
