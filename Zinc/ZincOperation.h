//
//  ZincOperation.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 7/27/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZincOperation : NSOperation

- (NSInteger) currentProgressValue;
- (NSInteger) maxProgressValue;

- (double) progress;

@end
