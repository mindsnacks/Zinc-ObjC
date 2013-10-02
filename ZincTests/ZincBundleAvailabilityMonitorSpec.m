//
//  ZincBundleAvailabilityMonitorSpec.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 9/10/13.
//  Copyright 2013 MindSnacks. All rights reserved.
//

#import "ZincBundleAvailabilityMonitor+Private.h"
#import "ZincActivityMonitor+Private.h"
#import "ZincRepo.h"
#import "ZincTask.h"
#import "ZincTaskDescriptor.h"
#import "ZincTaskActions.h"
#import "ZincResource.h"

SPEC_BEGIN(ZincBundleAvailabilityMonitorSpec)

describe(@"ZincBundleAvailabilityMonitorActivityItem", ^{

    __block ZincMockFactory* mockFactory;
    __block ZincBundleAvailabilityMonitorActivityItem* item;
    __block id monitor;
    __block id repo;
    NSString* const bundleID = @"com.mindsnacks.bundle1";

    beforeEach(^{
        mockFactory = [[ZincMockFactory alloc] init];
        repo = [ZincRepo mock];
        monitor = [ZincBundleAvailabilityMonitor mock];
        [monitor stub:@selector(repo) andReturn:repo];
        [monitor stub:@selector(progressBlock) andReturn:nil];
    });

    afterEach(^{
        item = nil;
    });

    context(@"newly created", ^{

        beforeEach(^{
            ZincBundleAvailabilityRequirement* req = [ZincBundleAvailabilityRequirement requirementForBundleID:bundleID versionSpecifier:ZincBundleVersionSpecifierAny];
            item = [[ZincBundleAvailabilityMonitorActivityItem alloc] initWithMonitor:monitor request:req];
        });

        it(@"should have zero progress", ^{
            [[theValue(item.currentProgressValue) should] equal:theValue(0)];
            [[theValue(item.maxProgressValue) should] equal:theValue(kZincBundleAvailabilityMonitorActivityItemMaxProgressValue)];
        });

        context(@"the bundle is available", ^{

            beforeEach(^{
                [repo stub:@selector(hasSpecifiedVersion:forBundleID:) andReturn:theValue(YES) withArguments:any(), bundleID];
                [item update];
            });

            specify(^{
                [[theValue([item currentProgressValue]) should] equal:theValue([item maxProgressValue])];
            });

            specify(^{
                [[theValue([item isFinished]) should] beTrue];
            });

        });
    });

    context(@"repo does not have desired version", ^{

        beforeEach(^{
            [repo stub:@selector(hasSpecifiedVersion:forBundleID:) andReturn:theValue(NO) withArguments:any(), bundleID];
        });

        context(@"has an operation", ^{

            __block id operation;

            beforeEach(^{
                ZincBundleAvailabilityRequirement* req = [ZincBundleAvailabilityRequirement requirementForBundleID:bundleID versionSpecifier:ZincBundleVersionSpecifierAny];
                item = [[ZincBundleAvailabilityMonitorActivityItem alloc] initWithMonitor:monitor request:req];
                operation = [mockFactory mockOperation];
                item.subject = operation;
            });

            context(@"the operation is finished", ^{

                const long long operationProgressValue = 100;

                beforeEach(^{
                    [(id)[operation progress] stub:@selector(currentProgressValue) andReturn:theValue(operationProgressValue)];
                    [(id)[operation progress] stub:@selector(maxProgressValue) andReturn:theValue(operationProgressValue)];
                    [operation stub:@selector(isFinished) andReturn:theValue(YES)];
                });

                specify(^{
                    [[theValue([item isFinished]) should] beFalse];
                });

                context(@"the item is updated", ^{

                    beforeEach(^{
                        [item update];
                    });

                    specify(^{
                        [[theValue([item isFinished]) should] beFalse];
                    });

                    it(@"should unassociate the operation", ^{
                        // this is an ugly expection but it wasn't compiling any other way
                        [[theValue(item.subject == nil) should] beTrue];
                    });

                    it(@"should reset progress", ^{
                        [[theValue(item.currentProgressValue) should] equal:theValue(0)];
                    });

                });
            });

            context(@"the operation is not finished", ^{

                const long long currentProgressValue = 10;
                const long long maxProgressValue = 100;
                const float progressPercentage = 0.1f;

                beforeEach(^{
                    [operation stub:@selector(isFinished) andReturn:theValue(NO)];
                    [(id)[operation progress] stub:@selector(currentProgressValue) andReturn:theValue(currentProgressValue)];
                    [(id)[operation progress] stub:@selector(maxProgressValue) andReturn:theValue(maxProgressValue)];
                    [(id)[operation progress] stub:@selector(progressPercentage) andReturn:theValue(progressPercentage)];

                    [item update];
                });

                it(@"has the right progress when updated", ^{
                    [[theValue(item.currentProgressValue) should] equal:progressPercentage*kZincBundleAvailabilityMonitorActivityItemMaxProgressValue withDelta:0.01];
                });

                specify(^{
                    [[theValue([item isFinished]) should] beFalse];
                });
            });
        });
    });

    context(@"repo has the catalog version", ^{

        beforeEach(^{
            [repo stub:@selector(hasSpecifiedVersion:forBundleID:) andReturn:theValue(YES) withArguments:any(), bundleID];
        });

        context(@"catalog version is not required", ^{

            beforeEach(^{
                ZincBundleAvailabilityRequirement* req = [ZincBundleAvailabilityRequirement requirementForBundleID:bundleID versionSpecifier:ZincBundleVersionSpecifierAny];
                item = [[ZincBundleAvailabilityMonitorActivityItem alloc] initWithMonitor:monitor request:req];
                [item update];
            });

            specify(^{
                [[theValue([item isFinished]) should] beTrue];
            });
        });

        context(@"catalog version is  required", ^{

            beforeEach(^{
                ZincBundleAvailabilityRequirement* req = [ZincBundleAvailabilityRequirement requirementForBundleID:bundleID versionSpecifier:ZincBundleVersionSpecifierCatalogOnly];
                item = [[ZincBundleAvailabilityMonitorActivityItem alloc] initWithMonitor:monitor request:req];
                [item update];
            });

            specify(^{
                [[theValue([item isFinished]) should] beTrue];
            });
        });
    });

    context(@"repo has an old version", ^{

        beforeEach(^{
            [repo stub:@selector(hasSpecifiedVersion:forBundleID:) andReturn:theValue(YES) withArguments:theValue(ZincBundleVersionSpecifierAny), bundleID];
            [repo stub:@selector(hasSpecifiedVersion:forBundleID:) andReturn:theValue(YES) withArguments:theValue(ZincBundleVersionSpecifierNotUnknown), bundleID];
            [repo stub:@selector(hasSpecifiedVersion:forBundleID:) andReturn:theValue(NO) withArguments:theValue(ZincBundleVersionSpecifierCatalogOnly), bundleID];
        });

        context(@"catalog version is not required", ^{

            beforeEach(^{
                ZincBundleAvailabilityRequirement* req = [ZincBundleAvailabilityRequirement requirementForBundleID:bundleID versionSpecifier:ZincBundleVersionSpecifierAny];
                item = [[ZincBundleAvailabilityMonitorActivityItem alloc] initWithMonitor:monitor request:req];
                [item update];
            });

            specify(^{
                [[theValue([item isFinished]) should] beTrue];
            });
        });

        context(@"catalog version is  required", ^{

            beforeEach(^{
                ZincBundleAvailabilityRequirement* req = [ZincBundleAvailabilityRequirement requirementForBundleID:bundleID versionSpecifier:ZincBundleVersionSpecifierCatalogOnly];
                item = [[ZincBundleAvailabilityMonitorActivityItem alloc] initWithMonitor:monitor request:req];
                [item update];
            });

            specify(^{
                [[theValue([item isFinished]) should] beFalse];
            });
        });
    });
});


