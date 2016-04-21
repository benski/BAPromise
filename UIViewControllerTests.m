//
//  UIViewController+BAPromiseTests.m
//  BAPromise
//
//  Created by Ben Allison on 4/21/16.
//  Copyright © 2016 Ben Allison. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "UIViewController+BAPromise.h"

@interface UIViewController_BAPromiseTests : XCTestCase

@end

@implementation UIViewController_BAPromiseTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testPresentAnimated {
    
    UIViewController *vc = UIViewController.new;
    UIViewController *present = UIViewController.new;
    UIApplication.sharedApplication.keyWindow.rootViewController = vc;
    XCTestExpectation *expectation = [self expectationWithDescription:@"Promise should fulfill"];
    
    [[vc promisePresentViewController:present animated:YES] done:^(id obj) {
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testPresentNonAnimated {
    
    UIViewController *vc = UIViewController.new;
    UIViewController *present = UIViewController.new;
    UIApplication.sharedApplication.keyWindow.rootViewController = vc;
    XCTestExpectation *expectation = [self expectationWithDescription:@"Promise should fulfill"];
    
    [[vc promisePresentViewController:present animated:NO] done:^(id obj) {
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testDismiss {
    
    UIViewController *vc = UIViewController.new;
    UIViewController *present = UIViewController.new;
    UIApplication.sharedApplication.keyWindow.rootViewController = vc;
    XCTestExpectation *expectation = [self expectationWithDescription:@"Promise should fulfill"];
    
    [[[vc promisePresentViewController:present animated:YES] then:^(id obj) {
        return [vc promiseDismissViewControllerAnimated:YES];
    }] done:^(id obj) {
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:4.0 handler:nil];
}

@end
