//
//  UIViewController+BAPromise.m
//  BAPromise
//
//  Created by Ben Allison on 4/21/16.
//  Copyright © 2016 Ben Allison. All rights reserved.
//

#import "UIViewController+BAPromise.h"
#import "BAPromiseClient.h"

@implementation UIViewController (BAPromise)

-(BAPromise *)promise_DismissViewControllerAnimated:(BOOL)animated
{
    BAPromiseClient *promise = BAPromiseClient.new;
    if (!self.presentedViewController) {
        // TODO(benski) a better error
        return [promise rejectedPromise:[NSError errorWithDomain:@"org.benski.promise" code:0 info:nil]];
    }
    
    [self dismissViewControllerAnimated:animated completion:^{
        [promise fulfil];
    }];
    return promise;
}

-(BAPromise *)promise_presentViewController:(UIViewController *)controller
                                   animated:(BOOL)animated
{
    BAPromiseClient *promise = BAPromiseClient.new;
    [self presentViewController:controller animated:YES completion:^{
        [promise fullfil];
    }];
    return promise;
}

- (BAPromise<NSNumber *> *)transitionFromViewController:(UIViewController *)fromViewController toViewController:(UIViewController *)toViewController duration:(NSTimeInterval)duration options:(UIViewAnimationOptions)options animations:(void (^ __nullable)(void))animations completion:(void (^ __nullable)(BOOL finished))completion
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
