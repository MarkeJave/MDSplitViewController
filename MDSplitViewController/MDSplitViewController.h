//
//  MDSplitViewController.h
//  Modool
//
//  Created by xulinfeng on 2018/11/27.
//  Copyright © 2018 modool. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MDSplitViewController : UISplitViewController

@property (nonatomic, strong, readonly) UIViewController *masterViewController;
@property (nonatomic, strong, readonly) UIViewController *detailViewController;

@property (nonatomic, strong, readonly) UIPanGestureRecognizer *panGestureRecognizer;

@property (nonatomic, assign, readonly) UISplitViewControllerDisplayMode requiredDisplayMode;

// Default 0.3f.
@property (nonatomic, assign, readonly) CGFloat animatedDuration;

@property (nonatomic, assign, getter=isReversingPrimaryViewController) BOOL reversingPrimaryViewController;

- (void)setPreferredDisplayMode:(UISplitViewControllerDisplayMode)preferredDisplayMode animated:(BOOL)animated;

@end

@interface UIViewController (MDSplitViewController)

@property (nonatomic, strong, readonly) MDSplitViewController *splitViewController;

- (void)showViewController:(UIViewController *)viewController animated:(BOOL)animated;
- (void)showViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(nullable void (^)(void))completion;

- (void)showDetailViewController:(UIViewController *)viewController animated:(BOOL)animated;
- (void)showDetailViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(nullable void (^)(void))completion;

@end

NS_ASSUME_NONNULL_END
