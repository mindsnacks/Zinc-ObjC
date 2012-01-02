//
//  ZCRepo.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 12/16/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import "ZincSource.h"
#import "ZincCatalog.h"

@interface ZincSource ()
@property (nonatomic, retain, readwrite) NSURL* url;
@end

@implementation ZincSource

@synthesize url = _url;

+ (ZincSource*) sourceWithURL:(NSURL*)url
{
    // TODO: validate URL
    ZincSource* remote = [[[ZincSource alloc] init] autorelease];
    remote.url = url;
    return remote;
}

- (void)dealloc
{
    self.url = nil;
    [super dealloc];
}

- (NSURL*) urlForCatalogIndex
{
    return [[NSURL URLWithString:@"index.json" relativeToURL:self.url] absoluteURL];
}

- (NSURLRequest*) getRequestForURL:(NSURL*)url
{
    NSMutableURLRequest* req = [[[NSMutableURLRequest alloc] initWithURL:url] autorelease];
    [req setHTTPMethod:@"GET"];
    return req;
}

- (NSURLRequest*) urlRequestForCatalogIndex
{
    NSURL* indexURL = [self urlForCatalogIndex];
    return [self getRequestForURL:indexURL];
}

- (NSURL*) urlForBundleName:(NSString*)name version:(NSInteger)version
{
    NSString* manifest = [NSString stringWithFormat:@"%@-%d.json", name, version];
    NSString* manifestPath = [NSString stringWithFormat:@"manifests/%@", manifest];
    NSURL* manifestURL = [NSURL URLWithString:manifestPath relativeToURL:self.url];
    return [manifestURL absoluteURL];
}

- (NSURLRequest*) urlRequestForBundleName:(NSString*)name version:(NSInteger)version
{
    NSURL* manifestURL = [self urlForBundleName:name version:version];
    return [self getRequestForURL:manifestURL];
}

- (NSURL*) urlForBundleName:(NSString*)name label:(NSString*)label catalog:(ZincCatalog*)catalog
{
    NSInteger version = [catalog versionForBundleName:name label:label];
    if (version == ZincVersionInvalid) {
        return nil;
    }
    return [self urlForBundleName:name version:version];
}

- (NSURLRequest*) urlRequestForBundleName:(NSString*)name label:(NSString*)label catalog:(ZincCatalog*)catalog
{
    NSURL* manifestURL = [self urlForBundleName:name label:label catalog:catalog];
    return [self getRequestForURL:manifestURL];
}

- (NSURL*) urlForFileWithSHA:(NSString*)sha
{
    NSString* relativePath = [NSString stringWithFormat:@"files/%@/%@/%@",
                              [sha substringWithRange:NSMakeRange(0, 2)],
                              [sha substringWithRange:NSMakeRange(2, 2)],
                              sha];
    return [[NSURL URLWithString:relativePath relativeToURL:self.url] absoluteURL];
}

- (NSURLRequest*) urlRequestForFileWithSHA:(NSString*)sha
{
    NSURL* fileURL = [self urlForFileWithSHA:sha];
    return [self getRequestForURL:fileURL];
}

@end
