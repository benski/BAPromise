//
//  LeakTests.m
//  BAPromise
//
//  Created by Ben Allison on 11/1/16.
//  Copyright © 2016 Ben Allison. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BAPromise.h"

@interface CancelLeak : NSObject
@property (nonatomic, strong) BACancelToken *token;
@property (nonatomic, strong) XCTestExpectation *expectation;
@end

@implementation CancelLeak
- (void)dealloc
{
    [self.expectation fulfill];
}
@end


@interface CancelLeak2 : NSObject
@property (nonatomic, strong) BACancelToken *token;
@end

@implementation CancelLeak2
- (void)dealloc
{
    [self.token cancel];
}
@end
@interface LeakTests : XCTestCase

@end

@implementation LeakTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testCancelDoesntLeak
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"expect strong reference cycle to be resolved"];
    
    @autoreleasepool {
        CancelLeak *leakTester = CancelLeak.new;
        BAPromiseClient *promise = BAPromiseClient.new;
        leakTester.expectation = expectation;
        leakTester.token = [promise finally:^{
            leakTester.token = nil;
        }];
        [leakTester.token cancel];
    }
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
}

- (void)testCancelLeakDoesntLeakWhenNotNillingToken
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"expect strong reference cycle to be resolved"];
    
    CancelLeak *leakTester = CancelLeak.new;
    leakTester.expectation = expectation;
    leakTester.token = [BAPromiseClient.new
                        finally:^{
                        }];
    
    [leakTester.token cancel];
    leakTester = nil;
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
}


- (void)testCancelDoesntLeakAndAlsoFulfills
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"expect strong reference cycle to be resolved"];
    
    CancelLeak *leakTester = CancelLeak.new;
    leakTester.expectation = expectation;
    BAPromiseClient *promise = BAPromiseClient.new;
    [promise cancelled:^{
        [expectation fulfill];
    }];
    __weak CancelLeak *weakLeak = leakTester;
    leakTester.token = [promise
                        finally:^{
                            weakLeak.token = nil;
                        }];
    
    leakTester = nil;
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
}

- (void)testCancelDOESLeakWhenCapturingSelf
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"expect strong reference cycle to be resolved"];
    
    CancelLeak *leakTester = CancelLeak.new;
    leakTester.expectation = expectation;
    BAPromiseClient *promise = BAPromiseClient.new;
    [promise cancelled:^{
        [expectation fulfill];
    }];
    __weak CancelLeak *weakLeak = leakTester;
    leakTester.token = [promise done:^(id obj) {
        NSLog(@"%@", leakTester.token);
    }
                        finally:^{
                            weakLeak.token = nil;
                        }];
    
    leakTester = nil;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        XCTAssertNotNil(weakLeak);
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
}

- (void)testFulfilledObjectEventuallyReleases
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"expect object to be released eventually"];
    
    __block BACancelToken *token;
    @autoreleasepool {
        CancelLeak *tester = CancelLeak.new;
        tester.expectation = expectation;
        
        BAPromiseClient *client = BAPromiseClient.new;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [client fulfillWithObject:tester];
        });
        
        
        token = [client done:^(id obj) {
            // noop
        } finally:^{
            token = nil;
        }];
    }
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}
@end
