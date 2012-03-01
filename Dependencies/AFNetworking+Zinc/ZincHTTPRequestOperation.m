// AFHTTPOperation.m
//
// Copyright (c) 2011 Gowalla (http://gowalla.com/)
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "ZincHTTPRequestOperation+Private.h"

static NSUInteger const kZincHTTPMinimumInitialDataCapacity = 1024;
static NSUInteger const kZincHTTPMaximumInitialDataCapacity = 1024 * 1024 * 8;


@implementation ZincHTTPRequestOperation
@synthesize acceptableStatusCodes = _acceptableStatusCodes;
@synthesize acceptableContentTypes = _acceptableContentTypes;
@synthesize responseData = _responseData;
@synthesize totalBytesRead = _totalBytesRead;
@synthesize dataAccumulator = _dataAccumulator;
@synthesize downloadProgress = _downloadProgress;
@synthesize outputStream = _outputStream;

- (id)init
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.acceptableStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 100)];
    
    return self;
}

- (void)dealloc {
    [_acceptableStatusCodes release];
    [_acceptableContentTypes release];
    [_responseData release];
    [_dataAccumulator release];
    [_outputStream release]; _outputStream = nil;
    [_downloadProgress release];
    
    [super dealloc];
}

- (void)setDownloadProgressBlock:(void (^)(NSInteger bytesRead, NSInteger totalBytesRead, NSInteger totalBytesExpectedToRead))block {
    self.downloadProgress = block;
}

- (BOOL)hasContent {
    return [self.responseData length] > 0;
}

- (BOOL)hasAcceptableStatusCode {
    return NO;
}

- (BOOL)hasAcceptableContentType {
    return NO;
}

- (void) createDataAccumulatorForContentLength:(NSUInteger)contentLength
{
    NSUInteger maxCapacity = MAX((NSUInteger)llabs(contentLength), kZincHTTPMinimumInitialDataCapacity);
    NSUInteger capacity = MIN(maxCapacity, kZincHTTPMaximumInitialDataCapacity);
    self.dataAccumulator = [NSMutableData dataWithCapacity:capacity];
}

- (void)setCompletionBlockWithSuccess:(void (^)(ZincHTTPRequestOperation *operation, id responseObject))success
                              failure:(void (^)(ZincHTTPRequestOperation *operation, NSError *error))failure
{
    self.completionBlock = ^ {
        if ([self isCancelled]) {
            return;
        }
        
        if (self.error) {
            if (failure) {
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    failure(self, self.error);
                });
            }
        } else {
            if (success) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    success(self, self.responseData);
                });
            }
        }
    };
}

- (void) finish
{
    if (self.outputStream) {
        [self.outputStream close];
    } else {
        self.responseData = [NSData dataWithData:self.dataAccumulator];
        self.dataAccumulator = nil;
    }
    
    [super finish];
}

@end
