//
//  RejectTests.m
//  BAPromise
//
//  Created by Ben Allison on 6/23/15.
//  Copyright (c) 2015 Ben Allison. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TestWaiter.h"
#import "BAPromise.h"
#import <OCMock/OCMock.h>

@interface RejectTests : XCTestCase

@end

@implementation RejectTests

-(void)setUp
{
    [super setUp];
}

-(void)tearDown
{
    [super tearDown];
}

-(void)testRejectionAsynchronous
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Promise Resolution"];
    BAPromise *promise = [[BAPromise alloc] init];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [promise rejectWithError:[[NSError alloc] init]];
    });
    
    [promise done:^(id obj) {
        XCTFail(@"Unexpected fulfillment");
        [expectation fulfill];
    } rejected:^(NSError *error) {
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:0.5 handler:nil];
}

-(void)testRejectionFirst
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Promise Resolution"];
    BAPromise *promise = [[BAPromise alloc] init];
    [promise rejectWithError:[[NSError alloc] init]];
    
    [promise done:^(id obj) {
        XCTFail(@"Unexpected fulfillment");
        [expectation fulfill];
    } rejected:^(NSError *error) {
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:0.5 handler:nil];
}

-(void)testRejectionSecond
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Promise Resolution"];
    BAPromise *promise = [[BAPromise alloc] init];
    
    [promise done:^(id obj) {
        XCTFail(@"Unexpected fulfillment");
        [expectation fulfill];
    } rejected:^(NSError *error) {
        [expectation fulfill];
    }];
    
    [promise rejectWithError:[[NSError alloc] init]];
    [self waitForExpectationsWithTimeout:0.5 handler:nil];
}

-(void)testRejectedHelper
{
    // calling rejected: should turn around and call done:observed:rejected:finally:queue
    BAPromiseOnRejectedBlock block2 = ^(NSError *obj) {};
    BAPromise *promise = [BAPromise new];
    id promiseMock = OCMPartialMock(promise);
    [[[promiseMock expect] andReturn:nil] done:nil observed:nil rejected:block2 finally:nil queue:dispatch_get_current_queue()];
    [promiseMock rejected:block2];
    [promiseMock verify];
}

-(void)testDoneRejectedHelper
{
    // calling done:rejected: should turn around and call done:observed:rejected:finally:queue
    void (^block)(id) = ^(id obj) {};
    BAPromiseOnRejectedBlock block2 = ^(NSError *obj) {};
    BAPromise *promise = [BAPromise new];
    id promiseMock = OCMPartialMock(promise);
    [[[promiseMock expect] andReturn:nil] done:block observed:nil rejected:block2 finally:nil queue:dispatch_get_current_queue()];
    [promiseMock done:block rejected:block2];
    [promiseMock verify];
}

-(void)testRejectHelper
{
    // calling done:rejected: should turn around and call done:observed:rejected:finally:queue
    BAPromise *promise = [BAPromise new];
    id promiseMock = OCMPartialMock(promise);
    [[promiseMock expect] rejectWithError:OCMOCK_ANY];
    [promise reject];
    [promiseMock verify];
}
@end
