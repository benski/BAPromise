//
//  DoneTests.m
//  BAPromise
//
//  Created by Ben Allison on 6/22/15.
//  Copyright (c) 2015 Ben Allison. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TestWaiter.h"
@import BAPromise;
#import <OCMock/OCMock.h>

@interface DoneTests : XCTestCase
@end

@implementation DoneTests

-(void)setUp
{
    [super setUp];
}

-(void)tearDown
{
    [super tearDown];
}

-(void)testDone
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Promise Resolution"];
    BAPromise *promise = [[BAPromise alloc] init];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [promise fulfillWithObject:nil];
    });
    
    [promise done:^(id obj) {
        [expectation fulfill];
    }
         observed:nil
         rejected:nil
          finally:nil
            queue:dispatch_get_current_queue()];
    
    [self waitForExpectationsWithTimeout:0.5 handler:nil];
}

-(void)testDoneVerifyQueue
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Promise Resolution"];
    BAPromise *promise = [[BAPromise alloc] init];
    dispatch_queue_t myQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [promise fulfillWithObject:nil];
    });
    
    [promise done:^(id obj) {
        XCTAssertEqual(myQueue, dispatch_get_current_queue(), @"Unexpected queue for fulfillment");
        [expectation fulfill];
    }
         observed:nil
         rejected:nil
          finally:nil
            queue:myQueue];
    
    [self waitForExpectationsWithTimeout:0.5 handler:nil];
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
    XCTestExpectation *expectation = [self expectationWithDescription:@"Promise Resolution"];
    BAPromise *promise = [[BAPromise alloc] init];
    [promise fulfillWithObject:nil];
    
    [promise done:^(id obj) {
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:0.5 handler:nil];
}

-(void)testFulfillmentSecond
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Promise Resolution"];
    BAPromise *promise = [[BAPromise alloc] init];
    
    [promise done:^(id obj) {
        [expectation fulfill];
    }];
    
    [promise fulfillWithObject:nil];
    
    [self waitForExpectationsWithTimeout:0.5 handler:nil];
}

-(void)testFulfill
{
    // calling 'fulfill' should call fulfillWithObject:nil
    BAPromise *promise = [BAPromise new];
    id promiseMock = OCMPartialMock(promise);
    [[promiseMock expect] fulfillWithObject:nil];
    [promiseMock fulfill];
    [promiseMock verify];
}

-(void)testFulfillWithObjectFirst
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Promise Resolution"];
    BAPromise *promise = [[BAPromise alloc] init];
    [promise fulfillWithObject:@7];
    
    [promise done:^(id obj) {
        XCTAssertEqualObjects(obj, @7);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:0.5 handler:nil];
}

-(void)testFulfillWithObjectSecond
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Promise Resolution"];
    BAPromise *promise = [[BAPromise alloc] init];
    
    [promise done:^(id obj) {
        XCTAssertEqualObjects(obj, @42);
        [expectation fulfill];
    }];
    
    [promise fulfillWithObject:@42];
    
    [self waitForExpectationsWithTimeout:0.5 handler:nil];
}

-(void)testSyntaxSugar
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Promise Resolution"];

    [[BAPromise promiseWithResolver:^(BAPromiseOnFulfillBlock fulfill, BAPromiseOnRejectedBlock reject) {
        fulfill(@"Success");
    }] done:^(id obj) {
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:0.5 handler:nil];
}

@end
