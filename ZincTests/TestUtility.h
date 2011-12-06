
#import <Foundation/Foundation.h>

#define TEST_RESOURCE_ROOT @"Data"
#define TEST_WAIT_UNTIL_TRUE_SLEEP_SECONDS (0.25)

#define TEST_RESOURCE_ROOT_PATH \
[[[NSBundle bundleForClass:[self class]] resourcePath] stringByAppendingPathComponent:TEST_RESOURCE_ROOT]

#define TEST_RESOURCE_PATH(name) \
[[[[NSBundle bundleForClass:[self class]] resourcePath] \
  stringByAppendingPathComponent:TEST_RESOURCE_ROOT] \
 stringByAppendingPathComponent:name]


#define TEST_TMP_PATH(name, ext) \
[NSTemporaryDirectory() stringByAppendingPathComponent: \
[[NSString stringWithFormat:@"%@_%@", NSStringFromSelector(_cmd), name] \
stringByAppendingPathExtension:ext]]


#define TEST_TMP_URL(name, ext) \
[NSURL fileURLWithPath:TEST_TMP_PATH(name, ext)]


#define TEST_TMP_DIR_PATH(name) \
[NSTemporaryDirectory() stringByAppendingPathComponent: \
[NSString stringWithFormat:@"%@_%@", NSStringFromSelector(_cmd), name]]

#define TEST_CREATE_TMP_DIR(name) \
_TestCreateTmpDir(TEST_TMP_DIR_PATH(name))

#define TEST_WAIT_UNTIL_TRUE(expr) \
while( (expr) == NO ) [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:TEST_WAIT_UNTIL_TRUE_SLEEP_SECONDS]];


static inline NSString* _TestCreateTmpDir(NSString* path)
{
    [[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
    [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:NULL];
    return path;
}
