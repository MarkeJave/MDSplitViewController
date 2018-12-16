//
//  MDSplitViewController.m
//  Modool
//
//  Created by xulinfeng on 2018/11/27.
//  Copyright © 2018 modool. All rights reserved.
//

#import "MDSplitViewController.h"

const CGFloat MDSplitViewControllerPrimaryHiddenMaximumFraction = .75f;

@interface MDSplitViewController () <UIGestureRecognizerDelegate>

@property (nonatomic, strong, readonly) UIViewController *placeholderDetailViewController;

@property (nonatomic, assign, readonly) CGFloat requiredPreferredPrimaryColumnWidthFraction;

@end

@implementation MDSplitViewController
@dynamic preferredDisplayMode, displayMode;

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        _animatedDuration = .3f;
        _requiredPreferredPrimaryColumnWidthFraction = .4f;
        _requiredDisplayMode = UISplitViewControllerDisplayModeAllVisible;

        _placeholderDetailViewController = [[UIViewController alloc] init];
        _placeholderDetailViewController.view.backgroundColor = [UIColor whiteColor];

        _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPanGestureRecognizer:)];
        _panGestureRecognizer.delegate = self;
    }
    return self;
}

- (void)loadView {
    [super loadView];

    [self.view addGestureRecognizer:_panGestureRecognizer];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    super.minimumPrimaryColumnWidth = 0;
    super.maximumPrimaryColumnWidth = self.view.bounds.size.width;
    super.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;

    [self _updateFractionAnimated:NO completion:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

#pragma mark - accessor

- (UIViewController *)masterViewController {
    return self.viewControllers.firstObject;
}

- (UIViewController *)detailViewController {
    if (self.viewControllers.count <= 1) return nil;

    UIViewController *detailViewController = self.viewControllers.lastObject;
    return detailViewController == _placeholderDetailViewController ? nil : detailViewController;
}

- (void)setViewControllers:(NSArray<__kindof UIViewController *> *)viewControllers {
    if (viewControllers.count == 1) viewControllers = @[viewControllers.firstObject, _placeholderDetailViewController];

    [super setViewControllers:viewControllers];
}

- (void)setReversingPrimaryViewController:(BOOL)reversingPrimaryViewController {
    if (_reversingPrimaryViewController != reversingPrimaryViewController) {
        _reversingPrimaryViewController = reversingPrimaryViewController;

        [self _updateFractionAnimated:NO completion:nil];
    }
}

- (UISplitViewControllerDisplayMode)displayMode {
    return _requiredDisplayMode;
}

- (void)setPreferredDisplayMode:(UISplitViewControllerDisplayMode)preferredDisplayMode {
    [self setPreferredDisplayMode:preferredDisplayMode animated:NO];
}

- (void)setPreferredDisplayMode:(UISplitViewControllerDisplayMode)preferredDisplayMode animated:(BOOL)animated {
    _requiredDisplayMode = preferredDisplayMode;
    super.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;

    BOOL primaryHidden = preferredDisplayMode == UISplitViewControllerDisplayModePrimaryHidden;
    BOOL placeholderDetail = self.placeholderDetailViewController == self.detailViewController;
    [self _respondDelegateForPreferredDisplayMode:preferredDisplayMode];

    void (^completion)(void) = ^{
        [super showDetailViewController:self.placeholderDetailViewController sender:nil];
    };
    if (!primaryHidden || placeholderDetail) completion = nil;
    [self _updateFractionAnimated:animated completion:completion];
}

- (void)setPreferredPrimaryColumnWidthFraction:(CGFloat)preferredPrimaryColumnWidthFraction {
    _requiredPreferredPrimaryColumnWidthFraction = preferredPrimaryColumnWidthFraction;
}

#pragma mark - private

- (CGFloat)primaryColumnWidthFraction {
    UISplitViewControllerDisplayMode mode = _requiredDisplayMode;

    BOOL reverse = _reversingPrimaryViewController;
    BOOL primaryHidden = mode == UISplitViewControllerDisplayModePrimaryHidden;

    CGFloat fraction = _requiredPreferredPrimaryColumnWidthFraction;
    if (primaryHidden) fraction = reverse ? 1 : 0;

    return fraction;
}

- (void)_respondDelegateForPreferredDisplayMode:(UISplitViewControllerDisplayMode)preferredDisplayMode {
    [self.delegate splitViewController:self willChangeToDisplayMode:preferredDisplayMode];
}

- (void)_showViewController:(UIViewController *)masterViewController sender:(id)sender animated:(BOOL)animated {
    [self _showViewController:masterViewController sender:sender animated:animated completion:nil];
}

- (void)_showViewController:(UIViewController *)masterViewController sender:(id)sender animated:(BOOL)animated completion:(void (^)(void))completion {
    _requiredDisplayMode = UISplitViewControllerDisplayModeAllVisible;

    [super showViewController:masterViewController sender:sender];
    [self _updateFractionAnimated:animated completion:completion];
}

- (void)_showDetailViewController:(UIViewController *)detailViewController sender:(id)sender animated:(BOOL)animated {
    [self _showDetailViewController:detailViewController sender:sender animated:animated completion:nil];
}

- (void)_showDetailViewController:(UIViewController *)detailViewController sender:(id)sender animated:(BOOL)animated completion:(void (^)(void))completion {
    _requiredDisplayMode = UISplitViewControllerDisplayModeAllVisible;

    [super showDetailViewController:detailViewController sender:sender];
    [self _updateFractionAnimated:animated completion:completion];
}

- (void)_updateFractionAnimated:(BOOL)animated completion:(void (^)(void))completion {
    CGFloat fraction = self.primaryColumnWidthFraction;
    if (animated) {
        [self.view layoutIfNeeded];
        [UIView animateWithDuration:_animatedDuration animations:^{
            super.preferredPrimaryColumnWidthFraction = fraction;
            [self.view layoutIfNeeded];
        } completion:^(BOOL finished) {
            if (completion) completion();
        }];
    } else {
        super.preferredPrimaryColumnWidthFraction = fraction;
        if (completion) completion();
    }
}

- (void)_finishDraggingWithFraction:(CGFloat)fraction {
    BOOL reverse = _reversingPrimaryViewController;
    CGFloat maximum = MDSplitViewControllerPrimaryHiddenMaximumFraction;
    BOOL hiddenPrimary = (reverse && fraction > maximum) || (!reverse && fraction < (1 - maximum));
    UISplitViewControllerDisplayMode mode = hiddenPrimary ? UISplitViewControllerDisplayModePrimaryHidden : UISplitViewControllerDisplayModeAllVisible;;
    [self setPreferredDisplayMode:mode animated:YES];
}

#pragma mark - public

- (void)showViewController:(UIViewController *)masterViewController sender:(id)sender {
    [self _showViewController:masterViewController sender:sender animated:NO];
}

- (void)showDetailViewController:(UIViewController *)detailViewController sender:(id)sender {
    [self _showDetailViewController:detailViewController sender:sender animated:NO];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (gestureRecognizer != _panGestureRecognizer) return NO;

    BOOL reverse = _reversingPrimaryViewController;
    CGPoint location = [touch locationInView:self.view];

    CGRect masterFrame = self.masterViewController.view.frame;
    if (!reverse && CGRectContainsPoint(masterFrame, location)) return YES;

    CGRect detailFrame = self.detailViewController.view.frame;
    return (reverse && CGRectContainsPoint(detailFrame, location));
}

- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)panGestureRecognizer {
    BOOL reverse = _reversingPrimaryViewController;

    CGPoint velocity = [panGestureRecognizer velocityInView:self.view];
    return (reverse && velocity.x > 0) || (!reverse && velocity.x < 0);
}

#pragma mark - actions

- (IBAction)didPanGestureRecognizer:(UIPanGestureRecognizer *)panGestureRecognizer {
    BOOL reverse = _reversingPrimaryViewController;
    CGFloat requiredFraction = _requiredPreferredPrimaryColumnWidthFraction;

    CGPoint translate = [panGestureRecognizer translationInView:self.view];

    CGFloat fraction = translate.x / CGRectGetWidth(self.view.bounds) + requiredFraction;
    if (reverse) {
        fraction = MAX(fraction, requiredFraction);
        fraction = MIN(fraction, 1);
    } else {
        fraction = MIN(fraction, requiredFraction);
        fraction = MAX(fraction, 0);
    }
    if (fraction != requiredFraction) super.preferredPrimaryColumnWidthFraction = fraction;

    switch (panGestureRecognizer.state) {
        case UIGestureRecognizerStateEnded: [self _finishDraggingWithFraction:fraction]; break;
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed: [self setPreferredDisplayMode:_requiredDisplayMode animated:YES]; break;
        default: break;
    }
}

@end

@implementation UIViewController (MDSplitViewController)
@dynamic splitViewController;

- (void)showViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [self showViewController:viewController animated:animated completion:nil];
}

- (void)showViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(void (^)(void))completion {
    MDSplitViewController *splitViewController = self.splitViewController;
    if ([splitViewController isKindOfClass:[MDSplitViewController class]]) {
        [splitViewController _showViewController:viewController sender:nil animated:animated completion:completion];
    } else {
        [self showViewController:viewController sender:nil];
        if (completion) completion();
    }
}

- (void)showDetailViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [self showDetailViewController:viewController animated:animated completion:nil];
}

- (void)showDetailViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(void (^)(void))completion {
    MDSplitViewController *splitViewController = self.splitViewController;
    if ([splitViewController isKindOfClass:[MDSplitViewController class]]) {
        [splitViewController _showDetailViewController:viewController sender:nil animated:animated completion:completion];
    } else {
        [self showDetailViewController:viewController sender:nil];
        if (completion) completion();
    }
}

@end
