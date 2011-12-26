//
//  ZCBundleManager.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 12/6/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZCBundle.h"

#define kZCBundleManagerDefaultNetworkOperationCount (5)

@protocol ZCBundleManagerDelegate;

@interface ZCBundleManager : NSObject

+ (ZCBundleManager*) defaultManager;
- (id) initWithNetworkOperationQueue:(NSOperationQueue*)operationQueue;
- (id) init;

@property (nonatomic, assign) id<ZCBundleManagerDelegate> delegate;

#pragma mark Loading

- (ZCBundle*) bundleWithURL:(NSURL*)url error:(NSError**)outError;
- (ZCBundle*) bundleWithURL:(NSURL*)url version:(ZincVersion)version error:(NSError**)outError;

- (ZCBundle*) bundleWithPath:(NSString*)path error:(NSError**)outError;;
- (ZCBundle*) bundleWithPath:(NSString*)path version:(ZincVersion)version error:(NSError**)outError;;

#pragma mark Repo Registration

- (void) addRepoWithURL:(NSURL*)url;
// TODO: removeRemoteRepoWithURL

- (void) refreshReposWithCompletion:(ZCBasicBlock)completion;

- (ZCBundle*) bundleWithName:(NSString*)name distribution:(NSString*)distribution;

#pragma mark Bundle Registration

- (BOOL) registerBundleWithURL:(NSURL*)url error:(NSError**)outError;
- (BOOL) registerBundleWithPath:(NSString*)path error:(NSError**)outError;

- (void) unregisterBundleWithURL:(NSURL*)url;
- (void) unregisterBundleWithPath:(NSString*)path;

@end


@protocol ZCBundleManagerDelegate <NSObject>

- (void) bundleManager:(ZCBundleManager*)bundleManager didEncounterError:(NSError*)error;

@end
