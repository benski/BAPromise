//
//  ThreadTests.m
//  BAPromise
//
//  Created by Ben Allison on 8/8/16.
//  Copyright © 2016 Ben Allison. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BAPromise.h"

@interface ThreadTests : XCTestCase
@property (nonatomic, strong) NSThread *thread;
@end

@implementation ThreadTests

- (void)threadFunc:(id)obj
{
    BOOL shouldKeepRunning = YES;        // global
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    [runLoop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode]; // adding some input source, that is required for runLoop to runing
    while (shouldKeepRunning && [runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]); // starting infinite loop which can be stopped by changing the shouldKeepRunning's value
}

- (void)setUp {
    [super setUp];
    if (!_thread) {
        _thread = [[NSThread alloc ] initWithTarget:self selector:@selector(threadFunc:) object:nil];
        [_thread start];
    }
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Promise should fulfill"];
    
    BAPromiseClient *promise = BAPromiseClient.new;
    
    [promise done:^(id obj){
        XCTAssertEqualObjects(NSThread.currentThread, self.thread);
        [expectation fulfill];
    }
         observed:nil
         rejected:nil
          finally:nil
            queue:nil
           thread:self.thread];
    
    
    [promise fulfill];
    [self waitForExpectationsWithTimeout:0.5 handler:nil];
}


@end
