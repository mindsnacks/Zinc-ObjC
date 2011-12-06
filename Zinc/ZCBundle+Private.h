//
//  ZCBundle+Private.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 12/5/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import "ZCBundle.h"
#import "ZCFileSystem.h"

@interface ZCBundle ()

- (id) initWithFileSystem:(ZCFileSystem*)fileSystem;

@property (nonatomic, retain) ZCFileSystem* fileSystem;

@end