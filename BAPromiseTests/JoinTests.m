//
//  JoinTests.m
//  BAPromise
//
//  Created by Ben Allison on 6/23/15.
//  Copyright (c) 2015 Ben Allison. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TestWaiter.h"
#import "BAPromise.h"
#import <OCMock/OCMock.h>

@interface JoinTests : XCTestCase
@end

@implementation JoinTests

-(void)setUp
{
    [super setUp];
}

-(void)tearDown
{
    [super tearDown];
}

- (void)testJoins
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Joined Promise should fulfill"];
    
    BAPromiseClient *promise1 = [[BAPromiseClient alloc] init];
    BAPromiseClient *promise2 = [[BAPromiseClient alloc] init];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [promise1 fulfill];
        [promise2 fulfill];
    });
    
    BAPromise * joined = [@[promise1, promise2] whenPromises];
    
    [joined rejected:^(NSError *error) {
        XCTFail(@"Unexpected rejection - %@", error);
    } finally:^{
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:0.5 handler:nil];
}

- (void)testJoinedData
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Joined Promise should fulfill"];
    
    BAPromiseClient *promise1 = [[BAPromiseClient alloc] init];
    BAPromiseClient *promise2 = [[BAPromiseClient alloc] init];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [promise1 fulfillWithObject:@3];
        [promise2 fulfillWithObject:@4];
    });
    
    BAPromise * joined = [@[promise1, promise2] whenPromises];
    
    [joined done:^(NSArray *obj) {
        XCTAssertTrue([obj isKindOfClass:NSArray.class]);
        XCTAssertEqual(obj.count, 2, @"Unexpected array size");
        for (NSNumber *value in obj) {
            XCTAssert([value isEqualToValue:@3] || [value isEqualToValue:@4], @"Unexpected value, %@", value);
        }
    } rejected:^(NSError *error) {
        XCTFail(@"Unexpected rejection - %@", error);
    } finally:^{
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:0.5 handler:nil];
}

- (void)testRejectedJoin
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Joined Promise should reject when one at least promise rejects"];
    
    BAPromiseClient *promise1 = [[BAPromiseClient alloc] init];
    BAPromiseClient *promise2 = [[BAPromiseClient alloc] init];
    BAPromiseClient *promise3 = [[BAPromiseClient alloc] init];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [promise1 fulfill];
        [promise2 rejectWithError:[NSError errorWithDomain:@"some_domain" code:11 userInfo:nil]];
        [promise3 rejectWithError:[NSError errorWithDomain:@"some_domain" code:22 userInfo:nil]];
    });
    
    BAPromise * joined = [@[promise1, promise2, promise3] whenPromises];
    
    [joined done:^(NSArray *obj) {
        XCTFail(@"Unexpected Fulfillment");
    } finally:^{
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:0.5 handler:nil];
}

- (void)testDoubleRejectedJoin
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Joined Promise should only reject once"];
    
    BAPromiseClient *promise1 = [[BAPromiseClient alloc] init];
    BAPromiseClient *promise2 = [[BAPromiseClient alloc] init];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [promise1 reject];
        [promise2 reject];
    });
    
    BAPromise * joined = [@[promise1, promise2] whenPromises];
    __block BOOL calledAlready=NO;
    [joined done:^(NSArray *obj) {
        XCTFail(@"Unexpected Fulfillment");
    } rejected:^(NSError *error) {
        XCTAssert(!calledAlready, @"Should only fail once");
        calledAlready = YES;
    } finally:^{
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:0.5 handler:nil];
}

- (void)testJoinElementsInOrder
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Joined Promise should fulfill"];
    BAPromiseClient *promise1 = [[BAPromiseClient alloc] init];
    BAPromiseClient *promise2 = [[BAPromiseClient alloc] init];
    
    BAPromise * joined = [@[promise1, [promise2 then:^id(id obj) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [promise1 fulfillWithObject:@1];
        });
        return obj;
    }]] whenPromises];
    [joined done:^(NSArray *obj) {
        XCTAssertEqual(obj.count, 2);
        XCTAssertEqualObjects(obj[0], @1);
        XCTAssertEqualObjects(obj[1], @2);
    } rejected:^(NSError *error) {
        XCTFail(@"Unexpected Error");
    } finally:^{
        [expectation fulfill];
    }];
    
    [promise2 fulfillWithObject:@2];
    
    [self waitForExpectationsWithTimeout:0.5 handler:nil];
}

-(void)testJoinRejectionCancelsOtherPromises
{
    BAPromiseClient *promise1 = [[BAPromiseClient alloc] init];
    BAPromiseClient *promise2 = [[BAPromiseClient alloc] init];
    
    XCTestExpectation *cancelExpectation = [self expectationWithDescription:@"Joined Promise should cancel"];
    [promise2 cancelled:^{
        [cancelExpectation fulfill];
    }];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Joined Promise should reject"];
    [@[promise1, promise2].whenPromises done:^(id obj) {
        XCTFail(@"Unexpected Fulfillment");
    } finally:^{
        [expectation fulfill];
    }];
    
    [promise1 reject];
    [self waitForExpectationsWithTimeout:0.5 handler:nil];
}

-(void)testJoinEmptyArrayReturnsValidPromise
{
    XCTAssertNotNil(@[].whenPromises);
}

-(void)testJoinEmptyArray
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Promise should complete"];
    [@[].whenPromises done:^(NSArray *obj) {
        XCTAssertNil(obj);
        XCTAssertTrue(@YES, @"Just noting which path the promise should follow");
    } rejected:^(NSError *error) {
        XCTFail(@"Unexpected Rejection");
    } finally:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:0.5 handler:nil];
}

-(void)testJoinedPromiseWithNilFulfillment
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Joined Promise should complete"];
    
    BAPromiseClient *promise1 = [BAPromiseClient fulfilledPromise:nil];
    BAPromiseClient *promise2 = [BAPromiseClient fulfilledPromise:@2];
    
    [@[promise1, promise2].whenPromises done:^(NSArray *obj) {
        XCTAssertEqual(obj.count, 2);
        XCTAssertEqualObjects(obj[0], [NSNull null]);
        XCTAssertEqualObjects(obj[1], @2);
    } rejected:^(NSError *error) {
        XCTFail(@"Unexpected Rejection");
    } finally:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:0.5 handler:nil];
}

@end
