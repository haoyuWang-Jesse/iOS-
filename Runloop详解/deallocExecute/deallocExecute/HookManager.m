//
//  HookManager.m
//  deallocExecute
//
//  Created by haoyu3 on 2017/3/20.
//  Copyright © 2017年 JessesWang. All rights reserved.
//

#import "HookManager.h"

@implementation HookManager

//+ (instancetype)shareInstance {
//    static dispatch_once_t onceToken;
//    static HookManager *sharedObject = nil;
//    dispatch_once(&onceToken, ^{
//        sharedObject = [[HookManager alloc] init];
//    });
//    return sharedObject;
//}

+ (instancetype)shareInstance {
    static HookManager *singleton = nil;
    if (! singleton) {
        singleton = [[self alloc] init];
    }
    return singleton;
}

- (void)registerNetWorkHook {
    NSLog(@"执行了调用");
}

- (void)dealloc {
    NSLog(@"HookManager dealloc");
}

/*
 此时dealloc不会执行：
    static声明的静态变量：
    1、全局静态变量：
    2、局部静态变量：存储于全局数据区，直到程序运行结束。作用域：局部作用域。
 
 所以：self对象不会被释放，直到程序运行结束。
 
 */

@end
