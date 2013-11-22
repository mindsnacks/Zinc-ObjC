//
//  DownloadsCell.h
//  MindSnacks
//
//  Created by Andy Mroczkowski on 6/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ZincActivityCell : UITableViewCell

@property (nonatomic, retain, readonly) UILabel *mainLabel;
@property (nonatomic, retain, readonly) UIProgressView *progressView;

+ (CGFloat)cellHeightForText:(NSString *)text fitInWidth:(CGFloat)width;

@end
