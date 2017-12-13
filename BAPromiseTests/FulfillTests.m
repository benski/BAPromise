//
//  FulfillTests.m
//  OS XTests
//
//  Created by Ben Allison on 12/13/17.
//  Copyright © 2017 Ben Allison. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TestWaiter.h"

@interface FulfillTests : XCTestCase

@end

@implementation FulfillTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testFulfillWithPromise
{
    BAPromise *promise = BAPromise.new;
    BAPromise *anotherPromise = BAPromise.new;
    
    [self expectPromiseFulfillment:promise];
    
    [promise fulfillWithObject:anotherPromise];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [anotherPromise fulfill];
    });
    
    [promise reject];

    [self waitForExpectationsWithTimeout:0.5 handler:nil];
}
@end
