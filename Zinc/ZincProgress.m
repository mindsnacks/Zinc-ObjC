//
//  ZincProgress.m
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 9/9/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincProgress.h"


float ZincProgressCalculate(id<ZincProgress> progress)
{
    long long max = [progress maxProgressValue];
    if (max > 0) {
        long long cur = [progress currentProgressValue];
        return (float)cur / max;
    }
    return 0.0f;
}