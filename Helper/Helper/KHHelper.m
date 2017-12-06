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
#import <AppKit/AppKit.h>

#define let __auto_type const
#define var __auto_type

@interface NSObject (SafePerformSelector)
- (id)performSelectorIfAvailable:(SEL)aSelector;
@end

@implementation NSObject (SafePerformSelector)
- (id)performSelectorIfAvailable:(SEL)aSelector
{
  if ([self respondsToSelector:aSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    return [self performSelector:aSelector];
#pragma clang diagnostic pop
  }
  return nil;
}
@end

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
#pragma clang diagnostic ignored "-Wundeclared-selector"
    SwizzleInstanceMethod([NSClassFromString(@"MSTextLayer") class], @selector(textStorageDidProcessEditing:), @selector(helper_textStorageDidProcessEditing:));
    SwizzleInstanceMethod([NSClassFromString(@"MSTextLayer") class], @selector(setAttributedString:), @selector(helper_setAttributedString:));
#pragma clang diagnostic pop
  });
}

+ (NSDictionary *)characterSpacings
{
  return @{
    // SF UI Text
    @6: @(0.246),
    @7: @(0.223),
    @8: @(0.208),
    @9: @(0.171),
    @10: @(0.12),
    @11: @(0.06),
    @12: @(0),
    @13: @(-0.078),
    @14: @(-0.154),
    @15: @(-0.24),
    @16: @(-0.32),
    @17: @(-0.408),
    @18: @(-0.45),
    @19: @(-0.49),
    // SF UI Display
    @20: @(0.361328),
    @21: @(0.348633),
    @22: @(0.343750),
    @23: @(0.348145),
    @24: @(0.351562),
    @25: @(0.354004),
    @26: @(0.355469),
    @27: @(0.355957),
    @28: @(0.355469),
    @29: @(0.354004),
    @30: @(0.366211),
    @31: @(0.363281),
    @32: @(0.375000),
    @33: @(0.370605),
    @34: @(0.381836),
    @35: @(0.375977),
    @36: @(0.386719),
    @37: @(0.379395),
    @38: @(0.371094),
    @39: @(0.380859),
    @40: @(0.371094),
    @41: @(0.380371),
    @42: @(0.369141),
    @43: @(0.377930),
    @44: @(0.365234),
    @45: @(0.351562),
    @46: @(0.359375),
    @47: @(0.344238),
    @48: @(0.351562),
    @49: @(0.334961),
    @50: @(0.341797),
    @51: @(0.323730),
    @52: @(0.304688),
    @53: @(0.310547),
    @54: @(0.290039),
    @55: @(0.295410),
    @56: @(0.273438),
    @57: @(0.278320),
    @58: @(0.254883),
    @59: @(0.230469),
    @60: @(0.234375),
    @61: @(0.208496),
    @62: @(0.211914),
    @63: @(0.184570),
    @64: @(0.187500),
    @65: @(0.158691),
    @66: @(0.161133),
    @67: @(0.130859),
    @68: @(0.132812),
    @69: @(0.134766),
    @70: @(0.102539),
    @71: @(0.104004),
    @72: @(0.105469),
    @73: @(0.071289),
    @74: @(0.072266),
    @75: @(0.036621),
    @76: @(0.037109),
    @77: @(0.037598),
  };
}

@end

@interface NSObject (MSTextLayerSwizzle)
@end

@implementation NSObject (MSTextLayerSwizzle)

static NSString * const kSFUIDisplayPrefix = @"SFUIDisplay";
static NSString * const kSFUITextPrefix = @"SFUIText";
static NSString * const kSFProDisplayPrefix = @"SFProDisplay";
static NSString * const kSFProTextPrefix = @"SFProText";

- (BOOL)isTextVariant:(NSFont *)font
{
  return [font.fontName hasPrefix:kSFUITextPrefix] || [font.fontName hasPrefix:kSFProTextPrefix];
}

- (BOOL)isDisplayVariant:(NSFont *)font
{
  return [font.fontName hasPrefix:kSFUIDisplayPrefix] || [font.fontName hasPrefix:kSFProDisplayPrefix];
}

