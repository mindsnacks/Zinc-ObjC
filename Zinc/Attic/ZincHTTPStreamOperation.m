//
//  ZincHTTPStreamOperation.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 2/28/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincHTTPStreamOperation.h"
//#import "ZincHTTPRequestOperation+Private.h"


static void ReadStreamClientCallback (CFReadStreamRef stream, CFStreamEventType event, void *myPtr);


@implementation ZincHTTPStreamOperation

@synthesize url = _url;

- (id) initWithURL:(NSURL*)url
{
    self = [super init];
    if (self) {
        _url = [url retain];
    }
    return self;
}

- (void)dealloc
{
    [_url release];
    if (_response != NULL) CFRelease(_response);
    [super dealloc];
}

#define BUFSIZE 163840
- (void) readStream:(CFReadStreamRef)readStream receivedEvent:(CFStreamEventType)event
{
    switch(event) {
            
        case kCFStreamEventHasBytesAvailable:
        {
            _response = (CFHTTPMessageRef)CFReadStreamCopyProperty(readStream, kCFStreamPropertyHTTPResponseHeader);
            //NSDictionary* headers = [(NSDictionary*)CFHTTPMessageCopyAllHeaderFields(myResponse) autorelease];
            
            if (self.outputStream) {
                [self.outputStream open];
                
            } else {
                
                NSString* contentLengthStr = [(NSString*)CFHTTPMessageCopyHeaderFieldValue(_response, CFSTR("Content-Length")) autorelease];
                NSNumberFormatter* f = [[[NSNumberFormatter alloc] init] autorelease];
                long long contentLength = [[f numberFromString:contentLengthStr] longLongValue];
                
                [self createDataAccumulatorForContentLength:contentLength];
            }
            
            UInt8 buf[BUFSIZE];
            while (CFReadStreamHasBytesAvailable(readStream)) {
                
                CFIndex bytesRead = CFReadStreamRead(readStream, buf, BUFSIZE);
                if (bytesRead > 0) {
                    
                    if (self.outputStream) {
                        [self.outputStream write:buf maxLength:bytesRead];
                    } else {
                        [self.dataAccumulator appendBytes:buf length:bytesRead];
                    }
                }
            }
            
            
//            UInt8 buf[BUFSIZE];
//            CFIndex bytesRead = CFReadStreamRead(readStream, buf, BUFSIZE);
//            if (bytesRead > 0) {
//                if (!CFHTTPMessageIsHeaderComplete(_response)) {
//                    if (!CFHTTPMessageAppendBytes(_response, buf, bytesRead)) {
//                        abort();
//                    }
//                    
//                    // check if header is complete after appending bytes
//                    if (CFHTTPMessageIsHeaderComplete(_response)) {
//                        
//                        // if header is complete set up body data
//                        
//                        if (self.outputStream) {
//                            [self.outputStream open];
//                            
//                        } else {
//                            
//                            NSDictionary* headers = [(NSDictionary*)CFHTTPMessageCopyAllHeaderFields(_response) autorelease];
//                            
//                            NSString* contentLengthStr = [(NSString*)CFHTTPMessageCopyHeaderFieldValue(_response, CFSTR("Content-Length")) autorelease];
//                            NSNumberFormatter* f = [[[NSNumberFormatter alloc] init] autorelease];
//                            long long contentLength = [[f numberFromString:contentLengthStr] longLongValue];
//                                                    
//                            NSUInteger maxCapacity = MAX((NSUInteger)llabs(contentLength), kAFHTTPMinimumInitialDataCapacity);
//                            NSUInteger capacity = MIN(maxCapacity, kAFHTTPMaximumInitialDataCapacity);
//                            self.dataAccumulator = [NSMutableData dataWithCapacity:capacity];
//                        }
//                        
//                        // copy data already read into the HTTP message into the output
//                        
//                        CFDataRef body = CFHTTPMessageCopyBody(_response);
//                        const uint8_t* bodyBytes = CFDataGetBytePtr(body);
//                        NSUInteger bodyLength = CFDataGetLength(body);
//                        
//                        if (self.outputStream) {
//                            [self.outputStream write:bodyBytes maxLength:bodyLength];
//                        } else {
//                            [self.dataAccumulator appendBytes:bodyBytes length:bodyLength];
//                        }
//                    }
//                    
//                } else {
//                    
//                    // append to the appropriate output
//                    
//                    if (self.outputStream) {
//                        [self.outputStream write:buf maxLength:bytesRead];
//                    } else {
//                        [self.dataAccumulator appendBytes:buf length:bytesRead];
//                    }
//                }
//            }
        }    
            break;
        case kCFStreamEventErrorOccurred:
            //            CFStreamError error = CFReadStreamGetError(stream);
            //            reportError(error);
            //            CFReadStreamUnscheduleFromRunLoop(stream, CFRunLoopGetCurrent(),
            //                                              kCFRunLoopCommonModes);
            //            CFReadStreamClose(stream);
            //            CFRelease(stream);
            [self finish];
            break;
        case kCFStreamEventEndEncountered:
            [self finish];
            CFReadStreamUnscheduleFromRunLoop(readStream, CFRunLoopGetCurrent(),
                                              kCFRunLoopCommonModes);
            CFReadStreamClose(readStream);
            CFRelease(readStream);
            break;
    }
}

