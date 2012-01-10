//
//  ZincOperationChain.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/9/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Zinc.h"

@interface ZincOperationChain : NSObject

- (void) addOperation:(NSOperation*)operation title:(NSString*)title passFailBlock:(ZincPassFailBlock)block;
- (NSArray*) operations;

@end
