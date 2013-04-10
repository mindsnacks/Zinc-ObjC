//
//  ZCRepo.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 12/16/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import "ZincSource.h"
#import "ZincCatalog.h"

@implementation NSURL (ZincSource)

- (NSURL*) urlForCatalogIndex
{
    return [[NSURL URLWithString:@"catalog.json.gz" relativeToURL:self] absoluteURL];
}

- (NSMutableURLRequest*) getRequestForURL:(NSURL*)url
{
    NSMutableURLRequest* req = [[[NSMutableURLRequest alloc] initWithURL:url] autorelease];
    [req setHTTPMethod:@"GET"];
    
//    [req setCachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData];

    // advises that caching-proxies don't attempt to further compress any data
    // http://stackoverflow.com/questions/10500113/ios-afnetworking-over-3g-is-not-reliable-when-fetching-files-from-rackspace
    [req addValue:@"no-transform" forHTTPHeaderField:@"Cache-Control"];
    
    return req;
}

- (NSURLRequest*) urlRequestForCatalogIndex
{
    NSURL* indexURL = [self urlForCatalogIndex];
    NSMutableURLRequest* request = [self getRequestForURL:indexURL];
    return request;
}

- (NSURL*) urlForBundleName:(NSString*)name version:(NSInteger)version
{
    NSString* manifest = [NSString stringWithFormat:@"%@-%d.json.gz", name, version];
    NSString* manifestPath = [NSString stringWithFormat:@"manifests/%@", manifest];
    NSURL* manifestURL = [NSURL URLWithString:manifestPath relativeToURL:self];
    return [manifestURL absoluteURL];
}

- (NSURLRequest*) zincManifestURLRequestForBundleName:(NSString*)name version:(NSInteger)version
{
    NSURL* manifestURL = [self urlForBundleName:name version:version];
    return [self getRequestForURL:manifestURL];
}

- (NSURL*) urlForBundleName:(NSString*)name distribution:(NSString*)distro catalog:(ZincCatalog*)catalog
{
    NSInteger version = [catalog versionForBundleId:name distribution:distro];
    if (version == ZincVersionInvalid) {
        return nil;
    }
    return [self urlForBundleName:name version:version];
}

- (NSURLRequest*) urlRequestForBundleName:(NSString*)name distribution:(NSString*)distro catalog:(ZincCatalog*)catalog
{
    NSURL* manifestURL = [self urlForBundleName:name distribution:distro catalog:catalog];
    return [self getRequestForURL:manifestURL];
}

- (NSURL*) urlForFileWithSHA:(NSString*)sha extension:(NSString*)extension
{
    NSString* relativeDir = [NSString stringWithFormat:@"objects/%@/%@/",
                              [sha substringWithRange:NSMakeRange(0, 2)],
                             [sha substringWithRange:NSMakeRange(2, 2)]];
    NSString* file = sha;
    if (extension != nil) {
        file = [file stringByAppendingPathExtension:extension];
    }
    NSString* relativePath = [relativeDir stringByAppendingPathComponent:file];
    
    return [[NSURL URLWithString:relativePath relativeToURL:self] absoluteURL];
}

- (NSURL*) urlForFileWithSHA:(NSString*)sha
{
    return [self urlForFileWithSHA:sha extension:nil];
}

- (NSURLRequest*) urlRequestForFileWithSHA:(NSString*)sha extension:(NSString*)extension
{
    NSURL* fileURL = [self urlForFileWithSHA:sha extension:extension];
    NSMutableURLRequest* request = [self getRequestForURL:fileURL];
    return request;
}

- (NSURLRequest*) urlRequestForFileWithSHA:(NSString*)sha
{
    NSURL* fileURL = [self urlForFileWithSHA:sha extension:nil];
    return [self getRequestForURL:fileURL];
}

- (NSURL*) urlForArchivedBundleName:(NSString*)name version:(NSInteger)version flavor:(NSString*)flavor
{
    NSString* filename = nil;
    if( flavor == nil) {
        filename = [NSString stringWithFormat:@"%@-%d.tar", name, version];
    } else {
        filename = [NSString stringWithFormat:@"%@-%d~%@.tar", name, version, flavor];
    }
    NSString* relativePath = [@"archives" stringByAppendingPathComponent:filename];
    
    return [[NSURL URLWithString:relativePath relativeToURL:self] absoluteURL];
}

- (NSURLRequest*) urlRequestForArchivedBundleName:(NSString*)name version:(NSInteger)version
{
    NSURL* archiveURL = [self urlForArchivedBundleName:name version:version flavor:nil];
    return [self getRequestForURL:archiveURL];
}

- (NSURLRequest*) urlRequestForArchivedBundleName:(NSString*)name version:(NSInteger)version flavor:(NSString*)flavor
{
    NSURL* archiveURL = [self urlForArchivedBundleName:name version:version flavor:flavor];
    return [self getRequestForURL:archiveURL];
}



@end
