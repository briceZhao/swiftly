//
//  UIView+Badge.m
//  ZXDropMenuView
//
//  Created by brice Mac on 2017/4/9.
//  Copyright © 2017年 briceZhao. All rights reserved.
//

#import "UIView+Badge.h"
#import <objc/runtime.h>

NSString const *UIView_badgeKey = @"UIView_badgeKey";
NSString const *UIView_badgeValueKey = @"UIView_badgeValueKey";
NSString const *UIView_badgeBGColorKey = @"UIView_badgeBGColorKey";
NSString const *UIView_badgeTextColorKey = @"UIView_badgeTextColorKey";
NSString const *UIView_badgeFontKey = @"UIView_badgeFontKey";
NSString const *UIView_badgePaddingKey = @"UIView_badgePaddingKey";
NSString const *UIView_badgeMinSizeKey = @"UIView_badgeMinSizeKey";
NSString const *UIView_badgeOriginXKey = @"UIView_badgeOriginXKey";
NSString const *UIView_badgeOriginYKey = @"UIView_badgeOriginYKey";
NSString const *UIView_shouldHideBadgeAtZeroKey = @"UIView_shouldHideBadgeAtZeroKey";
NSString const *UIView_shouldAnimateBadgeKey = @"UIView_shouldAnimateBadgeKey";

@implementation UIView (Badge)

@dynamic badgeValue, badgeBGColor, badgeTextColor, badgeFont, badgePadding, badgeMinSize, badgeOriginX, badgeOriginY, shouldHideBadgeAtZero, shouldAnimateBadge;


- (void)badgeInit
{
    self.badgeBGColor   = [UIColor redColor];
    self.badgeTextColor = [UIColor whiteColor];
    self.badgeFont      = [UIFont systemFontOfSize:12.0];
    self.badgePadding   = 6;
    self.badgeMinSize   = 8;
    self.badgeOriginX   = self.frame.size.width - self.badge.frame.size.width/2;
    self.badgeOriginY   = -4;
    self.shouldHideBadgeAtZero = YES;
    self.shouldAnimateBadge = YES;
}

// Handle badge display when its properties have been changed (color, font, ...)
- (void)refreshBadge
{
    // Change new attributes
    self.badge.textColor        = self.badgeTextColor;
    self.badge.backgroundColor  = self.badgeBGColor;
    self.badge.font             = self.badgeFont;
}

- (CGSize)badgeExpectedSize
{
    // When the value changes the badge could need to get bigger
    // Calculate expected size to fit new value
    // Use an intermediate label to get expected size thanks to sizeToFit
    // We don't call sizeToFit on the true label to avoid bad display
    UILabel *frameLabel = [self duplicateLabel:self.badge];
    [frameLabel sizeToFit];
    
    CGSize expectedLabelSize = frameLabel.frame.size;
    return expectedLabelSize;
}

- (void)updateBadgeFrame
{
    CGSize expectedLabelSize = [self badgeExpectedSize];
    
    // Make sure that for small value, the badge will be big enough
    CGFloat minHeight = expectedLabelSize.height;
    
    // Using a const we make sure the badge respect the minimum size
    minHeight = (minHeight < self.badgeMinSize) ? self.badgeMinSize : expectedLabelSize.height;
    CGFloat minWidth = expectedLabelSize.width;
    CGFloat padding = self.badgePadding;
    
    // Using const we make sure the badge doesn't get too smal
    minWidth = (minWidth < minHeight) ? minHeight : expectedLabelSize.width;
    self.badge.frame = CGRectMake(self.badgeOriginX, self.badgeOriginY, minWidth + padding, minHeight + padding);
    self.badge.layer.cornerRadius = (minHeight + padding) / 2;
    self.badge.layer.masksToBounds = YES;
}

// Handle the badge changing value
- (void)updateBadgeValueAnimated:(BOOL)animated
{
    // Bounce animation on badge if value changed and if animation authorized
    if (animated && self.shouldAnimateBadge && ![self.badge.text isEqualToString:self.badgeValue]) {
        CABasicAnimation * animation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
        [animation setFromValue:[NSNumber numberWithFloat:1.5]];
        [animation setToValue:[NSNumber numberWithFloat:1]];
        [animation setDuration:0.2];
        [animation setTimingFunction:[CAMediaTimingFunction functionWithControlPoints:1.f :2.f :0.8f :1.f]];
        [self.badge.layer addAnimation:animation forKey:@"bounceAnimation"];
    }
    
    // Set the new value
    self.badge.text = self.badgeValue;
    
    // Animate the size modification if needed
    NSTimeInterval duration = animated ? 0.2 : 0;
    [UIView animateWithDuration:duration animations:^{
        [self updateBadgeFrame];
    }];
}

- (UILabel *)duplicateLabel:(UILabel *)labelToCopy
{
    UILabel *duplicateLabel = [[UILabel alloc] initWithFrame:labelToCopy.frame];
    duplicateLabel.text = labelToCopy.text;
    duplicateLabel.font = labelToCopy.font;
    
    return duplicateLabel;
}

- (void)removeBadge
{
    // Animate badge removal
    [UIView animateWithDuration:0.2 animations:^{
        self.badge.transform = CGAffineTransformMakeScale(0, 0);
    } completion:^(BOOL finished) {
        [self.badge removeFromSuperview];
        self.badge = nil;
    }];
}

