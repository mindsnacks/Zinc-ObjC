//
//  ZincOperation.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 7/27/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincOperation.h"
#import "ZincRepo+Private.h"


double const kZincOperationInitialDefaultThreadPriority = 0.5;

#if __IPHONE_OS_VERSION_MIN_REQUIRED
#import <UIKit/UIKit.h>
typedef UIBackgroundTaskIdentifier ZincBackgroundTaskIdentifier;
#else
typedef id ZincBackgroundTaskIdentifier;
#endif


@interface ZincOperation ()

@property (nonatomic, assign, readwrite) ZincRepo* repo;
@property (atomic, retain) NSMutableArray* myEvents;
@property (readwrite, nonatomic, assign) ZincBackgroundTaskIdentifier backgroundTaskIdentifier;

@end


@implementation ZincOperation

double _defaultThreadPriority = kZincOperationInitialDefaultThreadPriority;

+ (void)setDefaultThreadPriority:(double)defaultThreadPriority
{
    @synchronized(self) {
        _defaultThreadPriority = defaultThreadPriority;
    }
}

+ (double)defaultThreadPriority
{
    return _defaultThreadPriority;
}

- (id)initWithRepo:(ZincRepo*)repo
{
    self = [super init];
    if (self) {
        self.repo = repo;
        self.myEvents = [NSMutableArray array];
        self.threadPriority = [[self class] defaultThreadPriority];
    }
    return self;
}

- (void)dealloc
{
#if __IPHONE_OS_VERSION_MIN_REQUIRED
    if (_backgroundTaskIdentifier) {
        [[UIApplication sharedApplication] endBackgroundTask:_backgroundTaskIdentifier];
        _backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    }
#endif
    [_myEvents release];
    [super dealloc];
}


#if __IPHONE_OS_VERSION_MIN_REQUIRED
- (void)setShouldExecuteAsBackgroundTask
{
    if (!self.backgroundTaskIdentifier) {
        
        UIApplication *application = [UIApplication sharedApplication];
        __block typeof(self) blockSelf = self;
        self.backgroundTaskIdentifier = [application beginBackgroundTaskWithExpirationHandler:^{
            
            UIBackgroundTaskIdentifier backgroundTaskIdentifier =  blockSelf.backgroundTaskIdentifier;
            blockSelf.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
            
            [blockSelf cancel];
            
            [application endBackgroundTask:backgroundTaskIdentifier];
        }];
    }
}
#endif


- (NSArray*) zincDependencies
{
    return [self.dependencies filteredArrayUsingPredicate:
            [NSPredicate predicateWithBlock:^(id obj, NSDictionary* bindings) {
        return [obj isKindOfClass:[ZincOperation class]];
    }]];
}


- (long long) currentProgressValue
{
    return [[self.zincDependencies valueForKeyPath:@"@sum.currentProgressValue"] longLongValue] + ([self isFinished] ? 1 : 0);
}


- (long long) maxProgressValue
{
    return [[self.zincDependencies valueForKeyPath:@"@sum.maxProgressValue"] longLongValue] + 1;
}


- (float) progress
{
    return ZincProgressCalculate(self);
}


- (void) addEvent:(ZincEvent*)event
{
    [self.myEvents addObject:event];
    [self.repo logEvent:event];
}


- (NSArray*) events
{
    return [NSArray arrayWithArray:self.myEvents];
}

@end
