//
//  DoneTests.m
//  BAPromise
//
//  Created by Ben Allison on 6/22/15.
//  Copyright (c) 2015 Ben Allison. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TestWaiter.h"
#import "BAPromise.h"
#import <OCMock/OCMock.h>

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
    BAPromiseClient *promise = [[BAPromiseClient alloc] init];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [promise fulfillWithObject:nil];
    });
    
    [self.waiter enter];
    [promise done:^(id obj) {
        [self.waiter leave];
    }
         observed:nil
         rejected:nil
          finally:nil
            queue:dispatch_get_current_queue()];
    
    XCTAssertFalse([self.waiter waitForSeconds:0.5]);
}

-(void)testDoneHelper
{
    // calling 'done' should turn around and call done:observed:rejected:finally:queue
    void (^block)(id) = ^(id obj) {};
    BAPromise *promise = [BAPromise new];
    id promiseMock = OCMPartialMock(promise);
    [[[promiseMock expect] andReturn:nil] done:block observed:nil rejected:nil finally:nil queue:dispatch_get_current_queue()];
    [promiseMock done:block];
    [promiseMock verify];
}

-(void)testFulfillmentFirst
{
    [self.waiter enter];
    BAPromiseClient *promise = [[BAPromiseClient alloc] init];
    [promise fulfillWithObject:nil];
    
    [promise done:^(id obj) {
        [self.waiter leave];
    }];
    
    XCTAssertFalse([self.waiter waitForSeconds:0.5]);
}

-(void)testFulfillmentSecond
{
    [self.waiter enter];
    BAPromiseClient *promise = [[BAPromiseClient alloc] init];
    
    [promise done:^(id obj) {
        [self.waiter leave];
    }];
    
    [promise fulfillWithObject:nil];
    
    XCTAssertFalse([self.waiter waitForSeconds:0.5]);
}

-(void)testFulfill
{
    // calling 'fulfill' should call fulfillWithObject:nil
    BAPromiseClient *promise = [BAPromiseClient new];
    id promiseMock = OCMPartialMock(promise);
    [[promiseMock expect] fulfillWithObject:nil];
    [promiseMock fulfill];
    [promiseMock verify];
}

-(void)testFulfillWithObjectFirst
{
    [self.waiter enter];
    BAPromiseClient *promise = [[BAPromiseClient alloc] init];
    [promise fulfillWithObject:@7];
    
    [promise done:^(id obj) {
        XCTAssertEqualObjects(obj, @7);
        [self.waiter leave];
    }];
    
    XCTAssertFalse([self.waiter waitForSeconds:0.5]);
}

-(void)testFulfillWithObjectSecond
{
    [self.waiter enter];
    BAPromiseClient *promise = [[BAPromiseClient alloc] init];
    
    [promise done:^(id obj) {
        XCTAssertEqualObjects(obj, @42);
        [self.waiter leave];
    }];
    
    [promise fulfillWithObject:@42];
    
    XCTAssertFalse([self.waiter waitForSeconds:0.5]);
}
@end
