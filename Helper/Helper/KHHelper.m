//
//  KHHelper.m
//  Helper
//
//  Created by Kyle Hickinson on 2016-08-21.
//  Copyright © 2016 Kyle Hickinson. All rights reserved.
//

#import "KHHelper.h"
#import <objc/runtime.h>
#import <Foundation/Foundation.h>

@implementation KHHelper

NS_INLINE void SwizzleInstanceMethod(Class class, SEL originalSelector, SEL swizzledSelector) {
  NSCParameterAssert(class);
  NSCParameterAssert(originalSelector);
  NSCParameterAssert(swizzledSelector);
  
  Method originalMethod = class_getInstanceMethod(class, originalSelector);
  Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
  
  BOOL didAddMethod = class_addMethod(class,
                                      originalSelector,
                                      method_getImplementation(swizzledMethod),
                                      method_getTypeEncoding(swizzledMethod));
  
//  NSLog(@"Swizzle; original = %@, replacement = %@, added = %d", originalMethod, swizzledMethod, didAddMethod);
  
  if (didAddMethod) {
    class_replaceMethod(class,
                        swizzledSelector,
                        method_getImplementation(originalMethod),
                        method_getTypeEncoding(originalMethod));
  } else {
    method_exchangeImplementations(originalMethod, swizzledMethod);
  }
}

+ (KHHelper *)shared
{
  static KHHelper *_shared = nil;
  if (!_shared) {
    _shared = [[KHHelper alloc] init];
  }
  return _shared;
}

- (instancetype)init
{
  if ((self = [super init])) {
    [self hookTextLayers];
  }
  return self;
}

- (void)hookTextLayers
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
#pragma clang diagnostic push
#pragma clang diagnostic push
    SwizzleInstanceMethod([NSClassFromString(@"MSTextLayer") class], @selector(setAttributedString:), @selector(helper_setAttributedString:));
#pragma clang diagnostic pop
  });
}

@end

@interface NSObject (MSTextLayerSwizzle)

- (void)helper_setAttributedString:(id)arg1;

@end

@implementation NSObject (MSTextLayerSwizzle)

- (void)helper_setAttributedString:(id)arg1;
{
  [self helper_setAttributedString:arg1];
  NSLog(@"%@", arg1);
}

@end

