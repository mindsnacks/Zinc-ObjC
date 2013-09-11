//
//  ZincMockFactory.h
//  Zinc-ObjC
//
//  Created by Andy Mroczkowski on 9/10/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ZincTaskRef.h"

@interface ZincTaskRefDummy : ZincTaskRef

@property (nonatomic, assign) BOOL isFinished;
@property (nonatomic, assign) BOOL isValid;

@end
