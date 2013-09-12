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

    __block ZincBundleAvailabilityMonitorActivityItem* item;
    __block id monitor;
    __block id repo;
    NSString* const bundleID = @"com.mindsnacks.bundle1";

    beforeEach(^{
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
            ZincBundleAvailabilityRequirement* req = [ZincBundleAvailabilityRequirement requirementForBundleID:bundleID versionSpecifier:ZincBundleAvailabilityRequirementVersionSpecifierAny];
            item = [[ZincBundleAvailabilityMonitorActivityItem alloc] initWithMonitor:monitor request:req];
        });

        it(@"should have zero progress", ^{
            [[theValue(item.currentProgressValue) should] equal:theValue(0)];
            [[theValue(item.maxProgressValue) should] equal:theValue(0)];
        });

        it(@"should not be finished", ^{
            [[theValue([item isFinished]) should] equal:theValue(NO)];
        });
    });

    context(@"repo does not have desired version", ^{

        beforeEach(^{
            [repo stub:@selector(stateForBundleWithID:) andReturn:theValue(ZincBundleStateNone) withArguments:bundleID];
            [repo stub:@selector(hasCurrentDistroVersionForBundleID:) andReturn:theValue(NO) withArguments:bundleID];
        });

        context(@"has an operation", ^{

            __block id operation;

            beforeEach(^{
                ZincBundleAvailabilityRequirement* req = [ZincBundleAvailabilityRequirement requirementForBundleID:bundleID versionSpecifier:ZincBundleAvailabilityRequirementVersionSpecifierAny];
                item = [[ZincBundleAvailabilityMonitorActivityItem alloc] initWithMonitor:monitor request:req];
                operation = [ZincOperation mock];
                item.operation = operation;
            });

            context(@"the operation is finished", ^{

                const long long operationProgressValue = 100;

                beforeEach(^{
                    [operation stub:@selector(currentProgressValue) andReturn:theValue(operationProgressValue)];
                    [operation stub:@selector(maxProgressValue) andReturn:theValue(operationProgressValue)];
                    [operation stub:@selector(isFinished) andReturn:theValue(YES)];
                    [item update];
                });

                it(@"should unassociate the operation", ^{
                    [[item.operation should] beNil];
                });

                it(@"should reset progress", ^{
                    [[theValue(item.currentProgressValue) should] equal:theValue(0)];
                    [[theValue(item.maxProgressValue) should] equal:theValue(operationProgressValue)];
                });

                specify(^{
                    [[theValue([item isFinished]) should] beFalse];
                });
            });

            context(@"the operation is not finished", ^{

                const long long currentProgressValue = 10;
                const long long maxProgressValue = 100;

                beforeEach(^{
                    [operation stub:@selector(isFinished) andReturn:theValue(NO)];
                    [operation stub:@selector(currentProgressValue) andReturn:theValue(currentProgressValue)];
                    [operation stub:@selector(maxProgressValue) andReturn:theValue(maxProgressValue)];
                    [item update];
                });

                it(@"has the right progress when updated", ^{
                    [[theValue(item.currentProgressValue) should] equal:theValue(currentProgressValue)];
                    [[theValue(item.maxProgressValue) should] equal:theValue(maxProgressValue)];
                });

                specify(^{
                    [[theValue([item isFinished]) should] beFalse];
                });
            });
        });
    });

    context(@"repo has the catalog version", ^{

        beforeEach(^{
            [repo stub:@selector(hasCurrentDistroVersionForBundleID:) andReturn:theValue(YES) withArguments:bundleID];
            [repo stub:@selector(stateForBundleWithID:) andReturn:theValue(ZincBundleStateAvailable) withArguments:bundleID];
        });

        context(@"catalog version is not required", ^{

            beforeEach(^{
                ZincBundleAvailabilityRequirement* req = [ZincBundleAvailabilityRequirement requirementForBundleID:bundleID versionSpecifier:ZincBundleAvailabilityRequirementVersionSpecifierAny];
                item = [[ZincBundleAvailabilityMonitorActivityItem alloc] initWithMonitor:monitor request:req];
                [item update];
            });

            specify(^{
                [[theValue([item isFinished]) should] beTrue];
            });
        });

        context(@"catalog version is  required", ^{

            beforeEach(^{
                ZincBundleAvailabilityRequirement* req = [ZincBundleAvailabilityRequirement requirementForBundleID:bundleID versionSpecifier:ZincBundleAvailabilityRequirementVersionSpecifierCatalogOnly];
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
            [repo stub:@selector(hasCurrentDistroVersionForBundleID:) andReturn:theValue(NO) withArguments:bundleID];
            [repo stub:@selector(stateForBundleWithID:) andReturn:theValue(ZincBundleStateAvailable) withArguments:bundleID];
        });

        context(@"catalog version is not required", ^{

            beforeEach(^{
                ZincBundleAvailabilityRequirement* req = [ZincBundleAvailabilityRequirement requirementForBundleID:bundleID versionSpecifier:ZincBundleAvailabilityRequirementVersionSpecifierAny];
                item = [[ZincBundleAvailabilityMonitorActivityItem alloc] initWithMonitor:monitor request:req];
                [item update];
            });

            specify(^{
                [[theValue([item isFinished]) should] beTrue];
            });
        });

        context(@"catalog version is  required", ^{

            beforeEach(^{
                ZincBundleAvailabilityRequirement* req = [ZincBundleAvailabilityRequirement requirementForBundleID:bundleID versionSpecifier:ZincBundleAvailabilityRequirementVersionSpecifierCatalogOnly];
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
            initializeMonitor(ZincBundleAvailabilityRequirementVersionSpecifierAny);
        });

        it(@"should have one activity item", ^{
            [[[monitor items] should] haveCountOf:1];
            ZincBundleAvailabilityMonitorActivityItem* item = (ZincBundleAvailabilityMonitorActivityItem*)[[monitor items] objectAtIndex:0];
            [[item.requirement.bundleID should] equal:bundleID];
        });
    });

    context(@"repo does not have the bundle", ^{

        beforeEach(^{
            [repo stub:@selector(hasCurrentDistroVersionForBundleID:) andReturn:theValue(NO) withArguments:bundleID];
            [repo stub:@selector(stateForBundleWithID:) andReturn:theValue(ZincBundleStateNone) withArguments:bundleID];
            [repo stub:@selector(tasks) andReturn:@[]];

            initializeMonitor(ZincBundleAvailabilityRequirementVersionSpecifierAny);
        });

        it(@"should not be finished when updated", ^{
            [monitor update];
            [[theValue([monitor.progress isFinished]) should] equal:theValue(NO)];
        });

        it(@"should associate an operation when added after started", ^{
            [monitor startMonitoring];

            id task = [mockFactory mockBundleCloneTaskForBundleID:bundleID version:currentVersion];
            [repo stub:@selector(tasks) andReturn:@[task]];
            [[NSNotificationCenter defaultCenter] postNotificationName:ZincRepoTaskAddedNotification object:repo userInfo:@{ZincRepoTaskNotificationTaskKey: task}];

            [monitor update];
            ZincBundleAvailabilityMonitorActivityItem* item = (ZincBundleAvailabilityMonitorActivityItem*)[[monitor items] objectAtIndex:0];
            [[[item operation] should] beIdenticalTo:task];
        });

        context(@"repo has a task for a different bundle", ^{

            beforeEach(^{
                id task = [mockFactory mockBundleCloneTaskForBundleID:@"com.mindsnacks.purple" version:2];
                [repo stub:@selector(tasks) andReturn:@[task]];
            });

            it(@"should not associate the task when started", ^{
                [monitor startMonitoring];
                ZincBundleAvailabilityMonitorActivityItem* item = (ZincBundleAvailabilityMonitorActivityItem*)[[monitor items] objectAtIndex:0];
                [[[item operation] should] beNil];
            });
        });
    });

    context(@"repo has the catalog version", ^{

        beforeEach(^{
            [repo stub:@selector(hasCurrentDistroVersionForBundleID:) andReturn:theValue(YES) withArguments:bundleID];
            [repo stub:@selector(stateForBundleWithID:) andReturn:theValue(ZincBundleStateAvailable) withArguments:bundleID];
        });

        it(@"should finish if the catalog version is not required", ^{
            initializeMonitor(ZincBundleAvailabilityRequirementVersionSpecifierAny);
            [monitor update];
            [[theValue([monitor.progress isFinished]) should] beTrue];
        });

        it(@"should finish if the catalog version is required", ^{
            initializeMonitor(ZincBundleAvailabilityRequirementVersionSpecifierCatalogOnly);
            [monitor update];
            [[theValue([monitor.progress isFinished]) should] beTrue];
        });
    });

    context(@"repo has a version, but not the catalog version", ^{

        beforeEach(^{
            [repo stub:@selector(hasCurrentDistroVersionForBundleID:) andReturn:theValue(NO) withArguments:bundleID];
            [repo stub:@selector(stateForBundleWithID:) andReturn:theValue(ZincBundleStateAvailable) withArguments:bundleID];
        });

        it(@"should finish if the catalog version is not required", ^{
            initializeMonitor(ZincBundleAvailabilityRequirementVersionSpecifierAny);
            [monitor update];
            [[theValue([monitor.progress isFinished]) should] beTrue];
        });

        it(@"should not finish if the catalog version is required", ^{
            initializeMonitor(ZincBundleAvailabilityRequirementVersionSpecifierCatalogOnly);
            [monitor update];
            [[theValue([monitor.progress isFinished]) should] beFalse];
        });
    });

    context(@"repo has a task for the desired bundleVersion", ^{

        __block id task;

        beforeEach(^{
            [repo stub:@selector(hasCurrentDistroVersionForBundleID:) andReturn:theValue(NO) withArguments:bundleID];
            [repo stub:@selector(stateForBundleWithID:) andReturn:theValue(ZincBundleStateCloning) withArguments:bundleID];

            task = [mockFactory mockBundleCloneTaskForBundleID:bundleID version:currentVersion];
            [repo stub:@selector(tasks) andReturn:@[task]];

            initializeMonitor(ZincBundleAvailabilityRequirementVersionSpecifierAny);
        });

        it(@"should associate the task when started", ^{
            [monitor startMonitoring];
            ZincBundleAvailabilityMonitorActivityItem* item = (ZincBundleAvailabilityMonitorActivityItem*)[[monitor items] objectAtIndex:0];
            [[[item operation] should] beIdenticalTo:task];
        });
    });

    context(@"repo has a task for the desired bundle but old version", ^{

        __block id task;

        beforeEach(^{
            [repo stub:@selector(hasCurrentDistroVersionForBundleID:) andReturn:theValue(NO) withArguments:bundleID];
            [repo stub:@selector(stateForBundleWithID:) andReturn:theValue(ZincBundleStateCloning) withArguments:bundleID];
            [repo stub:@selector(currentDistroVersionForBundleID:) andReturn:theValue(currentVersion) withArguments:bundleID];

            task = [mockFactory mockBundleCloneTaskForBundleID:bundleID version:previousVersion];
            [repo stub:@selector(tasks) andReturn:@[task]];
        });

        it(@"should associate the task when started if it doesn't require current version", ^{
            initializeMonitor(ZincBundleAvailabilityRequirementVersionSpecifierAny);
            [monitor startMonitoring];
            ZincBundleAvailabilityMonitorActivityItem* item = (ZincBundleAvailabilityMonitorActivityItem*)[[monitor items] objectAtIndex:0];
            [[[item operation] should] beIdenticalTo:task];
        });

        it(@"should not associate the task when started if it requires current version", ^{
            initializeMonitor(ZincBundleAvailabilityRequirementVersionSpecifierCatalogOnly);
            [monitor startMonitoring];
            ZincBundleAvailabilityMonitorActivityItem* item = (ZincBundleAvailabilityMonitorActivityItem*)[[monitor items] objectAtIndex:0];
            [[[item operation] should] beNil];
        });
    });
});


SPEC_END
