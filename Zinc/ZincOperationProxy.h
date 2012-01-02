//
//  ZincOperationProxy.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/2/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZincOperationProxy : NSProxy


+ (ZincOperationProxy*) proxyForOperation:(NSOperation*)operation;
@property (nonatomic, retain, readonly) NSOperation* operation;

@property (nonatomic, assign) id owner;

- (NSDictionary*) attributes;
- (void) addAttribute:(id)attribute forKey:(NSString*)key;

@end
