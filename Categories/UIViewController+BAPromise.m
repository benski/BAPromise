//
//  UIViewController+BAPromise.m
//  BAPromise
//
//  Created by Ben Allison on 4/21/16.
//  Copyright © 2016 Ben Allison. All rights reserved.
//

#import "UIViewController+BAPromise.h"
#import "BAPromise.h"

@implementation UIViewController (BAPromise)

-(BAPromise *)promiseDismissViewControllerAnimated:(BOOL)animated
{
    BAPromiseClient *promise = BAPromiseClient.new;
    if (!self.presentedViewController) {
        // TODO(benski) a better error
        return [BAPromiseClient rejectedPromise:[NSError errorWithDomain:@"org.benski.promise" code:0 userInfo:nil]];
    }
    
    [self dismissViewControllerAnimated:animated completion:^{
        [promise fulfill];
    }];
    return promise;
}

-(BAPromise *)promisePresentViewController:(UIViewController *)controller
                                   animated:(BOOL)animated
{
    BAPromiseClient *promise = BAPromiseClient.new;
    [self presentViewController:controller animated:YES completion:^{
        [promise fulfill];
    }];
    return promise;
}

- (BAPromise<NSNumber *> *)promiseTransitionFromViewController:(UIViewController *)fromViewController
                                              toViewController:(UIViewController *)toViewController
                                                      duration:(NSTimeInterval)duration
                                                       options:(UIViewAnimationOptions)options animations:(void (^ __nullable)(void))animations
                                                    completion:(void (^ __nullable)(BOOL finished))completion
{
    BAPromiseClient *promise = BAPromiseClient.new;
    [self transitionFromViewController:fromViewController
                      toViewController:toViewController
                              duration:duration
                               options:options
                            animations:animations
                            completion:^(BOOL finished) {
                                [promise fulfillWithObject:@(finished)];
                            }];
    return promise;
}

@end
