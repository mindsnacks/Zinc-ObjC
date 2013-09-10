//
//  ZincActivityMonitor.m
//  
//
//  Created by Andy Mroczkowski on 9/8/12.
//
//

#import "ZincActivityMonitor.h"

#import "ZincActivityMonitor+Private.h"
#import "ZincProgress+Private.h"
#import "ZincTask.h"
#import "ZincInternals.h"


NSString* const ZincActivityMonitorRefreshedNotification = @"ZincActivityMonitorRefreshedNotification";


@interface ZincActivityMonitor ()
@property (nonatomic, strong) NSTimer* refreshTimer;
@property (nonatomic, readwrite, assign) BOOL isMonitoring;
@end


@implementation ZincActivityMonitor

- (id)init
{
    self = [super init];
    if (self) {
        _refreshInterval = kZincActivityMonitorDefaultRefreshInterval;
    }
    return self;
}

- (void)dealloc
{
    [self stopMonitoring];
}

- (void)restartRefreshTimer
{
    [self stopRefreshTimer];
    
    if (!self.isMonitoring) return;

    if (self.refreshInterval > 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:self.refreshInterval
                                                                 target:self
                                                               selector:@selector(update)
                                                               userInfo:nil
                                                                repeats:YES];
        });
    }
}

- (void)stopRefreshTimer
{
    [self.refreshTimer invalidate];
    self.refreshTimer = nil;
}

- (void)setRefreshInterval:(NSTimeInterval)refreshInterval
{
    _refreshInterval = refreshInterval;
    [self restartRefreshTimer];
}

- (void) startMonitoring
{
    @synchronized(self) {
        if (self.isMonitoring) return;
        self.isMonitoring = YES;
        [self restartRefreshTimer];
        [self monitoringDidStart];
    }
}

- (void) stopMonitoring
{
    @synchronized(self) {
        if (!self.isMonitoring) return;
        self.isMonitoring = NO;
        [self stopRefreshTimer];
        [self monitoringDidStop];
    }
}

- (NSArray*) items
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (NSArray*) finishedItems
{
    return [[self items] filteredArrayUsingPredicate:
            [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return [evaluatedObject isFinished];
    }]];
}

- (void) update
{
    [[self items] makeObjectsPerformSelector:@selector(update)];

    [self itemsDidUpdate];

    [[NSNotificationCenter defaultCenter] postNotificationName:ZincActivityMonitorRefreshedNotification object:self];
}

- (void) itemsDidUpdate
{
}

- (void) monitoringDidStart
{
}

- (void) monitoringDidStop
{
}

@end


@implementation ZincActivityItem

- (id) initWithActivityMonitor:(ZincActivityMonitor*)monitor operation:(ZincOperation*)operation
{
    NSParameterAssert(monitor);
    self = [super init];
    if (self) {
        _monitor = monitor;
        _operation = operation;
    }
    return self;
}

- (id) initWithActivityMonitor:(ZincActivityMonitor*)monitor
{
    return [self initWithActivityMonitor:monitor operation:nil];
}

- (void) setProgressPercentage:(float)progressPercentage
{
    [super setProgressPercentage:progressPercentage];

    if (self.monitor.progressBlock != nil) {
        ZINC_DEBUG_LOG(@"%lld %lld %f", self.currentProgressValue, self.maxProgressValue, self.progressPercentage);
        self.monitor.progressBlock(self, self.currentProgressValue, self.maxProgressValue, self.progressPercentage);
    }
}

- (void) update
{
    if ([self isFinished]) return;
    if (self.operation == nil) return;
    
    if ([self.operation isFinished]) {
        
        [self finish];
        
    } else {
        
        [self updateFromProgress:self.operation];
    }
}

@end