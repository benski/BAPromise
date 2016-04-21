//
//  UIViewController+BAPromise.h
//  BAPromise
//
//  Created by Ben Allison on 4/21/16.
//  Copyright © 2016 Ben Allison. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (BAPromise)

-(BAPromise *)promise_DismissViewControllerAnimated:(BOOL)animated;
-(BAPromise *)promise_presentViewController:(UIViewController *)controller
                                   animated:(BOOL)animated;
- (BAPromise<NSNumber *> *)transitionFromViewController:(UIViewController *)fromViewController
                                       toViewController:(UIViewController *)toViewController
                                               duration:(NSTimeInterval)duration
                                                options:(UIViewAnimationOptions)options
                                             animations:(void (^ __nullable)(void))animations
                                             completion:(void (^ __nullable)(BOOL finished))completion;

@end
