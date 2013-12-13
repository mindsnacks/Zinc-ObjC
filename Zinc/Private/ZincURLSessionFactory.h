//
//  ZincURLSessionFactory.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 12/13/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ZincURLSession.h"

@protocol ZincURLSessionBackgroundTaskDelegate;

@interface ZincURLSessionFactory : NSObject

@property (nonatomic, assign) BOOL wantLegacyImplementation;

#pragma mark - Legacy Requirements

@property (nonatomic, strong) id<ZincURLSessionBackgroundTaskDelegate> backgroundTaskDelegate;
@property (nonatomic, strong) NSOperationQueue* networkOperationQueue;

- (id<ZincURLSession>)getURLSession;

@end
