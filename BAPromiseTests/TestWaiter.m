//
//  TestWaiter.m
//  BAPromise
//
//  Created by Ben Allison on 6/22/15.
//  Copyright (c) 2015 Ben Allison. All rights reserved.
//

#import "TestWaiter.h"
#import "BAPromise.h"

@implementation XCTestCase (Promise)

-(void)expectPromiseRejection:(BAPromise *)promise
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Promise Fulfillment"];
    [promise done:^(id obj) {
        XCTFail(@"Unexpected Fulfillment - %@", obj);
    } finally:^{
        [expectation fulfill];
    }];
}

-(void)expectPromiseFulfillment:(BAPromise *)promise
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Promise Fulfillment"];
    [promise rejected:^(NSError *error) {
        XCTFail(@"Unexpected Rejection - %@", error);
    } finally:^{
        [expectation fulfill];
    }];
}

-(void)expectPromiseResolution:(BAPromise *)promise
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Promise Resolution"];
    [promise finally:^{
        [expectation fulfill];
    }];
}

@end
