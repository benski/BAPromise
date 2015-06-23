//
//  ChainTests.m
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

@interface ChainTests : XCTestCase
@property (nonatomic, strong) TestWaiter *waiter;
@end

@implementation ChainTests

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

// calling fulfillWithObject:somePromise calls when, so we'll test that (the rest of the tests just test 'when'
-(void)testSimpleFulfill
{
    [_waiter enter];
    BAPromiseClient *promise = [[BAPromiseClient alloc] init];
    BAPromise *anotherPromise = [BAPromiseClient fulfilledPromise:@7];
    
    [promise fulfillWithObject:anotherPromise];
    [promise done:^(id obj) {
        XCTAssert([obj isKindOfClass:[NSNumber class]], @"Expected NSNumber");
        XCTAssertEqualObjects(obj, @7, @"Expected 7");
        [_waiter leave];
    }];
    
    XCTAssertFalse([self.waiter waitForSeconds:0.5]);
}

-(void)testSimpleWhen
{
    [_waiter enter];
    BAPromiseClient *promise = [[BAPromiseClient alloc] init];
    BAPromise *anotherPromise = [BAPromiseClient fulfilledPromise:@7];
    
    [promise fulfillWithObject:anotherPromise];
    [promise done:^(id obj) {
        XCTAssert([obj isKindOfClass:[NSNumber class]], @"Expected NSNumber");
        XCTAssertEqualObjects(obj, @7, @"Expected 7");
        [_waiter leave];
    }];
    
    XCTAssertFalse([self.waiter waitForSeconds:0.5]);
}

-(void)testAsyncWhen
{
    [_waiter enter];
    BAPromiseClient *promise = [[BAPromiseClient alloc] init];
    BAPromise *anotherPromise = [BAPromiseClient new];
    
    [promise fulfillWithObject:anotherPromise];
    [promise done:^(id obj) {
        XCTAssert([obj isKindOfClass:[NSNumber class]], @"Expected NSNumber");
        XCTAssertEqualObjects(obj, @7, @"Expected 7");
        [_waiter leave];
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [promise fulfillWithObject:@7];
    });
    
    XCTAssertFalse([self.waiter waitForSeconds:0.5]);
}

-(void)testSimpleWhenFail
{
    [_waiter enter];
    BAPromiseClient *promise = [[BAPromiseClient alloc] init];
    BAPromise *anotherPromise = [BAPromiseClient rejectedPromise:nil];
    
    [promise fulfillWithObject:anotherPromise];
    [promise rejected:^(id obj) {
        [_waiter leave];
    }];
    
    XCTAssertFalse([self.waiter waitForSeconds:0.5]);
}

-(void)testAsyncWhenFail
{
    [_waiter enter];
    BAPromiseClient *promise = [[BAPromiseClient alloc] init];
    BAPromise *anotherPromise = [BAPromiseClient new];
    
    [promise fulfillWithObject:anotherPromise];
    [promise rejected:^(id obj) {
        [_waiter leave];
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [promise reject];
    });
    
    XCTAssertFalse([self.waiter waitForSeconds:0.5]);
}

-(void)testSimpleWhenFinallyDone
{
    [_waiter enter];
    BAPromiseClient *promise = [[BAPromiseClient alloc] init];
    BAPromise *anotherPromise = [BAPromiseClient fulfilledPromise:nil];
    
    [promise fulfillWithObject:anotherPromise];
    [promise finally:^() {
        [_waiter leave];
    }];
    
    XCTAssertFalse([self.waiter waitForSeconds:0.5]);
}

-(void)testSimpleWhenFinallyFail
{
    [_waiter enter];
    BAPromiseClient *promise = [[BAPromiseClient alloc] init];
    BAPromise *anotherPromise = [BAPromiseClient rejectedPromise:nil];
    
    [promise fulfillWithObject:anotherPromise];
    [promise finally:^() {
        [_waiter leave];
    }];
    
    XCTAssertFalse([self.waiter waitForSeconds:0.5]);
}

-(void)testAsyncWhenFinallyDone
{
    [_waiter enter];
    BAPromiseClient *promise = [[BAPromiseClient alloc] init];
    BAPromise *anotherPromise = [BAPromiseClient new];
    
    [promise fulfillWithObject:anotherPromise];
    [promise finally:^() {
        [_waiter leave];
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [promise fulfillWithObject:nil];
    });
    
    XCTAssertFalse([self.waiter waitForSeconds:0.5]);
}

-(void)testAsyncWhenFinallyFail
{
    [_waiter enter];
    BAPromiseClient *promise = [[BAPromiseClient alloc] init];
    BAPromise *anotherPromise = [BAPromiseClient new];
    
    [promise fulfillWithObject:anotherPromise];
    [promise finally:^() {
        [_waiter leave];
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [promise reject];
    });
    
    XCTAssertFalse([self.waiter waitForSeconds:0.5]);
}

@end
