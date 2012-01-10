//
//  ZincCatalogUpdateOperation2.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/10/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincTask2.h"

@class ZincSource;

@interface ZincCatalogUpdateOperation2 : ZincTask2

- (id) initWithClient:(ZincClient *)client source:(ZincSource*)source;
@property (nonatomic, retain, readonly) ZincSource* source;

@end
