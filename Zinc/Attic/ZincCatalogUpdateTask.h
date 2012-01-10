//
//  ZincCatalogUpdateTask.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/9/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZincTask.h"

@class ZincSource;

@interface ZincCatalogUpdateTask : ZincTask

- (id) initWithClient:(ZincClient*)client source:(ZincSource*)source;
@property (nonatomic, retain, readonly) ZincSource* source;

@end
