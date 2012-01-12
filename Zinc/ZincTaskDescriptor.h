//
//  ZincTaskDescriptor.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/11/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>

//extern NSString* const kZincTaskMethodWrite;
//extern NSString* const kZincTaskMethodDelete;

@protocol ZincResourceDescriptor;

@interface ZincTaskDescriptor : NSObject <NSCopying>

@property (nonatomic, retain) id<ZincResourceDescriptor> resource;
@property (nonatomic, retain) NSString* method;

@end
