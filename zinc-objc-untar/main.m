//
//  main.m
//  zinc-objc-untar
//
//  Created by Andy Mroczkowski on 3/14/13.
//  Copyright (c) 2013 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSFileManager+ZincTar.h"

static void usage(void)
{
    NSLog(@"zinc-objc-untar <src tar> <dst path>");
}

int main(int argc, const char * argv[])
{
    @autoreleasepool {

        if (argc < 3) {
            usage();
            exit(1);
        }
        
        NSString *srcTar = [NSString stringWithCString:argv[1] encoding:NSUTF8StringEncoding];
        NSString *dstPath = [NSString stringWithCString:argv[2] encoding:NSUTF8StringEncoding];
        
        NSError *error = nil;
        BOOL success = [[NSFileManager defaultManager] zinc_createFilesAndDirectoriesAtPath:dstPath withTarPath:srcTar error:&error];
        
        if (!success) {
            NSLog(@"ERROR: %@", error);
            exit(1);
        }
    }
    return 0;
}

