// AFHTTPOperation.h
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

#import <Foundation/Foundation.h>
#import "ZincNetworkOperation.h"

/**
 `AFHTTPRequestOperation` is a subclass of `AFURLConnectionOperation` for requests using the HTTP or HTTPS protocols. It encapsulates the concept of acceptable status codes and content types, which determine the success or failure of a request.
 */
@interface ZincHTTPRequestOperation : ZincNetworkOperation {
@private
    NSIndexSet *_acceptableStatusCodes;
    NSSet *_acceptableContentTypes;
    
    NSData *_responseData;
    NSInteger _totalBytesRead;
    NSMutableData *_dataAccumulator;
}


///----------------------------
/// @name Getting Response Data
///----------------------------

/**
 The data received during the request. 
 */
@property (readonly, nonatomic, retain) NSData *responseData;

/**
 The string representation of the response data.
 
 @discussion This method uses the string encoding of the response, or if UTF-8 if not specified, to construct a string from the response data.
 */
//@property (readonly, nonatomic, copy) NSString *responseString;

///------------------------
/// @name Accessing Streams
///------------------------

/**
 The output stream that is used to write data received until the request is finished.
 
 @discussion By default, data is accumulated into a buffer that is stored into `responseData` upon completion of the request. When `outputStream` is set, the data will not be accumulated into an internal buffer, and as a result, the `responseData` property of the completed request will be `nil`.
 */
@property (nonatomic, retain) NSOutputStream *outputStream;


///----------------------------------------------------------
/// @name Managing And Checking For Acceptable HTTP Responses
///----------------------------------------------------------

/**
 Returns an `NSIndexSet` object containing the ranges of acceptable HTTP status codes. When non-`nil`, the operation will set the `error` property to an error in `AFErrorDomain`. See http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html
 
 By default, this is the range 200 to 299, inclusive.
 */
@property (nonatomic, retain) NSIndexSet *acceptableStatusCodes;

/**
 A Boolean value that corresponds to whether the status code of the response is within the specified set of acceptable status codes. Returns `YES` if `acceptableStatusCodes` is `nil`.
 */
@property (readonly) BOOL hasAcceptableStatusCode;

/**
 Returns an `NSSet` object containing the acceptable MIME types. When non-`nil`, the operation will set the `error` property to an error in `AFErrorDomain`. See http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.17 
 
 By default, this is `nil`.
 */
@property (nonatomic, retain) NSSet *acceptableContentTypes;

/**
 A Boolean value that corresponds to whether the MIME type of the response is among the specified set of acceptable content types. Returns `YES` if `acceptableContentTypes` is `nil`.
 */
@property (readonly) BOOL hasAcceptableContentType;

///-----------------------------------------------------------
/// @name Setting Completion Block Success / Failure Callbacks
///-----------------------------------------------------------

/**
 Sets the `completionBlock` property with a block that executes either the specified success or failure block, depending on the state of the request on completion. If `error` returns a value, which can be caused by an unacceptable status code or content type, then `failure` is executed. Otherwise, `success` is executed.
 
 @param success The block to be executed on the completion of a successful request. This block has no return value and takes two arguments: the receiver operation and the object constructed from the response data of the request.
 @param failure The block to be executed on the completion of an unsuccessful request. This block has no return value and takes two arguments: the receiver operation and the error that occured during the request.
 
 @discussion This method should be overridden in subclasses in order to specify the response object passed into the success block.
 */
- (void)setCompletionBlockWithSuccess:(void (^)(ZincHTTPRequestOperation *operation, id responseObject))success
                              failure:(void (^)(ZincHTTPRequestOperation *operation, NSError *error))failure;



///---------------------------------
/// @name Setting Progress Callbacks
///---------------------------------

/**
 Sets a callback to be called when an undetermined number of bytes have been uploaded to the server.
 
 @param block A block object to be called when an undetermined number of bytes have been uploaded to the server. This block has no return value and takes three arguments: the number of bytes read since the last time the upload progress block was called, the total bytes read, and the total bytes expected to be read during the request, as initially determined by the expected content size of the `NSHTTPURLResponse` object. This block may be called multiple times.
 
 @see setUploadProgressBlock
 */
- (void)setDownloadProgressBlock:(void (^)(NSInteger bytesRead, NSInteger totalBytesRead, NSInteger totalBytesExpectedToRead))block;


@end


typedef void (^ZincURLConnectionOperationProgressBlock)(NSInteger bytes, NSInteger totalBytes, NSInteger totalBytesExpected);





