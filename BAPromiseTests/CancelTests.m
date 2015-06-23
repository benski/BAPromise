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

-(void)testDoneAfterCancel
{
    BAPromiseClient *promise = [[BAPromiseClient alloc] init];
    [_waiter enter];
    [promise cancelled:^{
        [_waiter leave];
    }];
    
    [[promise done:^(id obj) {
        XCTFail(@"Cancelation should prevent calling of done block");
    } observed:^(id obj) {
        XCTFail(@"Cancelation should prevent calling of observed block");
    } rejected:^(NSError *error) {
        XCTFail(@"Cancelation should prevent calling of rejected block");
    } finally:^{
        XCTFail(@"Cancelation should prevent calling of finally block");
    } queue:dispatch_get_current_queue()] cancel];
    
    XCTAssertFalse([self.waiter waitForSeconds:0.5]);
    [TestWaiter pumpForSeconds:0.1];
}

-(void)testCancelTokenAfterFulfillment
{
    BAPromiseClient *promise = [[BAPromiseClient alloc] init];
    [promise fulfill];
    [promise cancelled:^{
        XCTFail(@"Unexpected cancelled callback");
    }];
    [[promise done:^(id obj){}] cancel];
    [TestWaiter pumpForSeconds:0.1];
}

-(void)testCancelPromiseAfterFulfilment
{
    BAPromiseClient *promise = [[BAPromiseClient alloc] init];
    [promise fulfill];
    [promise cancelled:^{
        XCTFail(@"Unexpected cancelled callback");
    }];
    [promise cancel];
    [TestWaiter pumpForSeconds:0.1];
}

-(void)testCancelPromiseAfterRejection
{
    BAPromiseClient *promise = [[BAPromiseClient alloc] init];
    [promise reject];
    [promise cancelled:^{
        XCTFail(@"Unexpected cancelled callback");
    }];
    [promise cancel];
    [TestWaiter pumpForSeconds:0.1];
}


-(void)testLateCancelCallback
{
    [_waiter enter];
    BAPromiseClient *promise = [[BAPromiseClient alloc] init];
    [promise cancel];
    [promise cancelled:^{
         [_waiter leave];
    }];
     XCTAssertFalse([self.waiter waitForSeconds:0.5]);
}
@end
