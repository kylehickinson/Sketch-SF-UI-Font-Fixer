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
    @20: @(0.340402),
    @21: @(0.326660),
    @22: @(0.320731),
    @23: @(0.324079),
    @24: @(0.326451),
    @25: @(0.327846),
    @26: @(0.328265),
    @27: @(0.327706),
    @28: @(0.326172),
    @29: @(0.323661),
    @30: @(0.334821),
    @31: @(0.330845),
    @32: @(0.341518),
    @33: @(0.336077),
    @34: @(0.346261),
    @35: @(0.339355),
    @36: @(0.349051),
    @37: @(0.340681),
    @38: @(0.331334),
    @39: @(0.340053),
    @40: @(0.329241),
    @41: @(0.337472),
    @42: @(0.325195),
    @43: @(0.332938),
    @44: @(0.319196),
    @45: @(0.304478),
    @46: @(0.311244),
    @47: @(0.295061),
    @48: @(0.301339),
    @49: @(0.283691),
    @50: @(0.289481),
    @51: @(0.270368),
    @52: @(0.250279),
    @53: @(0.255092),
    @54: @(0.233538),
    @55: @(0.237863),
    @56: @(0.214844),
    @57: @(0.218680),
    @58: @(0.194196),
    @59: @(0.168736),
    @60: @(0.171596),
    @61: @(0.144671),
    @62: @(0.147042),
    @63: @(0.118652),
    @64: @(0.120536),
    @65: @(0.090681),
    @66: @(0.092076),
    @67: @(0.060756),
    @68: @(0.061663),
    @69: @(0.062570),
    @70: @(0.029297),
    @71: @(0.029715),
    @72: @(0.030134),
    @73: @(-0.005092),
    @74: @(-0.005162),
    @75: @(-0.041853),
    @76: @(-0.042411),
    @77: @(-0.042969),
    @78: @(-0.081613),
    @79: @(-0.082659),
    @80: @(-0.083705),
    @81: @(-0.084752)
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

- (void)helper_textStorageDidProcessEditing:(NSNotification *)notification
{
  NSTextStorage *storage = (NSTextStorage *)notification.object;
  
  [[storage copy] enumerateAttributesInRange:NSMakeRange(0, storage.length) options:0 usingBlock:^(NSDictionary<NSString *,id> * _Nonnull attrs, NSRange range, BOOL * _Nonnull stop) {
    if (attrs[NSFontAttributeName]) {
      NSFont *font = attrs[NSFontAttributeName];
      NSString *fontName = font.fontName;
      
      if ([font.familyName hasPrefix:@"SF UI"]) {
        NSMutableDictionary *attributes = [attrs mutableCopy];
        
        if (font.pointSize >= 20 && [fontName hasPrefix:kSFUITextPrefix]) {
          NSString *switchedName = [NSString stringWithFormat:@"%@%@", kSFUIDisplayPrefix, [font.fontName substringFromIndex:kSFUITextPrefix.length]];
          attributes[NSFontAttributeName] = [NSFont fontWithName:switchedName size:font.pointSize] ?: [NSFont fontWithName:[NSString stringWithFormat:@"%@-Regular", kSFUIDisplayPrefix] size:font.pointSize];
        } else if (font.pointSize < 20 && [fontName hasPrefix:kSFUIDisplayPrefix]) {
          NSString *switchedName = [NSString stringWithFormat:@"%@%@", kSFUITextPrefix, [font.fontName substringFromIndex:kSFUIDisplayPrefix.length]];
          attributes[NSFontAttributeName] = [NSFont fontWithName:switchedName size:font.pointSize] ?: [NSFont fontWithName:[NSString stringWithFormat:@"%@-Regular", kSFUITextPrefix] size:font.pointSize];
        }
        
        attributes[NSKernAttributeName] = [KHHelper characterSpacings][@(font.pointSize)];
        [storage setAttributes:attributes range:range];
      }
      
      if ([font.familyName hasPrefix:@"SF Pro"]) {
        NSMutableDictionary *attributes = [attrs mutableCopy];
        
        if (font.pointSize >= 20 && [fontName hasPrefix:kSFProTextPrefix]) {
          NSString *switchedName = [NSString stringWithFormat:@"%@%@", kSFProDisplayPrefix, [font.fontName substringFromIndex:kSFProTextPrefix.length]];
          attributes[NSFontAttributeName] = [NSFont fontWithName:switchedName size:font.pointSize] ?: [NSFont fontWithName:[NSString stringWithFormat:@"%@-Regular", kSFProDisplayPrefix] size:font.pointSize];
        } else if (font.pointSize < 20 && [fontName hasPrefix:kSFProDisplayPrefix]) {
          NSString *switchedName = [NSString stringWithFormat:@"%@%@", kSFProTextPrefix, [font.fontName substringFromIndex:kSFProDisplayPrefix.length]];
          attributes[NSFontAttributeName] = [NSFont fontWithName:switchedName size:font.pointSize] ?: [NSFont fontWithName:[NSString stringWithFormat:@"%@-Regular", kSFProTextPrefix] size:font.pointSize];
        }
        
        attributes[NSKernAttributeName] = [KHHelper characterSpacings][@(font.pointSize)];
        [storage setAttributes:attributes range:range];
      }
    }
  }];
  
  [self helper_textStorageDidProcessEditing:notification];
}

