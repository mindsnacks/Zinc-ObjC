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

@property (weak, readonly) ZincCatalog* catalog;

@end
