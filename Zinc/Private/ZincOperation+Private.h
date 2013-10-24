//
//  ZincOperation+Private.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 9/14/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "ZincOperation.h"
#import "ZincProgress.h"

@interface ZincOperation () <ZincProgress>

- (void) addChildOperation:(NSOperation*)childOp;

@end