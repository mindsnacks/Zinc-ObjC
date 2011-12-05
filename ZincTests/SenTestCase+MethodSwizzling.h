
// from https://gist.github.com/1038034

#import <SenTestingKit/SenTestingKit.h>

@interface SenTestCase (MethodSwizzling)

- (void)swizzleMethod:(SEL)aOriginalMethod
              inClass:(Class)aOriginalClass
           withMethod:(SEL)aNewMethod
            fromClass:(Class)aNewClass
         executeBlock:(void (^)(void))aBlock;

@end