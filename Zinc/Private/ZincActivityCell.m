//
//  DownloadsCell.m
//  MindSnacks
//
//  Created by Andy Mroczkowski on 6/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ZincActivityCell.h"

#define kMargin 12.0f
#define kTextLabelSideMargin 20.0f
#define kTextLabelFontSize 17.0f
#define kCellMinHeight 55.0f
#define kTextLabelAndCellOffset 34.0f

static UIFont *_textFont = nil;
//static CGFloat _textLabelWidth = 0.0f;

@interface ZincActivityCell ()

@property (nonatomic, retain, readwrite) UILabel *mainLabel;
@property (nonatomic, retain, readwrite) UIProgressView *progressView;

@end

@implementation ZincActivityCell

+ (void)initialize
{
    if (([self class] == [ZincActivityCell class]))
    {
        _textFont = [UIFont systemFontOfSize:kTextLabelFontSize];
//        _textLabelWidth = [UIScreen mainScreen].applicationFrame.size.width - (kTextLabelSideMargin * 2);
    }
}

+ (CGFloat)cellHeightForText:(NSString *)text fitInWidth:(CGFloat)width
{
    CGFloat textHeight = [text sizeWithFont:_textFont
                          constrainedToSize:CGSizeMake(width, HUGE_VALF)
                              lineBreakMode:NSLineBreakByWordWrapping].height;

    return MAX(textHeight + kTextLabelAndCellOffset, kCellMinHeight);
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _mainLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        [[self contentView] addSubview:_mainLabel];
        
        _progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    }
    return self;
}

- (void)layoutSubviews
{
//    self.contentView.backgroundColor = [UIColor redColor];


    CGRect textLabelFrame = CGRectMake(kMargin, kMargin,
                                       self.frame.size.width - (kMargin * 2),
                                       30);
    self.mainLabel.frame = textLabelFrame;
}

@end
