// AFURLConnectionOperation.h
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
#import "ZincHTTPRequestOperation.h"


/**
 `AFURLConnectionOperation` is an `NSOperation` that implements NSURLConnection delegate methods.
 
 ## Subclassing Notes
 
 This is the base class of all network request operations. You may wish to create your own subclass in order to implement additional `NSURLConnection` delegate methods (see "`NSURLConnection` Delegate Methods" below), or to provide additional properties and/or class constructors.
 
 If you are creating a subclass that communicates over the HTTP or HTTPS protocols, you may want to consider subclassing `AFHTTPRequestOperation` instead, as it supports specifying acceptable content types or status codes.
 
 ## NSURLConnection Delegate Methods
 
 `AFURLConnectionOperation` implements the following `NSURLConnection` delegate methods:
 
 - `connection:didReceiveResponse:`
 - `connection:didReceiveData:`
 - `connectionDidFinishLoading:`
 - `connection:didFailWithError:`
 - `connection:didSendBodyData:totalBytesWritten:totalBytesExpectedToWrite:`
 - `connection:willCacheResponse:`
 
 If any of these methods are overriden in a subclass, they _must_ call the `super` implementation first.
 
 Notably, `AFHTTPRequestOperation` does not implement any of the authentication challenge-related `NSURLConnection` delegate methods, and are thus safe to override without a call to `super`.
 
 ## Class Constructors
 
 Class constructors, or methods that return an unowned (zero retain count) instance, are the preferred way for subclasses to encapsulate any particular logic for handling the setup or parsing of response data. For instance, `AFJSONRequestOperation` provides `JSONRequestOperationWithRequest:success:failure:`, which takes block arguments, whose parameter on for a successful request is the JSON object initialized from the `response data`.
 
 ## Callbacks and Completion Blocks
 
 The built-in `completionBlock` provided by `NSOperation` allows for custom behavior to be executed after the request finishes. It is a common pattern for class constructors in subclasses to take callback block parameters, and execute them conditionally in the body of its `completionBlock`. Make sure to handle cancelled operations appropriately when setting a `completionBlock` (e.g. returning early before parsing response data). See the implementation of any of the `AFHTTPRequestOperation` subclasses for an example of this.
 
 @warning Subclasses are strongly discouraged from overriding `setCompletionBlock:`, as `AFURLConnectionOperation`'s implementation includes a workaround to mitigate retain cycles, and what Apple rather ominously refers to as "The Deallocation Problem" (See http://developer.apple.com/library/ios/technotes/tn2109/_index.html#//apple_ref/doc/uid/DTS40010274-CH1-SUBSECTION11) 
 */
@interface ZincHTTPURLConnectionOperation : ZincHTTPRequestOperation {
@private
    
    NSURLConnection *_connection;
    NSURLRequest *_request;
    NSHTTPURLResponse *_response;
    NSError *_HTTPError;
}



///-----------------------------------------
/// @name Getting URL Connection Information
///-----------------------------------------

/**
 The request used by the operation's connection.
 */
@property (readonly, nonatomic, retain) NSURLRequest *request;

/**
 The last response received by the operation's connection.
 */
@property (readonly, nonatomic, retain) NSURLResponse *response;


///----------------------------------------------
/// @name Getting HTTP URL Connection Information
///----------------------------------------------

/**
 The last HTTP response received by the operation's connection.
 */
@property (readonly, nonatomic, retain) NSHTTPURLResponse *HTTPResponse;



///------------------------------------------------------
/// @name Initializing an AFURLConnectionOperation Object
///------------------------------------------------------

///**
// Initializes with a basic GET request for the URL
// */
//- (id) initWithURL:(NSURL*)url;

/**
 Initializes and returns a newly allocated operation object with a url connection configured with the specified url request.
 
 @param urlRequest The request object to be used by the operation connection.
 
 @discussion This is the designated initializer.
 */
- (id)initWithRequest:(NSURLRequest *)urlRequest;

@end
