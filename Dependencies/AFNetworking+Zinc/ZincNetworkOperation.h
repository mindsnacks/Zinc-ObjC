//
//  ZincNetworkOperation.h
//  
//
//  Created by Andy Mroczkowski on 2/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Indicates an error occured in AFNetworking.
 
 @discussion Error codes for ZincNetworkErrorDomain correspond to codes in NSURLErrorDomain.
 */
extern NSString * const ZincNetworkErrorDomain;

/**
 Posted when an operation begins executing.
 */
extern NSString * const ZincNetworkOperationDidStartNotification;

/**
 Posted when an operation finishes.
 */
extern NSString * const ZincNetworkOperationDidFinishNotification;

@interface ZincNetworkOperation : NSOperation 
{
@private
    NSSet *_runLoopModes;
    NSError *_error;
}

///-------------------------------
/// @name Accessing Run Loop Modes
///-------------------------------

/**
 The run loop modes in which the operation will run on the network thread. By default, this is a single-member set containing `NSRunLoopCommonModes`.
 */
@property (nonatomic, retain) NSSet *runLoopModes;

/**
 The error, if any, that occured in the lifecycle of the request.
 */
@property (readonly, nonatomic, retain) NSError *error;

@end


#pragma mark - Private

@interface ZincNetworkOperation ()

@property (readwrite, nonatomic, retain) NSError *error;
- (void)finish;

@end
