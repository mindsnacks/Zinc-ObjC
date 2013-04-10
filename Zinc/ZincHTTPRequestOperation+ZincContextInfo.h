//
//  ZincHTTPRequestOperation+ZincErrorContext.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 3/18/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>

@interface AFHTTPRequestOperation (ZincContextInfo)

- (NSDictionary*) zinc_contextInfo;

@end
