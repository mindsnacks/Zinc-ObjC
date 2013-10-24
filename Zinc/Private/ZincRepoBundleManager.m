//
//  ZincRepoBundleManager.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 5/14/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import "ZincRepoBundleManager.h"

#import "ZincInternals.h"
#import "ZincRepo+Private.h"
#import "ZincBundle+Private.h"

@interface ZincRepoBundleManager ()
@property (nonatomic, retain) NSMutableDictionary* loadedBundles;
@end

@implementation ZincRepoBundleManager

- (id) initWithZincRepo:(ZincRepo*)zincRepo
{
    self = [super init];
    if (self) {
        self.repo = zincRepo;
        self.loadedBundles = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (ZincBundle*) bundleWithID:(NSString*)bundleID version:(ZincVersion)version
{
    ZincBundle* bundle = nil;
    NSURL* res = [NSURL zincResourceForBundleWithID:bundleID version:version];
    NSString* path = [self.repo pathForBundleWithID:bundleID version:version];

    // Special case to handle a missing bundle dir
    if (![self.repo.fileManager fileExistsAtPath:path]) {

        dispatch_group_t group = dispatch_group_create();
        dispatch_group_enter(group);
        [self.repo deregisterBundle:res completion:^{
            dispatch_group_leave(group);
        }];
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);

        return nil;
    }

    @synchronized(self.loadedBundles) {
        bundle = [(self.loadedBundles)[res] pointerValue];

        if (bundle == nil) {
            bundle = [[ZincBundle alloc] initWithRepoBundleManager:self bundleID:bundleID version:version bundleURL:[NSURL fileURLWithPath:path]];
            if (bundle == nil) return nil;

            (self.loadedBundles)[res] = [NSValue valueWithPointer:(__bridge const void *)(bundle)];
        }
    }
    return bundle;
}

- (NSSet*) activeBundles
{
    NSMutableSet* activeBundles = [NSMutableSet set];

   @synchronized(self.loadedBundles) {
       for (NSURL* bundleRes in [self.loadedBundles allKeys]) {
           // make sure to request the object, and check if the ref is now nil
           ZincBundle* bundle = [(self.loadedBundles)[bundleRes] pointerValue];
           if (bundle != nil) {
               [activeBundles addObject:bundleRes];
           }
       }
   }
    
    return activeBundles;
}

- (void) bundleWillDeallocate:(ZincBundle*)bundle
{
    @synchronized(self.loadedBundles) {
        [self.loadedBundles removeObjectForKey:[bundle resource]];
    }
}

@end
