//
//  ZincUtils.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 1/15/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincUtils.h"
#import <sys/xattr.h> // for AddSkipBackupAttributeToFile

ZincBundleState ZincBundleStateFromName(NSString* name)
{
    if ([name isEqualToString:ZincBundleStateName[ZincBundleStateNone]]) {
        return ZincBundleStateNone;
    } else if ([name isEqualToString:ZincBundleStateName[ZincBundleStateAvailable]]) {
        return ZincBundleStateAvailable;
    } else if ([name isEqualToString:ZincBundleStateName[ZincBundleStateCloning]]) {
        return ZincBundleStateCloning;
    } else if ([name isEqualToString:ZincBundleStateName[ZincBundleStateDeleting]]) {
        return ZincBundleStateDeleting;
    }

    NSCAssert(NO, @"unknown bundle state name: %@", name);
    return -1;
}

int ZincAddSkipBackupAttributeToFileWithPath(NSString * path)
{
    u_int8_t b = 1;
    int result = setxattr([path fileSystemRepresentation], "com.apple.MobileBackup", &b, 1, 0, 0);
    return result;
}

int ZincAddSkipBackupAttributeToFileWithURL(NSURL * url)
{
    return ZincAddSkipBackupAttributeToFileWithPath([url path]);
}

NSString* ZincGetApplicationDocumentsDirectory(void)
{
    static NSString* dir = nil;
    if (dir == nil) {
        dir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
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
        dir = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
        if([dir length] == 0) {
            [NSException raise:@"Caches dir not found"
                        format:@"NSSearchPathForDirectoriesInDomains returned an empty dir"];
        }
    }
    return dir;
}

NSString* ZincCatalogIDFromBundleID(NSString* bundleID)
{
    NSArray* comps = [bundleID componentsSeparatedByString:@"."];
    NSString* sourceId = [[comps subarrayWithRange:NSMakeRange(0, [comps count]-1)] componentsJoinedByString:@"."];
    return sourceId;
}

NSString* ZincGetUniqueTemporaryDirectory(void)
{
    NSString* tmpFormat = [NSTemporaryDirectory() stringByAppendingPathComponent:@"zinc.XXXXXXXX"];
    char* tmpDirCstring = mkdtemp((char*)[tmpFormat cStringUsingEncoding:NSUTF8StringEncoding]);
    NSString* tmpDir = @(tmpDirCstring);
    return tmpDir;
}

NSString* ZincBundleNameFromBundleID(NSString* bundleID)
{
    return [[bundleID componentsSeparatedByString:@"."] lastObject];
}

NSString* ZincBundleIDFromCatalogIDAndBundleName(NSString* catalogID, NSString* bundleName)
{
    return [NSString stringWithFormat:@"%@.%@", catalogID, bundleName];
}

NSString* ZincBundleIDFromBundleDescriptor(NSString* bundleDescriptor)
{
    NSRange separatorRange = [bundleDescriptor rangeOfString:@"-" options:NSBackwardsSearch];
    NSString* bundleID = [bundleDescriptor substringToIndex:separatorRange.location];
    return bundleID;
}

ZincVersion ZincBundleVersionFromBundleDescriptor(NSString* bundleDescriptor)
{
    NSRange separatorRange = [bundleDescriptor rangeOfString:@"-" options:NSBackwardsSearch];
    ZincVersion version = [[bundleDescriptor substringFromIndex:NSMaxRange(separatorRange)] integerValue];
    return version;

}
