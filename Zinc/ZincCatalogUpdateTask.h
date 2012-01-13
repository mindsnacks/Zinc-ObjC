//
//  ZincCatalogUpdateTask.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/11/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincTask.h"

@class ZincCatalog;

@interface ZincCatalogUpdateTask : ZincTask

@property (readonly) ZincCatalog* catalog;

@end
