//
//  SimaBackTrace.h
//  RunloopMonitorDemo
//
//  Created by haoyu3 on 2017/3/22.
//  Copyright © 2017年 com.sina. All rights reserved.
//

#import <Foundation/Foundation.h>

#define BSLOG NSLog(@"%@",[SimaBackTrace bs_backtraceOfCurrentThread]);
#define BSLOG_MAIN NSLog(@"%@",[SimaBackTrace bs_backtraceOfMainThread]);
#define BSLOG_ALL NSLog(@"%@",[SimaBackTrace bs_backtraceOfAllThread]);

@interface SimaBackTrace : NSObject

+ (NSString *)bs_backtraceOfAllThread;
+ (NSString *)bs_backtraceOfCurrentThread;
+ (NSString *)bs_backtraceOfMainThread;
+ (NSString *)bs_backtraceOfNSThread:(NSThread *)thread;

@end
