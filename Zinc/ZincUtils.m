//
//  ZincUtils.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 1/15/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincUtils.h"
#import <sys/xattr.h> // for AddSkipBackupAttributeToFile

void ZincAddSkipBackupAttributeToFile(NSURL * url)
{
    u_int8_t b = 1;
    setxattr([[url path] fileSystemRepresentation], "com.apple.MobileBackup", &b, 1, 0, 0);
}

NSString* ZincGetApplicationDocumentsDirectory(void)
{
    static NSString* dir = nil;
    if (dir == nil) {
        dir = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] retain];
        if([dir length] == 0) {
            [NSException raise:@"Documents dir not found"
                        format:@"NSSearchPathForDirectoriesInDomains returned an empty dir"];
        }
    }
    return dir;
}

NSString* ZincGetApplicationCacheDirectory(void)
{
    static NSString* dir = nil;
    if (dir == nil) {
        dir = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] retain];
        if([dir length] == 0) {
            [NSException raise:@"Caches dir not found"
                        format:@"NSSearchPathForDirectoriesInDomains returned an empty dir"];
        }
    }
    return dir;
}

NSString* ZincCatalogIdFromBundleId(NSString* bundleId)
{
    NSArray* comps = [bundleId componentsSeparatedByString:@"."];
    NSString* sourceId = [[comps subarrayWithRange:NSMakeRange(0, [comps count]-1)] componentsJoinedByString:@"."];
    return sourceId;
}

NSString* ZincBundleNameFromBundleId(NSString* bundleId)
{
    return [[bundleId componentsSeparatedByString:@"."] lastObject];
}