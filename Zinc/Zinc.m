//
//  Zinc.m
//  Zinc
//
//  Created by Andy Mroczkowski on 12/5/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import "Zinc.h"
#import <sys/xattr.h> // for AddSkipBackupAttributeToFile

 void ZincAddSkipBackupAttributeToFile(NSURL * url)
{
    u_int8_t b = 1;
    setxattr([[url path] fileSystemRepresentation], "com.apple.MobileBackup", &b, 1, 0, 0);
}

NSString* ZincGetApplicationDocumentsDirectory(void)
{
    NSString* dir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    if([dir length] == 0) {
        [NSException raise:@"Documents dir not found"
                    format:@"NSSearchPathForDirectoriesInDomains returned an empty dir"];
    }
    return dir;
}


NSString* const ZincEventNotification = @"ZincEventNotification";