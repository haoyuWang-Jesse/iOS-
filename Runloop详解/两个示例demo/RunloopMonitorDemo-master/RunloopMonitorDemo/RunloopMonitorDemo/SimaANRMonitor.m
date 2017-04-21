//
//  SimaANRMonitor.m
//  RunloopMonitorDemo
//
//  Created by haoyu3 on 2017/3/22.
//  Copyright © 2017年 com.sina. All rights reserved.
//

#import "SimaANRMonitor.h"
#import <libkern/OSAtomic.h>
#import <execinfo.h>
#import "SimaBackTrace.h"

@interface SimaANRMonitor ()

{
    CFRunLoopObserverRef _observer;
    dispatch_semaphore_t _semaphore;//用来超时
    
}

@property (nonatomic, assign) NSInteger countTime;//超时次数
@property (nonatomic, assign) CFRunLoopActivity currentActivity; //主线程Runloop当前的状态
@property (nonatomic, strong) dispatch_semaphore_t activitySemphore;//同步currentActivity变量的semphore

@end

@implementation SimaANRMonitor

+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    static SimaANRMonitor *sharedObject = nil;
    dispatch_once(&onceToken, ^{
        sharedObject = [[SimaANRMonitor alloc] init];
    });
    return sharedObject;
}

#pragma mark - private method

static void mainRunloopObserverCallback(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info) {
    //保存当前的runloop状态（添加线程同步保护）
    dispatch_semaphore_t tempSemaphore = [SimaANRMonitor shareInstance].activitySemphore;
    dispatch_semaphore_wait(tempSemaphore, dispatch_time(DISPATCH_TIME_NOW, 3*NSEC_PER_SEC));
    SimaANRMonitor *monitor = [SimaANRMonitor shareInstance];
    monitor.currentActivity = activity;
    dispatch_semaphore_signal(tempSemaphore);
    // 发送信号
    dispatch_semaphore_t semaphore = monitor->_semaphore;
    dispatch_semaphore_signal(semaphore);
}

#pragma makr - observer in main thread runloop

- (void)registerMonitor {
    CFRunLoopObserverContext context = {0,(__bridge void*)self,NULL,NULL};
    _observer = CFRunLoopObserverCreate(kCFAllocatorDefault,
                                        kCFRunLoopAllActivities,
                                        YES,
                                        0,
                                        &mainRunloopObserverCallback,
                                        &context);
    CFRunLoopAddObserver(CFRunLoopGetMain(), _observer, kCFRunLoopCommonModes);
    //init semphore
    [self setUpSemphore];
    //create monitor thread
    [self createMonitorThread];
}

- (void)removeMonitor {
    if (!_observer) { return; }
    CFRunLoopRemoveObserver(CFRunLoopGetMain(), _observer, kCFRunLoopCommonModes);
    CFRelease(_observer);
    _observer = NULL;
}

- (void)setUpSemphore {
    _semaphore = dispatch_semaphore_create(0);
    self.activitySemphore = dispatch_semaphore_create(1);
}

#pragma makr - create monitor thread

- (void)createMonitorThread {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        while (YES) {
            long semphoreTimeOut = dispatch_semaphore_wait(_semaphore, dispatch_time(DISPATCH_TIME_NOW, 100*NSEC_PER_MSEC));
            if(semphoreTimeOut != 0) { //返回值不为0，在超时前该线程未被唤醒，只统计超过50ms未被唤醒的情况
                
                dispatch_semaphore_wait(self.activitySemphore, dispatch_time(DISPATCH_TIME_NOW, 3*NSEC_PER_SEC));
                CFRunLoopActivity tempActivity = self.currentActivity;//!!!:Wang Haoyu - 同步操作,死锁预防
                dispatch_semaphore_signal(self.activitySemphore);
                
                if(tempActivity == kCFRunLoopBeforeSources || tempActivity == kCFRunLoopAfterWaiting) {
                    if(++self.countTime < 5) { //连续5次超时（超时时间为50ms），即认为卡顿
                        continue;
                    }
                    NSLog(@"检测到线程卡顿：%@",[SimaBackTrace bs_backtraceOfMainThread]);
                }
            }
            self.countTime = 0;//未满5次超时（或未超时）重置。
        }
    });
}


@end
