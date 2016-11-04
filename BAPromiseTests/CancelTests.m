//
//  CancelTests.m
//  BAPromise
//
//  Created by Ben Allison on 6/22/15.
//  Copyright (c) 2015 Ben Allison. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TestWaiter.h"
#import "BAPromise.h"

@interface CancelTests : XCTestCase

@end

@implementation CancelTests

-(void)setUp
{
    [super setUp];
}

-(void)tearDown
{
    [super tearDown];
}

-(void)testCancel
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Promise Resolution"];
    BAPromiseClient *promise = [[BAPromiseClient alloc] init];
    [promise cancelled:^{
        [expectation fulfill];
    }];
    [promise cancel];
    [self waitForExpectationsWithTimeout:0.5 handler:nil];
}

-(void)testDoneAfterCancel
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Promise Resolution"];
    BAPromiseClient *promise = [[BAPromiseClient alloc] init];
    [promise cancelled:^{
        [expectation fulfill];
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
    
    [self waitForExpectationsWithTimeout:0.5 handler:nil];
    [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
}

-(void)testCancelTokenAfterFulfillment
{
    BAPromiseClient *promise = [[BAPromiseClient alloc] init];
    [promise fulfill];
    [promise cancelled:^{
        XCTFail(@"Unexpected cancelled callback");
    }];
    [[promise done:^(id obj){}] cancel];
    [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
}

-(void)testCancelPromiseAfterFulfilment
{
    BAPromiseClient *promise = [[BAPromiseClient alloc] init];
    [promise fulfill];
    [promise cancelled:^{
        XCTFail(@"Unexpected cancelled callback");
    }];
    [promise cancel];
    [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
}

-(void)testCancelPromiseAfterRejection
{
    BAPromiseClient *promise = [[BAPromiseClient alloc] init];
    [promise reject];
    [promise cancelled:^{
        XCTFail(@"Unexpected cancelled callback");
    }];
    [promise cancel];
    [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
}

-(void)testLateCancelCallback
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Promise Resolution"];
    BAPromiseClient *promise = [[BAPromiseClient alloc] init];
    [promise cancel];
    [promise cancelled:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:0.5 handler:nil];
}

-(void)testCancelToken
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Promise Resolution"];
    BAPromiseClient *promise = [[BAPromiseClient alloc] init];
    [promise cancelled:^{
        XCTFail(@"unepected onCancel");
    }];
    [promise fulfill];
    BACancelToken *token = [promise done:^(id obj) {
        XCTFail(@"unepected fulfillment");
    }];
    [token cancel];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:0.5 handler:nil];
    
}

-(void)testCancelAsyncARC
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Promise Resolution"];
    BAPromiseClient *promise = [[BAPromiseClient alloc] init];
    [promise cancelled:^{
        XCTFail(@"unepected onCancel");
    }];
    dispatch_async(dispatch_get_main_queue(), ^{
        [promise fulfill];
        BACancelToken *token = [promise done:^(id obj) {
            XCTFail(@"unepected fulfillment");
        }];
        [token cancel];
        
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:0.5 handler:nil];
}

-(void)testCancelTokenReject
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Promise Resolution"];
    BAPromiseClient *promise = [[BAPromiseClient alloc] init];
    [promise cancelled:^{
     XCTFail(@"unepected onCancel");
    }];
    [promise rejectWithError:[NSError errorWithDomain:@"org.benski" code:0 userInfo:nil]];
    BACancelToken *token = [promise rejected:^(NSError *obj) {
        XCTFail(@"unepected rejection");
    }];
    [token cancel];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:0.5 handler:nil];
    
}

-(void)testCancelAsyncARCReject
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Promise Resolution"];
    BAPromiseClient *promise = [[BAPromiseClient alloc] init];
    [promise cancelled:^{
        XCTFail(@"unepected onCancel");
    }];

    dispatch_async(dispatch_get_main_queue(), ^{
        [promise rejectWithError:[NSError errorWithDomain:@"org.benski" code:0 userInfo:nil]];
        BACancelToken *token = [promise rejected:^(NSError *error) {
            XCTFail(@"unepected rejection");
        }];
        [token cancel];
        
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:0.5 handler:nil];
}

-(void)testCancelThen
{
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"Promise reached inside of then block"];
    BAPromiseClient *thenPromise = BAPromiseClient.new;
    
    BACancelToken *cancelToken = [[BAPromiseClient fulfilledPromise:nil] then:^id(id obj) {
        [expectation1 fulfill];
        return thenPromise;
    }];
    
    [self waitForExpectationsWithTimeout:0.5 handler:nil];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"Inner Promise cancelled"];

    [thenPromise cancelled:^{
        [expectation2 fulfill];
    }];
    
    [cancelToken cancel];
    [self waitForExpectationsWithTimeout:0.5 handler:nil];
}

-(void)testCancelThenRaceCondition
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Promise reached inside of then block"];
    BAPromiseClient *thenPromise = BAPromiseClient.new;
    [thenPromise cancelled:^{
        [expectation fulfill];
    }];
    
    BACancelToken *cancelToken = [[BAPromiseClient fulfilledPromise:nil] then:^id(id obj) {
        [cancelToken cancel];
        return thenPromise;
    }];

    [cancelToken cancel];
    [self waitForExpectationsWithTimeout:0.5 handler:nil];
}
@end
