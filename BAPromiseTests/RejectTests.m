//
//  RejectTests.m
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

@interface RejectTests : XCTestCase
@property (nonatomic, strong) TestWaiter *waiter;
@end

@implementation RejectTests

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

-(void)testRejectionAsynchronous
{
    BAPromiseClient *promise = [[BAPromiseClient alloc] init];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [promise rejectWithError:[[NSError alloc] init]];
    });
    
    [_waiter enter];
    [promise done:^(id obj) {
        XCTFail(@"Unexpected fulfillment");
        [_waiter leave];
    } rejected:^(NSError *error) {
        [_waiter leave];
    }];
    
    XCTAssertFalse([self.waiter waitForSeconds:0.5]);
}

-(void)testRejectionFirst
{
    BAPromiseClient *promise = [[BAPromiseClient alloc] init];
    [promise rejectWithError:[[NSError alloc] init]];
    
    [_waiter enter];
    [promise done:^(id obj) {
        XCTFail(@"Unexpected fulfillment");
        [_waiter leave];
    } rejected:^(NSError *error) {
        [_waiter leave];
    }];
    
    XCTAssertFalse([self.waiter waitForSeconds:0.5]);
}

-(void)testRejectionSecond
{
    BAPromiseClient *promise = [[BAPromiseClient alloc] init];
    
    [_waiter enter];
    [promise done:^(id obj) {
        XCTFail(@"Unexpected fulfillment");
        [_waiter leave];
    } rejected:^(NSError *error) {
        [_waiter leave];
    }];
    
    [promise rejectWithError:[[NSError alloc] init]];
    XCTAssertFalse([self.waiter waitForSeconds:0.5]);
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
    BAPromiseOnFulfilledBlock block = ^(id obj) {};
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
    BAPromiseClient *promise = [BAPromiseClient new];
    id promiseMock = OCMPartialMock(promise);
    [[promiseMock expect] rejectWithError:OCMOCK_ANY];
    [promise reject];
    [promiseMock verify];
}
@end