- (void) main
{
    CFHTTPMessageRef request = CFHTTPMessageCreateRequest(kCFAllocatorDefault,
                                                          CFSTR("GET"), (CFURLRef)self.url, kCFHTTPVersion1_1);
    
    CFReadStreamRef requestStream = CFReadStreamCreateForHTTPRequest(kCFAllocatorDefault, request);
    
    if (!CFReadStreamSetProperty(requestStream, kCFStreamPropertyHTTPAttemptPersistentConnection, kCFBooleanTrue)) {
        abort();
    }
    
    if (!CFReadStreamSetProperty(requestStream, kCFStreamPropertyHTTPShouldAutoredirect, kCFBooleanTrue)) {
        abort();
    }
    
    CFStreamClientContext clientContext = {0, self, NULL, NULL, NULL};
    
    CFOptionFlags registeredEvents = kCFStreamEventHasBytesAvailable |
    kCFStreamEventErrorOccurred | kCFStreamEventEndEncountered /*| kCFStreamEventOpenCompleted*/;
    
    if (CFReadStreamSetClient(requestStream, registeredEvents, ReadStreamClientCallback, &clientContext))
    {
        CFReadStreamScheduleWithRunLoop(requestStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
    }
    
    //_response = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, FALSE);
    
    if (!CFReadStreamOpen(requestStream)) {
        CFStreamError requestErr = CFReadStreamGetError(requestStream);
        if (requestErr.error != 0) {
            abort();
            //            // An error has occurred.
            //            if (myErr.domain == kCFStreamErrorDomainPOSIX) {
            //                // Interpret myErr.error as a UNIX errno.
            //                strerror(myErr.error);
            //            } else if (myErr.domain == kCFStreamErrorDomainMacOSStatus) {
            //                OSStatus macError = (OSStatus)myErr.error;
            //            }
            //            // Check other domains.
        } else {
           // CFRunLoopRun();
        }
    }
}

- (BOOL)hasAcceptableStatusCode 
{
    if (!CFHTTPMessageIsHeaderComplete(_response)) {
        return NO;
    }
    if (!self.acceptableStatusCodes) {
        return NO;
    }
    
    UInt32 status = CFHTTPMessageGetResponseStatusCode(_response);
    return [self.acceptableStatusCodes containsIndex:status];
}

@end


static void ReadStreamClientCallback (CFReadStreamRef stream, CFStreamEventType event, void *ctx) 
{
    ZincHTTPStreamOperation* op = (ZincHTTPStreamOperation*)ctx;
    [op readStream:stream receivedEvent:event];
}
