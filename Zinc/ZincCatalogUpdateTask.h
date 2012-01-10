//
//  ZincCatalogUpdateOperation2.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/10/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincTask.h"

@class ZincSource;

@interface ZincCatalogUpdateTask : ZincTask

- (id) initWithRepo:(ZincRepo *)repo source:(ZincSource*)source;
@property (nonatomic, retain, readonly) ZincSource* source;

@end
