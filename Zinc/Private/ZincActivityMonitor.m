//
//  ZincActivityMonitor.m
//  
//
//  Created by Andy Mroczkowski on 9/8/12.
//
//

#import "ZincActivityMonitor.h"

#import <MSWeakTimer/MSWeakTimer.h>

#import "ZincActivityMonitor+Private.h"
#import "ZincProgress+Private.h"
#import "ZincTask.h"
#import "ZincInternals.h"


NSString* const ZincActivityMonitorRefreshedNotification = @"ZincActivityMonitorRefreshedNotification";


@interface ZincActivityMonitor ()
@property (strong) NSMutableArray* myItems;
@property (strong) MSWeakTimer* refreshTimer;
@property (readwrite, assign) BOOL isMonitoring;
@end


@implementation ZincActivityMonitor

- (id)init
{
    self = [super init];
    if (self) {
        _myItems = [NSMutableArray array];
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
        self.refreshTimer = [MSWeakTimer scheduledTimerWithTimeInterval:self.refreshInterval
                                                                 target:self
                                                               selector:@selector(update)
                                                               userInfo:nil
                                                                repeats:YES
                                                          dispatchQueue:dispatch_get_main_queue()];
    }
}

- (void)stopRefreshTimer
{
    [self.refreshTimer invalidate];
    self.refreshTimer = nil;
}

- (void)setRefreshInterval:(NSTimeInterval)refreshInterval
{
    @synchronized(self) {
        _refreshInterval = refreshInterval;
        [self restartRefreshTimer];
    }
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
    return [NSArray arrayWithArray:self.myItems];
}

- (void) addItem:(ZincActivityItem *)item
{
    NSAssert(item.monitor == self, @"monitor should be self");
    @synchronized(self.myItems) {
        [self.myItems addObject:item];
    }
}

- (void) removeItem:(ZincActivityItem *)item
{
    @synchronized(self.myItems) {
        [self.myItems removeObject:item];
    }
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

- (id) initWithActivityMonitor:(ZincActivityMonitor*)monitor subject:(id<ZincActivitySubject>)subject
{
    NSParameterAssert(monitor);
    self = [super init];
    if (self) {
        _monitor = monitor;
        _subject = subject;
    }
    return self;
}

- (id) initWithActivityMonitor:(ZincActivityMonitor*)monitor
{
    return [self initWithActivityMonitor:monitor subject:nil];
}

- (void) setProgressPercentage:(float)progressPercentage
{
    [super setProgressPercentage:progressPercentage];

    if (self.monitor.progressBlock != nil) {
        ZINC_DEBUG_LOG(@"%lld %lld %f", self.currentProgressValue, self.maxProgressValue, self.progressPercentage);
        self.monitor.progressBlock(self, self.currentProgressValue, self.maxProgressValue, self.progressPercentage);
    }
}

- (BOOL) isFinished
{
    return [self.subject isFinished];
}

- (void) update
{
    if (self.subject != nil) {
        [self updateFromProgress:[self.subject progress]];
    }
}

@end