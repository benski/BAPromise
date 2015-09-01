//
//  TestWaiter.h
//  BAPromise
//
//  Created by Ben Allison on 6/22/15.
//  Copyright (c) 2015 Ben Allison. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TestWaiter : NSObject
-(void)enter;
-(void)leave;
-(BOOL)waitForSeconds:(double)seconds;
@end
