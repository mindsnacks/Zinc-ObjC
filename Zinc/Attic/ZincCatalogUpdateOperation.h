//
//  ZincCatalogIndexUpdateTask.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/6/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincTaskOperation.h"

@class ZincTask;
@class ZincSource;

@interface ZincCatalogUpdateOperation : ZincTaskOperation

- (id) initWithTask:(ZincTask *)task source:(ZincSource*)source;
@property (nonatomic, retain, readonly) ZincSource* source;
           
@end
