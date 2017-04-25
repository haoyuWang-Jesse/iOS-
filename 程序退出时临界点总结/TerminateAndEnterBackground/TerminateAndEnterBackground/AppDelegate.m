//
//  AppDelegate.m
//  TerminateAndEnterBackground
//
//  Created by haoyu3 on 2017/4/7.
//  Copyright © 2017年 JessesWang. All rights reserved.
//

#import "AppDelegate.h"
#import "requestMoreTime.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    //requestMoreTime *moretime = [requestMoreTime new];
   // [moretime beginTask];
    //[NSTimer scheduledTimerWithTimeInterval:1 target:moretime selector:@selector(doSomeWorkWithTimer:) userInfo:nil repeats:YES];
    
    /*
    NSLog(@"进入后台");
    [requestMoreTime test];
     */
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    //requestMoreTime *moretime = [requestMoreTime new];
    //[NSTimer scheduledTimerWithTimeInterval:1 target:moretime selector:@selector(doSomeWorkWithTimer:) userInfo:nil repeats:YES];
    /*
    NSLog(@"11111");
    //sleep(10);
    NSLog(@"222222");
    for (NSInteger i = 0; i< 100000000; i++) {
        NSLog(@"====i:%ld",(long)i);
    }
     */
}


- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler {
    NSLog(@"下载完成会收到系统回调");
    completionHandler();
}

@end
