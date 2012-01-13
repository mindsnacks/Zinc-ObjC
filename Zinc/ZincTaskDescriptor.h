//
//  ZincTaskDescriptor.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/11/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ZincResourceDescriptor;

@interface ZincTaskDescriptor : NSObject <NSCopying>

/* method should always be the classname. Do not override. Did not call it
 * "className" directly because that method is already defined on NSObject on
 * OS X.
 */

+ (id) taskDescriptorWithResource:(NSURL*)resource method:(NSString*)method;
- (id) initWithResource:(NSURL*)resource method:(NSString*)method;

@property (nonatomic, retain, readonly) NSURL* resource;
@property (nonatomic, retain, readonly) NSString* method;

- (NSString*) stringValue;

@end
