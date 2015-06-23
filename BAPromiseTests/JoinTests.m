//
//  JoinTests.m
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

@interface JoinTests : XCTestCase
@property (nonatomic, strong) TestWaiter *waiter;
@end

@implementation JoinTests

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

- (void)testJoins
{
    [_waiter enter];
    
    BAPromiseClient *promise1 = [[BAPromiseClient alloc] init];
    BAPromiseClient *promise2 = [[BAPromiseClient alloc] init];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [promise1 fulfill];
        [promise2 fulfill];
    });
    
    BAPromise * joined = [@[promise1, promise2] joinPromises];
    
    [joined done:^(NSArray *obj) {
        [_waiter leave];
    }];
    
    XCTAssertFalse([self.waiter waitForSeconds:0.5]);
}

- (void)testJoinedData
{
    [_waiter enter];
    
    BAPromiseClient *promise1 = [[BAPromiseClient alloc] init];
    BAPromiseClient *promise2 = [[BAPromiseClient alloc] init];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [promise1 fulfillWithObject:@3];
        [promise2 fulfillWithObject:@4];
    });
    
    BAPromise * joined = [@[promise1, promise2] joinPromises];
    
    [joined done:^(NSArray *obj) {
        XCTAssertEqual(obj.count, 2, @"Unexpected array size");
        for (NSNumber *value in obj) {
            XCTAssert([value isEqualToValue:@3] || [value isEqualToValue:@4], @"Unexpected value, %@", value);
        }
        [_waiter leave];
    } rejected:^(NSError *error) {
        XCTFail(@"Unexpected Failure");
        [_waiter leave];
    }];
    
    XCTAssertFalse([self.waiter waitForSeconds:0.5]);
}

- (void)testRejectedJoin
{
    [_waiter enter];
    
    BAPromiseClient *promise1 = [[BAPromiseClient alloc] init];
    BAPromiseClient *promise2 = [[BAPromiseClient alloc] init];
    BAPromiseClient *promise3 = [[BAPromiseClient alloc] init];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [promise1 fulfill];
        [promise2 rejectWithError:[NSError errorWithDomain:@"some_domain" code:11 userInfo:nil]];
        [promise3 rejectWithError:[NSError errorWithDomain:@"some_domain" code:22 userInfo:nil]];
    });
    
    BAPromise * joined = [@[promise1, promise2, promise3] joinPromises];
    
    [joined done:^(NSArray *obj) {
        XCTFail(@"Unexpected Fulfillment");
        [_waiter leave];
    } rejected:^(NSError *error) {
        
        [_waiter leave];
    }];
    
    XCTAssertFalse([self.waiter waitForSeconds:0.5]);
}

- (void)testDoubleRejectedJoin
{
    [_waiter enter];
    
    BAPromiseClient *promise1 = [[BAPromiseClient alloc] init];
    BAPromiseClient *promise2 = [[BAPromiseClient alloc] init];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [promise1 reject];
        [promise2 reject];
    });
    
    BAPromise * joined = [@[promise1, promise2] joinPromises];
    __block BOOL calledAlready=NO;
    [joined done:^(NSArray *obj) {
        XCTFail(@"Unexpected Fulfillment");
        [_waiter leave];
    } rejected:^(NSError *error) {
        XCTAssert(!calledAlready, @"Should only fail once");
        calledAlready = YES;
        [_waiter leave];
    }];
    
    XCTAssertFalse([self.waiter waitForSeconds:0.5]);
}

- (void)testJoinElementsInOrder
{
    [_waiter enter];
    BAPromiseClient *promise1 = [[BAPromiseClient alloc] init];
    BAPromiseClient *promise2 = [[BAPromiseClient alloc] init];
    
    BAPromise * joined = [@[promise1, [promise2 then:^id(id obj) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [promise1 fulfillWithObject:@1];
        });
        return obj;
    }]] joinPromises];
    [joined done:^(NSArray *obj) {
        XCTAssertEqual(obj.count, 2);
        XCTAssertEqualObjects(obj[0], @1);
        XCTAssertEqualObjects(obj[1], @2);
        [_waiter leave];
    } rejected:^(NSError *error) {
        XCTFail(@"Unexpected Error");
        [_waiter leave];
    }];
    
    [promise2 fulfillWithObject:@2];
    
    XCTAssertFalse([self.waiter waitForSeconds:0.5]);
}
@end
