//
//  DownloadsCell.h
//  MindSnacks
//
//  Created by Andy Mroczkowski on 6/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ZincActivityCell : UITableViewCell

@property (nonatomic, strong, readonly) UILabel *mainLabel;
@property (nonatomic, strong, readonly) UILabel *detailLabel;
@property (nonatomic, strong, readonly) UIProgressView *progressView;

+ (CGFloat)cellHeight;

@end
