//
//  UIViewController+BAPromise.h
//  BAPromise
//
//  Created by Ben Allison on 4/21/16.
//  Copyright © 2016 Ben Allison. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BAPromise.h"

@interface UIViewController (BAPromise)

-(BAPromise *)promiseDismissViewControllerAnimated:(BOOL)animated;
-(BAPromise *)promisePresentViewController:(UIViewController *)controller
                                   animated:(BOOL)animated;
- (BAPromise<NSNumber *> *)transitionFromViewController:(UIViewController *)fromViewController
                                       toViewController:(UIViewController *)toViewController
                                               duration:(NSTimeInterval)duration
                                                options:(UIViewAnimationOptions)options
                                             animations:(void (^ __nullable)(void))animations
                                             completion:(void (^ __nullable)(BOOL finished))completion;

@end
