//
//  TestWaiter.h
//  BAPromise
//
//  Created by Ben Allison on 6/22/15.
//  Copyright (c) 2015 Ben Allison. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Foundation/Foundation.h>
#import "BAPromise.h"

@interface XCTestCase (Promise)
// helper methods that create an XCTestExpectation (not returned) that fulfills on promise resolution
// note: we should use these sparingly in the BAPromise test suite, because the logic assumes properly working promises
-(void)expectPromiseFulfillment:(BAPromise *)promise; // XCTFails on rejected
-(void)expectPromiseRejection:(BAPromise *)promise; // XCTFails on done
-(void)expectPromiseResolution:(BAPromise *)promise;
@end
