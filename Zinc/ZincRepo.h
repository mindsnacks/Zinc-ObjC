//
//  ZCBundleManager.h
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 12/6/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZincBundle.h"

#define kZincRepoDefaultNetworkOperationCount (5)

@protocol ZincRepoDelegate;

@interface ZincRepo : NSObject

+ (ZincRepo*) repoWithURL:(NSURL*)fileURL error:(NSError**)outError;

- (id) initWithURL:(NSURL*)fileURL networkOperationQueue:(NSOperationQueue*)operationQueue;
- (id) initWithURL:(NSURL*)fileURL;

@property (nonatomic, assign) id<ZincRepoDelegate> delegate;
@property (nonatomic, retain, readonly) NSURL* url;

@property (nonatomic, assign) NSTimeInterval refreshInterval;

#pragma mark Sources

- (void) addSourceURL:(NSURL*)url;

- (void) refreshSourcesWithCompletion:(dispatch_block_t)completion;

#pragma mark Bundles

- (void) beginTrackingBundleWithIdentifier:(NSString*)bundleId distribution:(NSString*)dista;

- (NSBundle*) bundleWithId:(NSString*)bundleId distribution:(NSString*)dist;

- (void) refreshBundlesWithCompletion:(dispatch_block_t)completion;

#pragma mark Files

- (NSString*) pathForFileWithSHA:(NSString*)sha;

#pragma mark Tasks

@property (readonly) NSArray* tasks;
           
@end


@protocol ZincRepoDelegate <NSObject>

- (void) zincRepo:(ZincRepo*)repo didEncounterError:(NSError*)error;

@end
