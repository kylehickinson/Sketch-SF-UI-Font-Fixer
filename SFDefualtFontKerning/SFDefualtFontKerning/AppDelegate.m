//
//  AppDelegate.m
//  SFDefualtFontKerning
//
//  Created by Kyle Hickinson on 2015-09-20.
//  Copyright © 2015 Kyle Hickinson. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  printf("SF UI Text:\n");
  [self listCharacterSpacingFromPointSize:6 toPointSize:20];
  printf("\n");
  printf("SF UI Display:\n");
  [self listCharacterSpacingFromPointSize:20 toPointSize:82];
  
  self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  self.window.backgroundColor = [UIColor whiteColor];
  self.window.rootViewController = [[UIViewController alloc] init];
  [self.window makeKeyAndVisible];
  
  UILabel *l = [[UILabel alloc] init];
  l.text = @"bbbbbb";
  l.font = [UIFont systemFontOfSize:20.0];
  [l sizeToFit];
  l.frame = (CGRect){ .origin.x = 10.0, .origin.y = 40.0, .size = l.bounds.size };
  [self.window.rootViewController.view addSubview:l];
  
  return YES;
}

- (void)listCharacterSpacingFromPointSize:(NSInteger)minFontSize toPointSize:(NSInteger)maxFontSize
{
  NSMutableDictionary *sizes = [[NSMutableDictionary alloc] init];
  NSString *testString = @"bbbbbb";
  
  // System auto-kerned
  for (NSInteger i = minFontSize; i < maxFontSize; i++) {
    CGSize size = [testString sizeWithAttributes:@{ NSFontAttributeName: [UIFont systemFontOfSize:i] }];
    
    sizes[@(i)] = [[NSMutableDictionary alloc] init];
    sizes[@(i)][@"system"] = [NSValue valueWithCGSize:size];
  }
  
  // Forced font creation of system font (no longer using auto-kerning)
  for (NSInteger i = minFontSize; i < maxFontSize; i++) {
    UIFont *font = [UIFont fontWithName:(i < 20 ? @".SFUIText" : @".SFUIDisplay") size:i];
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:testString attributes:@{ NSFontAttributeName: font, NSKernAttributeName: @0.0 }];
    sizes[@(i)][@"font-name"] = [NSValue valueWithCGSize:[attributedString size]];
  }
  
  // Log work:
  for (NSInteger i = minFontSize; i < maxFontSize; i++) {
    NSDictionary *d = sizes[@(i)];
    CGSize autoKernedSystemSize = [d[@"system"] CGSizeValue];
    CGSize forcedFontCreationSize = [d[@"font-name"] CGSizeValue];
    
    CGFloat diff = forcedFontCreationSize.width - autoKernedSystemSize.width;
    CGFloat requiredSketchCharacterSpacing = -(diff / [testString length]);
    //    NSLog(@"%ld - system: %f vs font-name: %f (diff: %f over %ld characters: %f)", i, autoKernedSystemSize.width, forcedFontCreationSize.width, diff, [testString length], diff / [testString length]);
    printf("%2ld: %f\n", i, requiredSketchCharacterSpacing);
  }
}

@end
