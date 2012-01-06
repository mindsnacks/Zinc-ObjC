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

#pragma mark Sources

- (void) addSourceURL:(NSURL*)url;

- (void) refreshSourcesWithCompletion:(dispatch_block_t)completion;

#pragma mark Bundles

- (void) beginTrackingBundleWithIdentifier:(NSString*)bundleId distribution:(NSString*)dista;

//- (ZincBundle*) bundleWithId:(NSString*)bundleId distribution:(NSString*)dist;
- (NSBundle*) bundleWithId:(NSString*)bundleId distribution:(NSString*)dist;

- (void) refreshBundlesWithCompletion:(dispatch_block_t)completion;

#pragma mark Files

- (NSString*) pathForFileWithSHA:(NSString*)sha;

@end


@protocol ZincClientDelegate <NSObject>

- (void) zincClient:(ZincClient*)zincClient didEncounterError:(NSError*)error;

@end
