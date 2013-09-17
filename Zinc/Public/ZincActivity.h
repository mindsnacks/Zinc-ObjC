//
//  ZincActivity.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 9/14/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZincProgress.h"

/**
 `ZincAcitivySubject
 */
@protocol ZincActivitySubject <NSObject>

@required

- (id<ZincProgress>) progress;

- (BOOL) isFinished;

@end