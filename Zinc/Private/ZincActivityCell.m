//
//  DownloadsCell.m
//  MindSnacks
//
//  Created by Andy Mroczkowski on 6/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ZincActivityCell.h"

#define kTextLabelSideMargin 20.0f
#define kTextLabelFontSize 17.0f
#define kCellMinHeight 55.0f
#define kTextLabelAndCellOffset 34.0f

static UIFont *_textFont = nil;
static CGFloat _textLabelWidth = 0.0f;

@interface ZincActivityCell ()

@property (nonatomic, retain, readwrite) IBOutlet UILabel *mainLabel;
@property (nonatomic, retain, readwrite) IBOutlet UIProgressView *progressView;

@end

@implementation ZincActivityCell

+ (void)initialize
{
    if (([self class] == [ZincActivityCell class]))
    {
        _textFont = [UIFont systemFontOfSize:kTextLabelFontSize];
        _textLabelWidth = [UIScreen mainScreen].applicationFrame.size.width - (kTextLabelSideMargin * 2);
    }
}

+ (CGFloat)cellHeightForText:(NSString *)text
{
    CGFloat textHeight = [text sizeWithFont:_textFont
                          constrainedToSize:CGSizeMake(_textLabelWidth, HUGE_VALF)
                              lineBreakMode:NSLineBreakByWordWrapping].height;

    return MAX(textHeight + kTextLabelAndCellOffset, kCellMinHeight);
}

@end
