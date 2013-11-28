//
//  DownloadsCell.m
//  MindSnacks
//
//  Created by Andy Mroczkowski on 6/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ZincActivityCell.h"

#define kMargin 8.0f
#define kMainLabelFontSize 16.0f
#define kDetailLabelFontSize 14.0f
#define kCellHeight 70.0f
#define kPadding 2.0f


@interface ZincActivityCell ()

@property (nonatomic, strong, readwrite) UILabel *mainLabel;
@property (nonatomic, strong, readwrite) UILabel *detailLabel;
@property (nonatomic, strong, readwrite) UIProgressView *progressView;

@end

@implementation ZincActivityCell

+ (CGFloat)cellHeight
{
    return kCellHeight;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _mainLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _mainLabel.font = [UIFont systemFontOfSize:kMainLabelFontSize];
        _mainLabel.adjustsFontSizeToFitWidth = YES;
        _mainLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        _mainLabel.numberOfLines = 1;
        [[self contentView] addSubview:_mainLabel];

        _detailLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _detailLabel.font = [UIFont systemFontOfSize:kDetailLabelFontSize];
        _detailLabel.adjustsFontSizeToFitWidth = YES;
        _detailLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        _detailLabel.numberOfLines = 1;
        _detailLabel.textColor = [UIColor darkGrayColor];
        [[self contentView] addSubview:_detailLabel];

        _progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        [[self contentView] addSubview:_progressView];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGRect mainLabelFrame = CGRectMake(kMargin, kMargin,
                                       self.contentView.frame.size.width - (kMargin * 2),
                                       kMainLabelFontSize + kPadding);
    self.mainLabel.frame = mainLabelFrame;

    CGRect detailLabelFrame = CGRectMake(kMargin,
                                         self.mainLabel.frame.origin.y + self.mainLabel.frame.size.height + kPadding,
                                         self.contentView.frame.size.width - (kMargin * 2),
                                         kDetailLabelFontSize + kPadding);
    self.detailLabel.frame = detailLabelFrame;

    CGRect progressViewFrame = self.progressView.frame;
    progressViewFrame.origin.x = self.mainLabel.frame.origin.x;
    progressViewFrame.origin.y = CGRectGetMaxY(self.detailLabel.frame) + kPadding;
    progressViewFrame.size.width = self.contentView.frame.size.width - (kMargin * 2);
    self.progressView.frame = progressViewFrame;
}

@end
