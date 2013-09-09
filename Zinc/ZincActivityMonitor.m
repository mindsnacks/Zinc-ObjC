//
//  ZincActivityMonitor.m
//  
//
//  Created by Andy Mroczkowski on 9/8/12.
//
//

#import "ZincActivityMonitor.h"

#import "ZincActivityMonitor+Private.h"
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
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:self.refreshInterval
                                                             target:self
                                                           selector:@selector(update)
                                                           userInfo:nil
                                                            repeats:YES];
    });
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
    return nil;
}

- (void) update
{
    @throw [NSException
            exceptionWithName:NSGenericException
            reason:[NSString stringWithFormat:@"method not implemented"]
            userInfo:nil];
}

- (void) monitoringDidStart
{
}

- (void) monitoringDidStop
{
}

@end


@implementation ZincActivityItem : NSObject

- (id) initWithActivityMonitor:(ZincActivityMonitor*)monitor
{
    self = [super init];
    if (self) {
        _monitor = monitor;
    }
    return self;
}



- (void) finish
{
    self.currentProgressValue = self.maxProgressValue;
    self.progress = 1.0f;
}

- (void) setProgress:(float)progress
{
    _progress = progress;
    
    if (self.monitor.progressBlock != nil) {
        ZINC_DEBUG_LOG(@"%lld %lld %f", self.currentProgressValue, self.maxProgressValue, self.progress);
        self.monitor.progressBlock(self, self.currentProgressValue, self.maxProgressValue, self.progress);
    }
}

- (BOOL) isFinished
{
    return self.progress == 1.0f;
}

- (void) update
{
    if ([self isFinished]) return;
    if (self.task == nil) return;
    
    if ([self.task isFinished]) {
        
        [self finish];
        
    } else {
        
        BOOL progressValuesChanged = NO;
        
        long long taskCurrentProgressValue = [self.task currentProgressValue];
        long long taskMaxProgressValue = [self.task maxProgressValue];
        
        if (self.currentProgressValue != taskCurrentProgressValue) {
            self.currentProgressValue = taskCurrentProgressValue;
            progressValuesChanged = YES;
        }
        
        if (self.maxProgressValue != taskMaxProgressValue) {
            self.maxProgressValue = taskMaxProgressValue;
            progressValuesChanged = YES;
        }
        
        if (progressValuesChanged) {
            self.progress = ZincProgressCalculate(self);
        }
    }
}

@end