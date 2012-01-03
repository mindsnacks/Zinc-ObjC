//
//  ZCBundleManager.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 12/6/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZincBundle.h"

#define kZCBundleManagerDefaultNetworkOperationCount (5)

@protocol ZincClientDelegate;

@interface ZincClient : NSObject

+ (ZincClient*) defaultClient; // TODO: rename to sharedClient?

+ (ZincClient*) clientWithURL:(NSURL*)fileURL error:(NSError**)outError;

- (id) initWithURL:(NSURL*)fileURL networkOperationQueue:(NSOperationQueue*)operationQueue;
- (id) initWithURL:(NSURL*)fileURL;

@property (nonatomic, assign) id<ZincClientDelegate> delegate;
@property (nonatomic, retain, readonly) NSURL* url;

@property (nonatomic, assign) NSTimeInterval refreshInterval;

#pragma mark Loading

- (void) beginTrackingBundleWithIdentifier:(NSString*)bundleId distribution:(NSString*)dista;

////- (ZCBundle*) bundleWithURL:(NSURL*)url error:(NSError**)outError;
////- (ZCBundle*) bundleWithURL:(NSURL*)url version:(ZincVersion)version error:(NSError**)outError;
////
////- (ZCBundle*) bundleWithPath:(NSString*)path error:(NSError**)outError;;
////- (ZCBundle*) bundleWithPath:(NSString*)path version:(ZincVersion)version error:(NSError**)outError;;

- (ZincBundle*) bundleWithId:(NSString*)bundleId distribution:(NSString*)dist;
//- (ZincBundle*) bundleWithId:(NSString*)bundleId version:(ZincVersion)version;

- (void) refreshBundlesWithCompletion:(dispatch_block_t)completion;

- (NSString*) pathForFileWithSHA:(NSString*)sha;

#pragma mark Sources

- (void) addSourceURL:(NSURL*)url;
//- (void) removeRepoWithIdentifer:(NSString*)identifier;

- (void) refreshSourcesWithCompletion:(dispatch_block_t)completion;

//- (ZCBundle*) bundleWithName:(NSString*)name distribution:(NSString*)distribution;

#pragma mark Bundle Registration

//- (BOOL) registerBundleWithURL:(NSURL*)url error:(NSError**)outError;
//- (BOOL) registerBundleWithPath:(NSString*)path error:(NSError**)outError;
//
//- (void) unregisterBundleWithURL:(NSURL*)url;
//- (void) unregisterBundleWithPath:(NSString*)path;

@end


@protocol ZincClientDelegate <NSObject>

- (void) zincClient:(ZincClient*)zincClient didEncounterError:(NSError*)error;

@end
