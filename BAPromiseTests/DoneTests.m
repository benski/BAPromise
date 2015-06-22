//
//  DoneTests.m
//  BAPromise
//
//  Created by Ben Allison on 6/22/15.
//  Copyright (c) 2015 Ben Allison. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "TestWaiter.h"
#import "BAPromise.h"

@interface DoneTests : XCTestCase
@property (nonatomic, strong) TestWaiter *waiter;
@end

@implementation DoneTests

-(void)setUp
{
    [super setUp];
    _waiter = [TestWaiter new];
}

-(void)tearDown
{
    [super tearDown];
    _waiter = nil;
}

-(void)testDone
{
    XCTAssert(YES, @"Pass");
    BAPromiseClient *promise = [[BAPromiseClient alloc] init];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [promise fulfillWithObject:nil];
    });
    
    [self.waiter enter];
    [promise done:^(id obj) {
        [self.waiter leave];
    }
         rejected:nil
          finally:nil
            queue:nil];
    
    XCTAssertFalse([self.waiter waitForSeconds:0.5]);
}

@end
