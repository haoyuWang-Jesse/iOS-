//
//  AppDelegate.m
//  RunLoopDemo04
//
//  Created by Harvey on 2016/12/15.
//  Copyright © 2016年 Haley. All rights reserved.
//

#import "AppDelegate.h"
#import "CrashHandler.h"
#import <Bugly/Bugly.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

void HandleException123 (NSException *exception)
{
    // 获取异常的堆栈信息
    NSArray *callStack = [exception callStackSymbols];
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    NSException *customException = [NSException exceptionWithName:[exception name] reason:[exception reason] userInfo:userInfo];
    NSLog(@"=======%@",[exception reason]);

}


void SignalHandler11 (int signal) {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *doc = [NSString stringWithFormat:@"%@/otherCrash.txt",[paths objectAtIndex:0]];
    NSString *content = [NSString stringWithFormat:@"third signal crash:reason %d",signal];
    
    BOOL isSuccess = [(NSData *)content writeToFile:doc atomically:YES];
    if(isSuccess) {
        NSLog(@"写入成功");
    }
    
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
     [Bugly startWithAppId:@"4830270eb0"];
    
    NSSetUncaughtExceptionHandler(&HandleException123);
    
    signal(SIGABRT, SignalHandler11);
    signal(SIGILL, SignalHandler11);
    signal(SIGSEGV, SignalHandler11);
    signal(SIGFPE, SignalHandler11);
    signal(SIGBUS, SignalHandler11);
    signal(SIGPIPE, SignalHandler11);
    
    //[CrashHandler sharedInstance];
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
