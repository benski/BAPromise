//
//  ChainTests.m
//  BAPromise
//
//  Created by Ben Allison on 6/23/15.
//  Copyright (c) 2015 Ben Allison. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TestWaiter.h"
#import "BAPromise.h"
#import <OCMock/OCMock.h>

@interface ChainTests : XCTestCase

@end

@implementation ChainTests

-(void)setUp
{
    [super setUp];
}

-(void)tearDown
{
    [super tearDown];
}

// calling fulfillWithObject:somePromise calls when, so we'll test that (the rest of the tests just test 'when'
-(void)testSimpleFulfill
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Promise Resolution"];
    BAPromise *promise = [[BAPromise alloc] init];
    BAPromise *anotherPromise = [BAPromise fulfilledPromise:@7];
    
    [promise fulfillWithObject:anotherPromise];
    [promise done:^(id obj) {
        XCTAssert([obj isKindOfClass:[NSNumber class]], @"Expected NSNumber");
        XCTAssertEqualObjects(obj, @7, @"Expected 7");
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:0.5 handler:nil];
}

-(void)testSimpleWhen
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Promise Resolution"];
    BAPromise *promise = [[BAPromise alloc] init];
    BAPromise *anotherPromise = [BAPromise fulfilledPromise:@7];
    
    [promise fulfillWithObject:anotherPromise];
    [promise done:^(id obj) {
        XCTAssert([obj isKindOfClass:[NSNumber class]], @"Expected NSNumber");
        XCTAssertEqualObjects(obj, @7, @"Expected 7");
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:0.5 handler:nil];
}

-(void)testAsyncWhen
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Promise Resolution"];
    BAPromise *promise = [[BAPromise alloc] init];
    BAPromise *anotherPromise = [BAPromise new];
    
    [promise fulfillWithObject:anotherPromise];
    [promise done:^(id obj) {
        XCTAssert([obj isKindOfClass:[NSNumber class]], @"Expected NSNumber");
        XCTAssertEqualObjects(obj, @7, @"Expected 7");
        [expectation fulfill];
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [anotherPromise fulfillWithObject:@7];
    });
    
    [self waitForExpectationsWithTimeout:0.5 handler:nil];
}

-(void)testSimpleWhenFail
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Promise Resolution"];
    BAPromise *promise = [[BAPromise alloc] init];
    BAPromise *anotherPromise = [BAPromise rejectedPromise:[NSError errorWithDomain:@"org.benski" code:0 userInfo:nil]];
    
    [promise fulfillWithObject:anotherPromise];
    [promise rejected:^(id obj) {
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:0.5 handler:nil];
}

-(void)testAsyncWhenFail
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Promise Resolution"];
    BAPromise *promise = [[BAPromise alloc] init];
    BAPromise *anotherPromise = [BAPromise new];
    
    [promise fulfillWithObject:anotherPromise];
    [promise rejected:^(id obj) {
        [expectation fulfill];
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [anotherPromise reject];
    });
    
    [self waitForExpectationsWithTimeout:0.5 handler:nil];
}

-(void)testSimpleWhenFinallyDone
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Promise Resolution"];
    BAPromise *promise = [[BAPromise alloc] init];
    BAPromise *anotherPromise = [BAPromise fulfilledPromise:nil];
    
    [promise fulfillWithObject:anotherPromise];
    [promise finally:^() {
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:0.5 handler:nil];
}

-(void)testSimpleWhenFinallyFail
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Promise Resolution"];
    BAPromise *promise = [[BAPromise alloc] init];
    BAPromise *anotherPromise = [BAPromise rejectedPromise:[NSError errorWithDomain:@"com.github.benski.promise" code:0 userInfo:nil]];
    
    [promise fulfillWithObject:anotherPromise];
    [promise finally:^() {
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:0.5 handler:nil];
}

-(void)testAsyncWhenFinallyDone
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Promise Resolution"];
    BAPromise *promise = [[BAPromise alloc] init];
    BAPromise *anotherPromise = [BAPromise new];
    
    [promise fulfillWithObject:anotherPromise];
    [promise finally:^() {
        [expectation fulfill];
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [anotherPromise fulfillWithObject:nil];
    });
    
    [self waitForExpectationsWithTimeout:0.5 handler:nil];
}

-(void)testAsyncWhenFinallyFail
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Promise Resolution"];
    BAPromise *promise = [BAPromise new];
    BAPromise *anotherPromise = [BAPromise new];
    
    [promise fulfillWithObject:anotherPromise];
    [promise finally:^() {
        [expectation fulfill];
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [anotherPromise reject];
    });
    
    [self waitForExpectationsWithTimeout:0.5 handler:nil];
}

-(void)testFulfillSeveralTimes
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"testFullfillSeveralTimes"];
    expectation.expectedFulfillmentCount = 1;

    BAPromise *promise = [[BAPromise alloc] init];
    BAPromise *promise1 = [[BAPromise alloc] init];
    BAPromise *promise2 = [[BAPromise alloc] init];

    [promise fulfillWithObject:promise1];
    [promise fulfillWithObject:promise2];

    [promise1 fulfillWithObject:@1];
    [promise2 fulfillWithObject:@2];

    [promise done:^(id  _Nullable obj) {
        XCTAssert(((NSNumber *)obj).intValue == 1);
        [expectation fulfill];
    }];


    [self waitForExpectationsWithTimeout:0.5 handler:nil];

}

@end
