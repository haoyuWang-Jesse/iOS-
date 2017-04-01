//
//  CustomSource.m
//  RunloopModule
//
//  Created by haoyu3 on 2017/3/21.
//  Copyright © 2017年 JessesWang. All rights reserved.
//

#import "CustomSource.h"
#import <CoreFoundation/CoreFoundation.h>
#import <CoreFoundation/CFRunLoop.h>

@interface CustomSource ()

{
    CFRunLoopRef _runloopRef;
    CFRunLoopSourceRef _source;
    CFRunLoopSourceContext _source_context;
}
@property (nonatomic, strong) NSString *haoyuString;

@end

@implementation CustomSource

- (void)createCustomSource {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSLog(@"线程start....");
        //获取当前线程的runloop
        _runloopRef = CFRunLoopGetCurrent();
        //初始化runloopContext
        bzero(&_source_context, sizeof(_source_context));
        //配置基于事件的源
        //1.source被执行是回调的函数
        _source_context.perform = performMethod;
        //2、source被添加到runloop中后的回调函数
        _source_context.schedule = sourceAddedIntoRunloop;
        //3、source从runloop中移除时的回调函数
        _source_context.cancel = sourceRemovedFromRunloop;
        _source_context.info = (__bridge void *)(self.haoyuString);
        //根据sourceContext创建source
        _source = CFRunLoopSourceCreate(NULL, 0, &_source_context);
        //将source添加到当前线程的runloop中去
        CFRunLoopAddSource(_runloopRef, _source, kCFRunLoopDefaultMode);
        
        //开启runloop，第三个参数设置为YES，执行玩一次事件后返回
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 9999999, YES);
        //runloop启动后，会进入到runloop的循环状态。或处于休眠，或在执行任务
        NSLog(@"线程执行完毕");
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if(CFRunLoopIsWaiting(_runloopRef)) {
            NSLog(@"工作线程的runloop处于休眠状态,需要事件来唤醒");
            
            CFRunLoopSourceContext context;
            CFRunLoopSourceGetContext(_source, &context);
            context.info = @"即使输入源已经添加进runloop，仍然可以修改里面的数据配置";
            self.haoyuString = @"aaabbbccc";
            
            
            //添加输入事件（给输入源发送信号）
            CFRunLoopSourceSignal(_source);
            //唤醒线程，线程唤醒后发现有事件需要处理，于是立即处理事件
            CFRunLoopWakeUp(_runloopRef);
        }
        else {
            NSLog(@"工作线程的runloop不处于waittting状态，线程正在处理事件");
            //添加输入事件（给输入源发送信号）
            CFRunLoopSourceSignal(_source);
        }
    });
}

static void performMethod(void *info) {
    NSLog(@"runloop开始处理任务时会调用的函数");
}

void sourceAddedIntoRunloop(void *info, CFRunLoopRef rl, CFRunLoopMode mode) {
    /* !!!:Wang Haoyu -
     通常在该函数中，将sourceContext抛给其他线程。
     其他线程或对象（ex:appdelegate）会使用RunloopContext对象来完成和“输入源”的通信
     */
    NSLog(@"source被添加进runloop中");
    NSString *infoString = (__bridge NSString *)info;
}

void sourceRemovedFromRunloop(void *info, CFRunLoopRef rl, CFRunLoopMode mode) {
    /* !!!:Wang Haoyu -
     通常在该函数中，会通知其他线程，将他们注册的输入源移除掉。因为该输入源在runloop中已被移除，继续持有该输入源已经没有作用。
     */
    NSLog(@"source被从runloop中移除");
    NSString *infoString = (__bridge NSString *)info;
    
}


/*
 思考：其他线程如何给 “被添加到runloop中的输入源” 发送数据？？
    因为在输入源的创建和配置时，已经为其赋完值同时指定好对应的回调函数。当其他线程想给给其传递数据是应该怎么来实现？（其他线程是可以给输入源发送信号，并唤醒runloop。如果不发送新数据，每次都只是执行旧数据）
 */

//参考链接：http://www.jianshu.com/p/4d5b6fc33519
//http://www.cnblogs.com/gatsbywang/p/5555200.html
@end