- (void)helper_setAttributedString:(id)arg1
{
  // Dirty hack for beta (41) for now: MSTextLayer is no longer a NSTextStorageDelegate, so it doesnt get called
  // This method is still called however, so we could technically adjust the mutable string here.
  //
  // This DOESNT work on Sketch 40.
  NSMutableAttributedString *storage = [[arg1 attributedString] mutableCopy];
  CGFloat version = [[[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"] floatValue];
  
  if (version >= 41) {
    [storage enumerateAttributesInRange:NSMakeRange(0, storage.length) options:0 usingBlock:^(NSDictionary<NSString *,id> * _Nonnull attrs, NSRange range, BOOL * _Nonnull stop) {
      if (attrs[NSFontAttributeName]) {
        NSFont *font = attrs[NSFontAttributeName];
        NSString *fontName = font.fontName;
        if ([font.familyName hasPrefix:@"SF UI"]) {
          NSMutableDictionary *attributes = [attrs mutableCopy];
          
          if (font.pointSize >= 20 && [fontName hasPrefix:kSFUITextPrefix]) {
            NSString *switchedName = [NSString stringWithFormat:@"%@%@", kSFUIDisplayPrefix, [font.fontName substringFromIndex:kSFUITextPrefix.length]];
            attributes[NSFontAttributeName] = [NSFont fontWithName:switchedName size:font.pointSize] ?: [NSFont fontWithName:[NSString stringWithFormat:@"%@-Regular", kSFUIDisplayPrefix] size:font.pointSize];
          } else if (font.pointSize < 20 && [fontName hasPrefix:kSFUIDisplayPrefix]) {
            NSString *switchedName = [NSString stringWithFormat:@"%@%@", kSFUITextPrefix, [font.fontName substringFromIndex:kSFUIDisplayPrefix.length]];
            attributes[NSFontAttributeName] = [NSFont fontWithName:switchedName size:font.pointSize] ?: [NSFont fontWithName:[NSString stringWithFormat:@"%@-Regular", kSFUITextPrefix] size:font.pointSize];
          }
          
          attributes[NSKernAttributeName] = [KHHelper characterSpacings][@(font.pointSize)];
          [storage setAttributes:attributes range:range];
        }
        
        if ([font.familyName hasPrefix:@"SF Pro"]) {
          NSMutableDictionary *attributes = [attrs mutableCopy];
          
          if (font.pointSize >= 20 && [fontName hasPrefix:kSFProTextPrefix]) {
            NSString *switchedName = [NSString stringWithFormat:@"%@%@", kSFProDisplayPrefix, [font.fontName substringFromIndex:kSFProTextPrefix.length]];
            attributes[NSFontAttributeName] = [NSFont fontWithName:switchedName size:font.pointSize] ?: [NSFont fontWithName:[NSString stringWithFormat:@"%@-Regular", kSFProDisplayPrefix] size:font.pointSize];
          } else if (font.pointSize < 20 && [fontName hasPrefix:kSFProDisplayPrefix]) {
            NSString *switchedName = [NSString stringWithFormat:@"%@%@", kSFProTextPrefix, [font.fontName substringFromIndex:kSFProDisplayPrefix.length]];
            attributes[NSFontAttributeName] = [NSFont fontWithName:switchedName size:font.pointSize] ?: [NSFont fontWithName:[NSString stringWithFormat:@"%@-Regular", kSFProTextPrefix] size:font.pointSize];
          }
          
          attributes[NSKernAttributeName] = [KHHelper characterSpacings][@(font.pointSize)];
          [storage setAttributes:attributes range:range];
        }
      }
    }];
    
    [self helper_setAttributedString:[[NSClassFromString(@"MSAttributedString") alloc] initWithAttributedString:storage]];
  } else {
    [self helper_setAttributedString:arg1];
  }
  
  // Update inspector
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
  id document = [(id<NSObject>)NSClassFromString(@"MSDocument") performSelector:@selector(currentDocument)];
  id inspectorController = [document performSelector:@selector(inspectorController)];
  id currentController = [inspectorController performSelector:@selector(currentController)];
  if ([currentController respondsToSelector:@selector(stackView)]) {
    id stackView = [currentController performSelector:@selector(stackView)];
    if ([stackView respondsToSelector:@selector(sectionViewControllers)]) {
      NSArray *viewControllers = [stackView performSelector:@selector(sectionViewControllers)];
      for (NSViewController *vc in viewControllers) {
        if ([vc isKindOfClass:NSClassFromString(@"MSLayerInspectorViewController")]) {
          NSArray *layers = [vc performSelector:@selector(layerInspectorControllers)];
          for (id layer in layers) {
            if ([layer isKindOfClass:NSClassFromString(@"MSTextLayerSection")]) {
              dispatch_async(dispatch_get_main_queue(), ^{
                [layer performSelector:@selector(reloadData)];
              });
              break;
            }
          }
          break;
        }
      }
    }
  }
#pragma clang diagnostic pop
}

@end

