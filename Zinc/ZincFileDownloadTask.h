//
//  ZincFileUpdateTask2.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/10/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincTask.h"

@class ZincSource;

@interface ZincFileDownloadTask : ZincTask

- (id)initWithRepo:(ZincRepo*)repo source:(ZincSource*)souce sha:(NSString*)sha;
@property (nonatomic, retain) ZincSource* source;
@property (nonatomic, retain) NSString* sha;

@end
