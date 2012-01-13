//
//  ZincCatalogUpdateOperation2.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/10/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincTask.h"

@interface ZincSourceUpdateTask : ZincTask

- (id) initWithRepo:(ZincRepo *)repo source:(NSURL*)sourceURL;
@property (nonatomic, retain, readonly) NSURL* sourceURL;

@end
