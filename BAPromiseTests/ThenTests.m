//
//  ThenTests.m
//  BAPromise
//
//  Created by Ben Allison on 6/23/15.
//  Copyright (c) 2015 Ben Allison. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TestWaiter.h"
#import "BAPromise.h"
#import <OCMock/OCMock.h>

@interface ThenTests : XCTestCase

@end

@implementation ThenTests

-(void)setUp
{
    [super setUp];
}

-(void)tearDown
{
    [super tearDown];
}

-(void)testSimpleThen
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Promise Resolution"];
    BAPromise *promise = [[BAPromise alloc] init];
    
    [[promise then:^id(id obj) {
        XCTAssertNil(obj);
        return @7;
    }] done:^(id obj) {
        XCTAssert([obj isKindOfClass:[NSNumber class]], @"Expected NSNumber");
        XCTAssertEqualObjects(obj, @7, @"Expected 7");
        [expectation fulfill];
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [promise fulfill];
    });
    
    [self waitForExpectationsWithTimeout:0.5 handler:nil];
}

-(void)testPromiseThen
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Promise Resolution"];
    BAPromise *promise = [[BAPromise alloc] init];
    
    [[promise then:^id(id obj) {
        XCTAssertEqualObjects(obj, @6, @"Expected 6");
        BAPromise *promise2 = [[BAPromise alloc] init];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [promise2 fulfillWithObject:@8];
        });
        return promise2;
    }] done:^(id obj) {
        XCTAssertEqualObjects(obj, @8, @"Expected 8");
        [expectation fulfill];
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [promise fulfillWithObject:@6];
    });
    
    
    [self waitForExpectationsWithTimeout:0.5 handler:nil];
}

-(void)testPromiseThenTwice
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Promise Resolution"];
    BAPromise *promise = [[BAPromise alloc] init];
    
    [[[promise then:^id(id obj) {
        XCTAssertEqualObjects(obj, @6, @"Expected 6");
        BAPromise *promise2 = [[BAPromise alloc] init];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [promise2 fulfillWithObject:@8];
        });
        return promise2;
    }] then:^id(id obj) {
        XCTAssertEqualObjects(obj, @8, @"Expected 8");
        BAPromise *promise2 = [[BAPromise alloc] init];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [promise2 fulfillWithObject:@NO];
        });
        return promise2;
    }] done:^(id obj) {
        XCTAssertEqualObjects(obj, @NO, @"Expected NO");
        [expectation fulfill];
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [promise fulfillWithObject:@6];
    });
    
    [self waitForExpectationsWithTimeout:0.5 handler:nil];
}

-(void)testFulfilledPromiseThen
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Promise Resolution"];
    BAPromise *promise = [[BAPromise alloc] init];
    
    [[promise then:^id(id obj) {
        XCTAssertEqualObjects(obj, @6, @"Expected 6");
        BAPromise *promise2 = [[BAPromise alloc] init];
        dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [promise2 fulfillWithObject:@8];
        });
        return promise2;
    }] done:^(id obj) {
        XCTAssertEqualObjects(obj, @8, @"Expected 8");
        [expectation fulfill];
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [promise fulfillWithObject:@6];
    });
    
    [self waitForExpectationsWithTimeout:0.5 handler:nil];
}

-(void)testRejectedThen
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Promise Resolution"];
    BAPromise *promise = [[BAPromise alloc] init];
    
    [[promise then:^id(id obj) {
        XCTAssertNil(obj);
        return [NSError errorWithDomain:@"whatever"
                                   code:7
                               userInfo:nil];;
    }] done:^(id obj) {
        XCTFail(@"Unexpected fulfillment");
        [expectation fulfill];
    } rejected:^(NSError *error) {
        [expectation fulfill];
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [promise fulfill];
    });
    
    [self waitForExpectationsWithTimeout:0.5 handler:nil];
}

// a rejected promise that is turned back into fulfillment in a 'then' clause
-(void)testUnrejectedThen
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Promise Resolution"];
    BAPromise *promise = [[BAPromise alloc] init];
    
    [[promise then:^id(id obj) {
        XCTFail(@"Unexpected fulfillment");
        return [NSError errorWithDomain:@"whatever"
                                   code:7
                               userInfo:nil];;
    } rejected:^id(id obj) {
        return @3;
    }
      ] done:^(id obj) {
        XCTAssertEqualObjects(obj, @3, @"Unexpected value");
        [expectation fulfill];
    } rejected:^(NSError *error) {
        XCTFail(@"Unexpected rejection");
        [expectation fulfill];
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [promise rejectWithError:[NSError errorWithDomain:@"whatever" code:777 userInfo:nil]];
    });
    
    [self waitForExpectationsWithTimeout:0.5 handler:nil];
}

-(void)testRejectedPromiseThen
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Promise Resolution"];
    BAPromise *promise = [[BAPromise alloc] init];
    
    [[promise then:^id(id obj) {
        XCTAssertEqualObjects(obj, @6, @"Expected 6");
        BAPromise *promise2 = [[BAPromise alloc] init];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [promise2 reject];
        });
        return promise2;
    }] done:^(id obj) {
        XCTFail(@"Unexpected fulfillment");
    } rejected:^(NSError *error) {
        [expectation fulfill];
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [promise fulfillWithObject:@6];
    });
    
    [self waitForExpectationsWithTimeout:0.5 handler:nil];
}

-(void)testThenHelper
{
    id (^block)(id) = ^id(id obj) { return obj; };
    BAPromise *promise = [BAPromise new];
    id promiseMock = OCMPartialMock(promise);
    [[[promiseMock expect] andReturn:nil] then:block rejected:nil finally:nil queue:dispatch_get_main_queue()];
    [promiseMock then:block];
    [promiseMock verify];
}

-(void)testThenRejectedHelper
{
    id (^block)(id) = ^id(id obj) { return obj; };
    BAPromiseThenRejectedBlock block2 = ^NSError *(NSError *obj) { return obj; };
    BAPromise *promise = [BAPromise new];
    id promiseMock = OCMPartialMock(promise);
    [[[promiseMock expect] andReturn:nil] then:block rejected:block2 finally:nil queue:dispatch_get_main_queue()];
    [promiseMock then:block rejected:block2];
    [promiseMock verify];
}

-(void)testThenRejectedPassThru
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Promise Resolution"];
    BAPromise *promise = [BAPromise fulfilledPromise:nil];
    
    [[promise thenRejected:^id(NSError *error) {
        XCTFail(@"unexpected rejection");
        return error;
    }] done:^(id obj) {
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:0.5 handler:nil];
}
@end