describe(@"ZincBundleAvailabilityMonitor", ^{

    __block ZincBundleAvailabilityMonitor* monitor;
    __block id repo;
    __block ZincMockFactory* mockFactory;
    
    NSString* const bundleID = @"com.mindsnacks.bundle1";
    ZincVersion const previousVersion = 1;
    ZincVersion const currentVersion = 2;

    void (^initializeMonitor)(BOOL) = ^(BOOL requireCatalogVersion) {
        ZincBundleAvailabilityRequirement* req = [ZincBundleAvailabilityRequirement requirementForBundleID:bundleID versionSpecifier:requireCatalogVersion];
        monitor = [[ZincBundleAvailabilityMonitor alloc] initWithRepo:repo requirements:@[req]];
    };

    // ----

    beforeEach(^{
        mockFactory = [[ZincMockFactory alloc] init];
        repo = [ZincRepo mock];
    });

    context(@"monitoring a single bundle", ^{

        beforeEach(^{
            initializeMonitor(ZincBundleVersionSpecifierAny);
        });

        it(@"should have one activity item", ^{
            [[[monitor items] should] haveCountOf:1];
            ZincBundleAvailabilityMonitorActivityItem* item = (ZincBundleAvailabilityMonitorActivityItem*)[[monitor items] objectAtIndex:0];
            [[item.requirement.bundleID should] equal:bundleID];
        });
    });

    context(@"repo does not have the bundle", ^{

        beforeEach(^{
            [repo stub:@selector(hasSpecifiedVersion:forBundleID:) andReturn:theValue(NO) withArguments:any(), bundleID];
            [repo stub:@selector(tasks) andReturn:@[]];

            initializeMonitor(ZincBundleVersionSpecifierAny);
        });

        it(@"should not be finished when updated", ^{
            [monitor update];
            [[theValue([monitor.progress isFinished]) should] equal:theValue(NO)];
        });

        context(@"repo has a task for the bundle", ^{

            __block id task;

            beforeEach(^{

                NSURL* bundleRes = [NSURL zincResourceForBundleWithID:bundleID version:currentVersion];
                [repo stub:@selector(bundleResource:satisfiesVersionSpecifier:) andReturn:theValue(YES) withArguments:bundleRes, any()];

                task = [mockFactory mockBundleCloneTaskForBundleID:bundleID version:currentVersion];
                [repo stub:@selector(tasks) andReturn:@[task]];
            });

            it(@"should associate an operation when added after started", ^{
                [monitor startMonitoring];

                [[NSNotificationCenter defaultCenter] postNotificationName:ZincRepoTaskAddedNotification object:repo userInfo:@{ZincRepoTaskNotificationTaskKey: task}];

                [monitor update];
                ZincBundleAvailabilityMonitorActivityItem* item = (ZincBundleAvailabilityMonitorActivityItem*)[[monitor items] objectAtIndex:0];
                [[(NSObject*)item.subject should] beIdenticalTo:task];
            });
        });

        context(@"repo has a task for a different bundle", ^{

            beforeEach(^{
                [repo stub:@selector(bundleResource:satisfiesVersionSpecifier:) andReturn:theValue(NO) withArguments:any(), any()];

                id task = [mockFactory mockBundleCloneTaskForBundleID:@"com.mindsnacks.purple" version:2];
                [repo stub:@selector(tasks) andReturn:@[task]];
            });

            it(@"should not associate the task when started", ^{
                [monitor startMonitoring];
                ZincBundleAvailabilityMonitorActivityItem* item = (ZincBundleAvailabilityMonitorActivityItem*)[[monitor items] objectAtIndex:0];
                // this is an ugly expection but it wasn't compiling any other way
                [[theValue(item.subject == nil) should] beTrue];
            });
        });
    });

    context(@"repo has the catalog version", ^{

        beforeEach(^{
            [repo stub:@selector(hasSpecifiedVersion:forBundleID:) andReturn:theValue(YES) withArguments:any(), bundleID];
        });

        it(@"should finish if the catalog version is not required", ^{
            initializeMonitor(ZincBundleVersionSpecifierAny);
            [monitor update];
            [[theValue([monitor.progress isFinished]) should] beTrue];
        });

        it(@"should finish if the catalog version is required", ^{
            initializeMonitor(ZincBundleVersionSpecifierCatalogOnly);
            [monitor update];
            [[theValue([monitor.progress isFinished]) should] beTrue];
        });
    });

    context(@"repo has a version, but not the catalog version", ^{

        beforeEach(^{
            [repo stub:@selector(hasSpecifiedVersion:forBundleID:) andReturn:theValue(YES) withArguments:theValue(ZincBundleVersionSpecifierAny), bundleID];
            [repo stub:@selector(hasSpecifiedVersion:forBundleID:) andReturn:theValue(NO) withArguments:theValue(ZincBundleVersionSpecifierNotUnknown), bundleID];
            [repo stub:@selector(hasSpecifiedVersion:forBundleID:) andReturn:theValue(NO) withArguments:theValue(ZincBundleVersionSpecifierCatalogOnly), bundleID];
        });

        it(@"should finish if the catalog version is not required", ^{
            initializeMonitor(ZincBundleVersionSpecifierAny);
            [monitor update];
            [[theValue([monitor.progress isFinished]) should] beTrue];
        });

        it(@"should not finish if the catalog version is required", ^{
            initializeMonitor(ZincBundleVersionSpecifierCatalogOnly);
            [monitor update];
            [[theValue([monitor.progress isFinished]) should] beFalse];
        });
    });

    context(@"repo has a task for the desired bundleVersion", ^{

        __block id task;

        beforeEach(^{

            NSURL* bundleRes = [NSURL zincResourceForBundleWithID:bundleID version:currentVersion];

            [repo stub:@selector(hasSpecifiedVersion:forBundleID:) andReturn:theValue(NO) withArguments:any(), bundleID];
            [repo stub:@selector(bundleResource:satisfiesVersionSpecifier:) andReturn:theValue(YES) withArguments:bundleRes, any()];

            task = [mockFactory mockBundleCloneTaskForBundleID:bundleID version:currentVersion];
            [repo stub:@selector(tasks) andReturn:@[task]];

            initializeMonitor(ZincBundleVersionSpecifierAny);
        });

        it(@"should associate the task when started", ^{
            [monitor startMonitoring];
            ZincBundleAvailabilityMonitorActivityItem* item = (ZincBundleAvailabilityMonitorActivityItem*)[[monitor items] objectAtIndex:0];
            [[(NSObject *)[item subject] should] beIdenticalTo:task];
        });
    });

    context(@"repo has a task for the desired bundle but old version", ^{

        __block id task;

        beforeEach(^{

            NSURL* bundleRes = [NSURL zincResourceForBundleWithID:bundleID version:previousVersion];
            
            [repo stub:@selector(hasSpecifiedVersion:forBundleID:) andReturn:theValue(NO) withArguments:any(), bundleID];
            [repo stub:@selector(bundleResource:satisfiesVersionSpecifier:) andReturn:theValue(YES) withArguments:bundleRes, theValue(ZincBundleVersionSpecifierAny)];
            [repo stub:@selector(bundleResource:satisfiesVersionSpecifier:) andReturn:theValue(YES) withArguments:bundleRes, theValue(ZincBundleVersionSpecifierNotUnknown)];
            [repo stub:@selector(bundleResource:satisfiesVersionSpecifier:) andReturn:theValue(NO) withArguments:bundleRes, theValue(ZincBundleVersionSpecifierCatalogOnly)];

            task = [mockFactory mockBundleCloneTaskForBundleID:bundleID version:previousVersion];
            [repo stub:@selector(tasks) andReturn:@[task]];
        });

        it(@"should associate the task when started if it doesn't require current version", ^{
            initializeMonitor(ZincBundleVersionSpecifierAny);
            [monitor startMonitoring];
            ZincBundleAvailabilityMonitorActivityItem* item = (ZincBundleAvailabilityMonitorActivityItem*)[[monitor items] objectAtIndex:0];
            [[(NSObject*)item.subject should] beIdenticalTo:task];
        });

        it(@"should not associate the task when started if it requires current version", ^{
            initializeMonitor(ZincBundleVersionSpecifierCatalogOnly);
            [monitor startMonitoring];
            ZincBundleAvailabilityMonitorActivityItem* item = (ZincBundleAvailabilityMonitorActivityItem*)[[monitor items] objectAtIndex:0];
            // this is an ugly expection but it wasn't compiling any other way
            [[theValue(item.subject == nil) should] beTrue];
        });
    });
});


SPEC_END
