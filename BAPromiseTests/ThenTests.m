//
//  ThenTests.m
//  BAPromise
//
//  Created by Ben Allison on 6/23/15.
//  Copyright (c) 2015 Ben Allison. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "TestWaiter.h"
#import "BAPromise.h"
#import <OCMock/OCMock.h>

@interface ThenTests : XCTestCase
@property (nonatomic, strong) TestWaiter *waiter;
@end

@implementation ThenTests

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

-(void)testSimpleThen
{
    [_waiter enter];
    BAPromiseClient *promise = [[BAPromiseClient alloc] init];
    
    [[promise then:^id(id obj) {
        XCTAssertNil(obj);
        return @7;
    }] done:^(id obj) {
        XCTAssert([obj isKindOfClass:[NSNumber class]], @"Expected NSNumber");
        XCTAssertEqualObjects(obj, @7, @"Expected 7");
        [_waiter leave];
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [promise fulfill];
    });
    
    XCTAssertFalse([self.waiter waitForSeconds:0.5]);
}

-(void)testPromiseThen
{
    [_waiter enter];
    BAPromiseClient *promise = [[BAPromiseClient alloc] init];
    
    [[promise then:^id(id obj) {
        XCTAssertEqualObjects(obj, @6, @"Expected 6");
        BAPromiseClient *promise2 = [[BAPromiseClient alloc] init];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [promise2 fulfillWithObject:@8];
        });
        return promise2;
    }] done:^(id obj) {
        XCTAssertEqualObjects(obj, @8, @"Expected 8");
        [_waiter leave];
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [promise fulfillWithObject:@6];
    });
    
    
    XCTAssertFalse([self.waiter waitForSeconds:0.5]);
}

-(void)testPromiseThenTwice
{
    [_waiter enter];
    BAPromiseClient *promise = [[BAPromiseClient alloc] init];
    
    [[[promise then:^id(id obj) {
        XCTAssertEqualObjects(obj, @6, @"Expected 6");
        BAPromiseClient *promise2 = [[BAPromiseClient alloc] init];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [promise2 fulfillWithObject:@8];
        });
        return promise2;
    }] then:^id(id obj) {
        XCTAssertEqualObjects(obj, @8, @"Expected 8");
        BAPromiseClient *promise2 = [[BAPromiseClient alloc] init];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [promise2 fulfillWithObject:@NO];
        });
        return promise2;
    }] done:^(id obj) {
        XCTAssertEqualObjects(obj, @NO, @"Expected NO");
        [_waiter leave];
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [promise fulfillWithObject:@6];
    });
    
    
    XCTAssertFalse([self.waiter waitForSeconds:0.5]);
}

-(void)testFulfilledPromiseThen
{
    [_waiter enter];
    BAPromiseClient *promise = [[BAPromiseClient alloc] init];
    
    [[promise then:^id(id obj) {
        XCTAssertEqualObjects(obj, @6, @"Expected 6");
        TestWaiter *waiter = [[TestWaiter alloc] init];
        [waiter enter];
        BAPromiseClient *promise2 = [[BAPromiseClient alloc] init];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [promise2 fulfillWithObject:@8];
            [waiter leave];
        });
        XCTAssertFalse([waiter waitForSeconds:0.5]);
        return promise2;
    }] done:^(id obj) {
        XCTAssertEqualObjects(obj, @8, @"Expected 8");
        [_waiter leave];
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [promise fulfillWithObject:@6];
    });
    
    
    XCTAssertFalse([self.waiter waitForSeconds:0.5]);
}

-(void)testRejectedThen
{
    [_waiter enter];
    BAPromiseClient *promise = [[BAPromiseClient alloc] init];
    
    [[promise then:^id(id obj) {
        XCTAssertNil(obj);
        return [NSError errorWithDomain:@"whatever"
                                   code:7
                               userInfo:nil];;
    }] done:^(id obj) {
        XCTFail(@"Unexpected fulfillment");
        [_waiter leave];
    } rejected:^(NSError *error) {
        [_waiter leave];
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [promise fulfill];
    });
    
    XCTAssertFalse([self.waiter waitForSeconds:0.5]);
}

// a rejected promise that is turned back into fulfillment in a 'then' clause
-(void)testUnrejectedThen
{
    [_waiter enter];
    BAPromiseClient *promise = [[BAPromiseClient alloc] init];
    
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
        [_waiter leave];
    } rejected:^(NSError *error) {
        XCTFail(@"Unexpected rejection");
        [_waiter leave];
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [promise rejectWithError:[NSError errorWithDomain:@"whatever" code:777 userInfo:nil]];
    });
    
    XCTAssertFalse([self.waiter waitForSeconds:0.5]);
}

-(void)testRejectedPromiseThen
{
    [_waiter enter];
    BAPromiseClient *promise = [[BAPromiseClient alloc] init];
    
    [[promise then:^id(id obj) {
        XCTAssertEqualObjects(obj, @6, @"Expected 6");
        BAPromiseClient *promise2 = [[BAPromiseClient alloc] init];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [promise2 reject];
        });
        return promise2;
    }] done:^(id obj) {
        XCTFail(@"Unexpected fulfillment");
    } rejected:^(NSError *error) {
        [_waiter leave];
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [promise fulfillWithObject:@6];
    });
    
    
    XCTAssertFalse([self.waiter waitForSeconds:0.5]);
}

-(void)testThenHelper
{
    id (^block)(id) = ^id(id obj) { return obj; };
    BAPromise *promise = [BAPromise new];
    id promiseMock = OCMPartialMock(promise);
    [[[promiseMock expect] andReturn:nil] then:block rejected:nil finally:nil queue:dispatch_get_current_queue()];
    [promiseMock then:block];
    [promiseMock verify];
}

-(void)testThenRejectedHelper
{
    id (^block)(id) = ^id(id obj) { return obj; };
    BAPromiseThenRejectedBlock block2 = ^NSError *(NSError *obj) { return obj; };
    BAPromise *promise = [BAPromise new];
    id promiseMock = OCMPartialMock(promise);
    [[[promiseMock expect] andReturn:nil] then:block rejected:block2 finally:nil queue:dispatch_get_current_queue()];
    [promiseMock then:block rejected:block2];
    [promiseMock verify];
}
@end