#pragma mark - associate object -
- (UILabel*)badge
{
    return objc_getAssociatedObject(self, &UIView_badgeKey);
}
- (void)setBadge:(UILabel *)badgeLabel
{
    objc_setAssociatedObject(self, &UIView_badgeKey, badgeLabel, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

// Badge value to be display
- (NSString *)badgeValue
{
    return objc_getAssociatedObject(self, &UIView_badgeValueKey);
}
- (void)setBadgeValue:(NSString *)badgeValue
{
    objc_setAssociatedObject(self, &UIView_badgeValueKey, badgeValue, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    // When changing the badge value check if we need to remove the badge
    if (!badgeValue || [badgeValue isEqualToString:@""] || ([badgeValue isEqualToString:@"0"] && self.shouldHideBadgeAtZero)) {
        [self removeBadge];
    } else if (!self.badge) {
        // Create a new badge because not existing
        self.badge                      = [[UILabel alloc] initWithFrame:CGRectMake(self.badgeOriginX, self.badgeOriginY, 20, 20)];
        self.badge.textColor            = self.badgeTextColor;
        self.badge.backgroundColor      = self.badgeBGColor;
        self.badge.font                 = self.badgeFont;
        self.badge.textAlignment        = NSTextAlignmentCenter;
        [self badgeInit];
        [self addSubview:self.badge];
        [self updateBadgeValueAnimated:NO];
    } else {
        [self updateBadgeValueAnimated:YES];
    }
}

// Badge background color
- (UIColor *)badgeBGColor
{
    return objc_getAssociatedObject(self, &UIView_badgeBGColorKey);
}

- (void)setBadgeBGColor:(UIColor *)badgeBGColor
{
    objc_setAssociatedObject(self, &UIView_badgeBGColorKey, badgeBGColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (self.badge) {
        [self refreshBadge];
    }
}

// Badge text color
- (UIColor *)badgeTextColor
{
    return objc_getAssociatedObject(self, &UIView_badgeTextColorKey);
}
- (void)setBadgeTextColor:(UIColor *)badgeTextColor
{
    objc_setAssociatedObject(self, &UIView_badgeTextColorKey, badgeTextColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (self.badge) {
        [self refreshBadge];
    }
}

// Badge font
- (UIFont *)badgeFont
{
    return objc_getAssociatedObject(self, &UIView_badgeFontKey);
}
- (void)setBadgeFont:(UIFont *)badgeFont
{
    objc_setAssociatedObject(self, &UIView_badgeFontKey, badgeFont, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (self.badge) {
        [self refreshBadge];
    }
}

// Padding value for the badge
- (CGFloat)badgePadding {
    NSNumber *number = objc_getAssociatedObject(self, &UIView_badgePaddingKey);
    return number.floatValue;
}
- (void)setBadgePadding:(CGFloat)badgePadding
{
    NSNumber *number = [NSNumber numberWithDouble:badgePadding];
    objc_setAssociatedObject(self, &UIView_badgePaddingKey, number, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (self.badge) {
        [self updateBadgeFrame];
    }
}

// Minimum size badge to small
- (CGFloat)badgeMinSize
{
    NSNumber *number = objc_getAssociatedObject(self, &UIView_badgeMinSizeKey);
    return number.floatValue;
}

- (void)setBadgeMinSize:(CGFloat)badgeMinSize
{
    NSNumber *number = [NSNumber numberWithDouble:badgeMinSize];
    objc_setAssociatedObject(self, &UIView_badgeMinSizeKey, number, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (self.badge) {
        [self updateBadgeFrame];
    }
}

// Values for offseting the badge over the BarButtonItem you picked
- (CGFloat)badgeOriginX
{
    NSNumber *number = objc_getAssociatedObject(self, &UIView_badgeOriginXKey);
    return number.floatValue;
}

- (void)setBadgeOriginX:(CGFloat)badgeOriginX
{
    NSNumber *number = [NSNumber numberWithDouble:badgeOriginX];
    objc_setAssociatedObject(self, &UIView_badgeOriginXKey, number, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (self.badge) {
        [self updateBadgeFrame];
    }
}

- (CGFloat)badgeOriginY
{
    NSNumber *number = objc_getAssociatedObject(self, &UIView_badgeOriginYKey);
    return number.floatValue;
}

- (void)setBadgeOriginY:(CGFloat)badgeOriginY
{
    NSNumber *number = [NSNumber numberWithDouble:badgeOriginY];
    objc_setAssociatedObject(self, &UIView_badgeOriginYKey, number, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (self.badge) {
        [self updateBadgeFrame];
    }
}

// In case of numbers, remove the badge when reaching zero
- (BOOL)shouldHideBadgeAtZero
{
    NSNumber *number = objc_getAssociatedObject(self, &UIView_shouldHideBadgeAtZeroKey);
    return number.boolValue;
}

- (void)setShouldHideBadgeAtZero:(BOOL)shouldHideBadgeAtZero
{
    NSNumber *number = [NSNumber numberWithBool:shouldHideBadgeAtZero];
    objc_setAssociatedObject(self, &UIView_shouldHideBadgeAtZeroKey, number, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

// Badge has a bounce animation when value changes
- (BOOL)shouldAnimateBadge
{
    NSNumber *number = objc_getAssociatedObject(self, &UIView_shouldAnimateBadgeKey);
    return number.boolValue;
}

- (void)setShouldAnimateBadge:(BOOL)shouldAnimateBadge
{
    NSNumber *number = [NSNumber numberWithBool:shouldAnimateBadge];
    objc_setAssociatedObject(self, &UIView_shouldAnimateBadgeKey, number, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


@end
