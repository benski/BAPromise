//
//  CancelTests.m
//  BAPromise
//
//  Created by Ben Allison on 6/22/15.
//  Copyright (c) 2015 Ben Allison. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "TestWaiter.h"
#import "BAPromise.h"

@interface CancelTests : XCTestCase
@property (nonatomic, strong) TestWaiter *waiter;
@end

@implementation CancelTests

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

-(void)testCancel
{
    BAPromiseClient *promise = [[BAPromiseClient alloc] init];
    [_waiter enter];
    [promise cancelled:^{
        [_waiter leave];
    }];
    [promise cancel];
    XCTAssertFalse([self.waiter waitForSeconds:0.5]);
}
@end
