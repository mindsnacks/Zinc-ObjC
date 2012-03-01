// AFURLConnectionOperation.m
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

#import "ZincHTTPURLConnectionOperation.h"
#import "ZincHTTPRequestOperation+Private.h"

@interface ZincHTTPURLConnectionOperation ()
@property (readwrite, nonatomic, retain) NSURLConnection *connection;
@property (readwrite, nonatomic, retain) NSURLRequest *request;
@property (readwrite, nonatomic, retain) NSURLResponse *response;
@property (readwrite, nonatomic, retain) NSError *HTTPError;
@end

@implementation ZincHTTPURLConnectionOperation
@dynamic HTTPResponse;
@synthesize connection = _connection;
@synthesize request = _request;
@synthesize response = _response;
@synthesize HTTPError = _HTTPError;


- (id)initWithRequest:(NSURLRequest *)urlRequest {
    self = [super init];
    if (!self) {
		return nil;
    }
    
    self.request = urlRequest;
    
    return self;
}

- (void)dealloc {
    
    [_request release];
    [_response release];
    [_HTTPError release];
    
    [_connection release]; _connection = nil;
	
    [super dealloc];
}

- (NSHTTPURLResponse *)HTTPResponse {
    return (NSHTTPURLResponse *)[self response];
}

#pragma mark - NSOperation

- (void) main
{
    if ([self isCancelled]) {
        [self finish];
        return;
    }
    
    self.connection = [[[NSURLConnection alloc] initWithRequest:self.request delegate:self startImmediately:NO] autorelease];
    
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    for (NSString *runLoopMode in self.runLoopModes) {
        [self.connection scheduleInRunLoop:runLoop forMode:runLoopMode];
        [self.outputStream scheduleInRunLoop:runLoop forMode:runLoopMode];
    }
    
    [self.connection start];
}

- (void)cancel
{
    [super cancel];
    [self.connection cancel];
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)__unused connection 
   didSendBodyData:(NSInteger)bytesWritten 
 totalBytesWritten:(NSInteger)totalBytesWritten 
totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
}

- (void)connection:(NSURLConnection *)__unused connection 
didReceiveResponse:(NSURLResponse *)response 
{
    self.response = (NSHTTPURLResponse *)response;
    
    if (self.outputStream) {
        [self.outputStream open];
    } else {
        [self createDataAccumulatorForContentLength:response.expectedContentLength];
    }
}

- (void)connection:(NSURLConnection *)__unused connection 
    didReceiveData:(NSData *)data 
{
    self.totalBytesRead += [data length];
    
    if (self.outputStream) {
        if ([self.outputStream hasSpaceAvailable]) {
            const uint8_t *dataBuffer = [data bytes];
            [self.outputStream write:&dataBuffer[0] maxLength:[data length]];
        }
    } else {
        [self.dataAccumulator appendData:data];
    }
    
    if (self.downloadProgress) {
        self.downloadProgress([data length], self.totalBytesRead, (NSInteger)self.response.expectedContentLength);
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)__unused connection {        

    
    [self finish];
}

- (void)connection:(NSURLConnection *)__unused connection 
  didFailWithError:(NSError *)error 
{      
    self.error = error;
    
    if (self.outputStream) {
        [self.outputStream close];
    } else {
        self.dataAccumulator = nil;
    }
    
    [self finish];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)__unused connection 
                  willCacheResponse:(NSCachedURLResponse *)cachedResponse 
{
    if ([self isCancelled]) {
        return nil;
    }
    
    return cachedResponse;
}

- (BOOL)hasAcceptableStatusCode {
    return !self.acceptableStatusCodes || [self.acceptableStatusCodes containsIndex:[self.HTTPResponse statusCode]];
}

- (BOOL)hasAcceptableContentType {
    return !self.acceptableContentTypes || [self.acceptableContentTypes containsObject:[self.HTTPResponse MIMEType]];
}

- (NSError *)error {
    if (self.response && !self.HTTPError) {
        if (![self hasAcceptableStatusCode]) {
            NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
            [userInfo setValue:[NSString stringWithFormat:NSLocalizedString(@"Expected status code %@, got %d", nil), self.acceptableStatusCodes, [self.HTTPResponse statusCode]] forKey:NSLocalizedDescriptionKey];
            [userInfo setValue:[self.request URL] forKey:NSURLErrorFailingURLErrorKey];
            
            self.HTTPError = [[[NSError alloc] initWithDomain:ZincNetworkErrorDomain code:NSURLErrorBadServerResponse userInfo:userInfo] autorelease];
        } else if ([self hasContent] && ![self hasAcceptableContentType]) { // Don't invalidate content type if there is no content
            NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
            [userInfo setValue:[NSString stringWithFormat:NSLocalizedString(@"Expected content type %@, got %@", nil), self.acceptableContentTypes, [self.response MIMEType]] forKey:NSLocalizedDescriptionKey];
            [userInfo setValue:[self.request URL] forKey:NSURLErrorFailingURLErrorKey];
            
            self.HTTPError = [[[NSError alloc] initWithDomain:ZincNetworkErrorDomain code:NSURLErrorCannotDecodeContentData userInfo:userInfo] autorelease];
        }
    }
    
    if (_HTTPError) {
        return _HTTPError;
    } else {
        return [super error];
    }
}

@end