- (BOOL)isSFFont:(NSFont *)font
{
  return [self isTextVariant:font] || [self isDisplayVariant:font];
}

- (NSFont *)transformedFont:(NSFont *)font newPrefix:(NSString *)prefix
{
  let oldStyle = [[font.fontName componentsSeparatedByString:@"-"] lastObject];
  let adjustedName = [NSString stringWithFormat:@"%@-%@", prefix, oldStyle];
  let transformedFont = [NSFont fontWithName:adjustedName size:font.pointSize];
  return transformedFont ?: [NSFont fontWithName:[NSString stringWithFormat:@"%@-Regular", prefix] size:font.pointSize];
}

- (void)helper_setAttributedString:(id)arg1
{
  // MSTextLayer is no longer a NSTextStorageDelegate, so `textStorageDidProcessEditing` doesnt get called
  // This method is still called however
  //
  // Sketch 41+
  CGFloat version = [[[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"] floatValue];
  
  if (version < 41) {
    [self helper_setAttributedString:arg1];
    return;
  }
  
  NSMutableAttributedString *storage = [[arg1 attributedString] mutableCopy];
  [storage enumerateAttributesInRange:NSMakeRange(0, storage.length) options:0 usingBlock:^(NSDictionary<NSString *,id> * _Nonnull attrs, NSRange range, BOOL * _Nonnull stop) {
    
    let font = (NSFont *)attrs[NSFontAttributeName];
    if (!font || ![self isSFFont:font]) {
      return;
    }
    
    let attributes = (NSMutableDictionary *)[attrs mutableCopy];
    
    if ([self isTextVariant:font] && font.pointSize >= 20) {
      // Transform to display variant
      let newPrefix = [font.fontName hasPrefix:kSFUITextPrefix] ? kSFUIDisplayPrefix : kSFProDisplayPrefix;
      attributes[NSFontAttributeName] = [self transformedFont:font newPrefix:newPrefix];
    } else if ([self isDisplayVariant:font] && font.pointSize < 20) {
      // Transform to text variant
      let newPrefix = [font.fontName hasPrefix:kSFUIDisplayPrefix] ? kSFUITextPrefix : kSFProTextPrefix;
      attributes[NSFontAttributeName] = [self transformedFont:font newPrefix:newPrefix];
    }
    
    if (font.pointSize > 77) {
      attributes[NSKernAttributeName] = @0.0;
    } else {
      attributes[NSKernAttributeName] = [KHHelper characterSpacings][@(font.pointSize)];
    }
    
    [storage setAttributes:attributes range:range];
  }];
  
  if (version >= 48) {
    // Sketch 48 now includes color profile support, so the API changed a bit!
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    [self helper_setAttributedString:[[NSClassFromString(@"MSAttributedString") alloc] performSelector:@selector(initWithAttributedString:documentColorSpace:) withObject:storage withObject:nil]];
#pragma clang diagnostic pop
  } else {
    [self helper_setAttributedString:[[NSClassFromString(@"MSAttributedString") alloc] initWithAttributedString:storage]];
  }

  // Update inspector
  [self reloadInspector];
}

- (void)reloadInspector
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
  id document = [(id<NSObject>)NSClassFromString(@"MSDocument") performSelector:@selector(currentDocument)];
  id inspectorController = [document performSelectorIfAvailable:@selector(inspectorController)];
  id currentController = [inspectorController performSelectorIfAvailable:@selector(currentController)];
  id stackView = [currentController performSelectorIfAvailable:@selector(stackView)];
  NSArray *viewControllers = [stackView performSelectorIfAvailable:@selector(sectionViewControllers)];
  for (NSViewController *vc in viewControllers) {
    if ([vc isKindOfClass:NSClassFromString(@"MSLayerInspectorViewController")]) {
      NSArray *layers = [vc performSelectorIfAvailable:@selector(layerInspectorControllers)];
      for (id layer in layers) {
        if ([layer isKindOfClass:NSClassFromString(@"MSTextLayerSection")]) {
          dispatch_async(dispatch_get_main_queue(), ^{
            [layer performSelectorIfAvailable:@selector(reloadData)];
          });
          break;
        }
      }
      break;
    }
  }
#pragma clang diagnostic pop
}

@end

