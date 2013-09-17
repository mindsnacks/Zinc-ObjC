//
//  NSOperationZincSpec.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 9/17/13.
//  Copyright 2013 MindSnacks. All rights reserved.
//

#import "Kiwi.h"
#import "NSOperation+Zinc.h"
#import "ZincOperation+Private.h"

SPEC_BEGIN(NSOperationZincSpec)

describe(@"allDependencies", ^{

    __block NSOperation* theOperation;

    beforeEach(^{
        theOperation = [[NSOperation alloc] init];
    });

    it(@"should return direct dependencies", ^{

        // set up
        NSOperation* dep = [[NSOperation alloc] init];
        [theOperation addDependency:dep];

        // verify
        NSSet* allDeps = [theOperation zinc_allDependencies];
        [[allDeps should] haveCountOf:1];
        [[allDeps should] contain:dep];
    });

    it(@"should return dependencies of direct dependencies", ^{

        // verify
        NSOperation* depOuter = [[NSOperation alloc] init];
        NSOperation* depInner = [[NSOperation alloc] init];
        [depOuter addDependency:depInner];
        [theOperation addDependency:depOuter];

        // set up
        NSSet* allDeps = [theOperation zinc_allDependencies];
        [[allDeps should] haveCountOf:2];
        [[allDeps should] contain:depInner];
        [[allDeps should] contain:depOuter];
    });

    it(@"should return children of dependencies", ^{

        // set up
        ZincOperation* dep = [[ZincOperation alloc] init];
        NSOperation* depChild = [[NSOperation alloc] init];
        [dep addChildOperation:depChild];
        [theOperation addDependency:dep];

        // verify
        NSSet* allDeps = [theOperation zinc_allDependenciesIncludingChildren:YES];
        [[allDeps should] haveCountOf:2];
        [[allDeps should] contain:dep];
        [[allDeps should] contain:depChild];
    });

});

SPEC_END
