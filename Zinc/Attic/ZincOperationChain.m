//
//  ZincOperationChain.m
//  Zinc-iOS
//
//  Created by Andy Mroczkowski on 1/9/12.
//  Copyright (c) 2012 MindSnacks. All rights reserved.
//

#import "ZincOperationChain.h"

@interface ZincOperationChain ()
@property (nonatomic, retain) NSMutableArray* operations;
@end

@implementation ZincOperationChain

@synthesize operations = _operations;

- (id)init
{
    self = [super init];
    if (self) {
        self.operations = [NSMutableArray array];
    }
    return self;
}

- (void)dealloc
{
    self.operations = nil;
    [super dealloc];
}

- (void) addOperation:(NSOperation*)operation title:(NSString*)title passFailBlock:(ZincPassFailBlock)block
{
    NSOperation* lastOp = [self.operations lastObject];
    [self.operations addObject:operation];
    if (lastOp != nil) {
        [operation addDependency:operation];
    }
    
}

- (NSArray*) operations
{
    return [NSArray arrayWithArray:self.operations];
}

@end
