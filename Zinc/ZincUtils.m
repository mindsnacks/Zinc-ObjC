//
//  ZincUtils.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 1/15/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincUtils.h"
#import <sys/xattr.h> // for AddSkipBackupAttributeToFile

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

NSString* ZincGetUniqueTemporaryDirectory(void)
{
    NSString* tmpFormat = [NSTemporaryDirectory() stringByAppendingPathComponent:@"zinc.XXXXXXXX"];
    char* tmpDirCstring = mkdtemp((char*)[tmpFormat cStringUsingEncoding:NSUTF8StringEncoding]);
    NSString* tmpDir = [NSString stringWithCString:tmpDirCstring encoding:NSUTF8StringEncoding];
    return tmpDir;
}

NSString* ZincBundleNameFromBundleId(NSString* bundleId)
{
    return [[bundleId componentsSeparatedByString:@"."] lastObject];
}

NSString* ZincBundleIdFromCatalogIdAndBundleName(NSString* catalogId, NSString* bundleName)
{
    return [NSString stringWithFormat:@"%@.%@", catalogId, bundleName];
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
