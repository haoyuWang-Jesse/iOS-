//
//  TimerSource.m
//  RunloopModule
//
//  Created by haoyu3 on 2017/3/31.
//  Copyright © 2017年 JessesWang. All rights reserved.
//

#import "CustomTimerSource.h"

@interface CustomTimerSource ()

@property (nonatomic, strong) NSTimer *myTimer; //此处一定不能为weak

@property (nonatomic, strong) dispatch_source_t mySource;

@end

@implementation CustomTimerSource

#pragma mark - 类方法创建定时器

/*
 NSTimer定时器创建问题：
 1、[NSTimer scheduledTimerWithTimeInterval:<#(NSTimeInterval)#> target:<#(nonnull id)#> selector:<#(nonnull SEL)#> userInfo:<#(nullable id)#> repeats:<#(BOOL)#>
 2、[NSTimer timerWithTimeInterval:<#(NSTimeInterval)#> target:<#(nonnull id)#> selector:<#(nonnull SEL)#> userInfo:<#(nullable id)#> repeats:<#(BOOL)#>]
 3、当然还有invocation方法和block方法，道理是相同的。
 方式1: 会创建一个定时器，并见timer添加到默认的模式下（即：NSDefaultRunloopMode下）
 方式2: 创建一个定时器，但是没有添加到runloop中，需要在创建后手动调用NSRunloop对象的addTimer:forMode:方法
 
 其中userInfo只是timer中的一个存储额外信息的属性。
 
 注意：1、timer会在指定的TimerInterval时间后，启动定时器。因此从这个意义上来讲可以作为<#延迟执行的方法#>来使用。
      2、通过类方法创建的timer不需要手动触发定时器。只有通过默认的初始化方法创建的定时器才需要手动触发定时器。
 */

- (void)setupTimerSource {
    //1、类方法，默认会将定时器添加到runloop。
    /*
    self.myTimer = [NSTimer scheduledTimerWithTimeInterval:15 target:self selector:@selector(handleWithParam:) userInfo:@"timer标识等信息" repeats:YES];
    */
    
    //2、类方法，需要手动将定时器添加到
    
    self.myTimer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(handleWithParam:) userInfo:@"timer标识等信息" repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.myTimer forMode:NSDefaultRunLoopMode];
    
    
    //3、（1）立即执行target指定的selector方法，（2）没有改变时间设置，指定时间到达，依然会调用target指定的selector方法。
    [self.myTimer fire];
}

#pragma mark - 默认方法创建定时器

/*
 默认的定时器创建方法是需要手动添加进runloop，并指定启动时间（如果需要立即执行target指定的selector函数可以使用fire函数或者将FireDate:参数指定为当前时间）
 */

- (void)setupTimerSourceWithdefaultMethod {
    self.myTimer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:1] interval:15 target:self selector:@selector(handleWithParam:) userInfo:@"timer标识等信息" repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.myTimer forMode:NSDefaultRunLoopMode];
    //[self.myTimer fire];
}


#pragma mark - 

- (void)handleWithParam:(NSTimer *)timer {
    NSLog(@"惺惺惜惺惺想寻");
}

#pragma mark - NSTimer 使用中的注意事项

/*
 1、内存问题
    使用NSTimer首当其冲的就是内存问题。因为：timer会对出入的target做retain，而添加进runloop后，runloop对timer也是retain操作。因此会导致被timer持有的target不被释放。
    解决办法：使用invalidate函数，将timer从runloop中移除（也就是停止）。打断runloop对timer的持有。
            同时需要将timer置为nil。打断timer和self的相互持有。
 */

- (void)cancleTimer {
    [self.myTimer invalidate];
    self.myTimer = nil;
    NSLog(@"从runloop中移除后，timer是否还存在：%@",self.myTimer);
}

- (void)dealloc {
    NSLog(@"CustomTimerSource dealloc");
}


/*
 2、NSTimer的精确度问题
    首先要明确的知识点是：timer只是runloop中的一个源。而每次循环只能执行一个事件。所以：
    1、当timer被添加进runloop后，只能等下次循环才能被执行。如果当次循环被阻塞（正在处理耗时操作），定时器就会推迟执行时间。
    2、一个timer注册到runloop后，runloop会为其注册好时间点，例如：10:00,10:10,10:20...,如过到了某个时间点，runloop正在执行很长的任务，则那个时间点的回调就会跳过。是直接就不再执行该回调，而不是延后执行该回调。（即可以这样理解：只有到了某个时间点时，runloop处于waitting状态，这是才会被唤醒执行timer时间，也符合runloop被唤醒的四个条件之一）。
 */

//以上参考文档：http://www.jianshu.com/p/3ccdda0679c1





#pragma mark - 高精确度 dispatch_source_t

/*
 1、dispatch_source_t（Timer事件源）精度很高，系统自动触发，系统级别的源。
    1)需要手动启动。 由于dispatch source必须进行额外的配置才能被使用，dispatch_source_create 函数返回的dispatch source将处于挂起状态，所以配置完成后，需要手动启动
    2）配置dispatch_source有一个重要的环节是：定义一个事件处理器（block或者回调函数）来处理事件（例如timer定时事件等）。使用dispatch_source_set_event_handler或dispatch_source_set_event_handler_f来安装事件处理器。
        2.1）如果”事件处理器“已经在queue中并等待处理已经到达的事件，如果这时又来了一个新事件，dispatch_source会合并这两个事件，事件处理器通常只会看到最新的事件。<#（不过某些类型的dispatch source也能获得已经发生以及合并的事件信息。）#>
        2.2）如果事件处理器已经在处理事件，这时又有新事件到达，dispatch_source会保留这些事件，直到前面的事件处理完成后。然后以新的事件再次提交”事件处理器“到queue中。
        2.3）在”事件处理器“内部：可以从dispatch_source对象中获得事件的信息，函数处理器可以直接使用参数指针，Block则必须自己捕获到dispatch source指针。例如：
        dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, myDescriptor, 0, myQueue);
        dispatch_source_set_event_handler(source, ^{
            //从source中读取事件的信息
            size_t estimated = dispatch_source_get_data(source);
        });
        dispatch_resume(source);
    3)这个source可以取消
 
 2、关于dispatch_suspend和dispatch_resume:
    暂停和继续操作会维持一个“暂停计数”，当执行dispatch_suspend时，会+1，相反执行dispatch_resume时，会-1.
    只有“暂停计数”为0时（即：暂停和继续次数平衡时），dispatch_source才会继续将block提交到指定的队列中去执行。
 当“暂停计数“为0，如果调用dispatch_resume，会导致程序程序crash（报错为：指令错误EXC_BAD_INSTRUCTION）

 3、dispatch_cancle(dispatch_object)
    3.1）安装一个取消处理器：可以在任何时候安装取消处理器，但通常我们在创建dispatch source时就会安装取消处理器。使用 dispatch_source_set_cancel_handler 或 dispatch_source_set_cancel_handler_f 函数来设置取消处理器
    3.2）执行取消后，就无法再被resume。ARC中执行取消后通常就会释放掉，所以，要是想取消后重新开始执行，例如SimaSDK中的使用方式，则需要重新创建source。
    <#取消是一个一步操作，正在被处理的事件，会继续执行完成。在处理完最后的事件之后，dispatch source会执行自己的取消处理器。#>
 
 4、dispatc_source 的其他作用：
    1、从描述符中读取数据
    2、向描述符写入数据
    3、监控文件系统对象
    4、监测信号
    5、监控进程
 5、关于dispatch_source的详细内容，参考一下文档：
    http://blog.csdn.net/nogodoss/article/details/31346207
 */

- (void)setUpDispatchSource {
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    self.mySource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    //开始时间
    dispatch_time_t start = dispatch_time(DISPATCH_TIME_NOW, 3.0*NSEC_PER_SEC);
    //间隔时间
    uint64_t timeInterval = 2.0*NSEC_PER_SEC;
    //1、设置timer
    dispatch_source_set_timer(self.mySource, start, timeInterval, 0);
    //2、设置回调
    dispatch_source_set_event_handler(self.mySource, ^{
        NSLog(@"设置定时器的回调");
    });
    
    //启动timer
    dispatch_resume(self.mySource);
}

- (void)setUpCancle {
    //dispatch_source_cancel(self.mySource);
    dispatch_suspend(self.mySource);
    NSLog(@"source被suspend");
    
}

- (void)setupResume {
    dispatch_resume(self.mySource);
    NSLog(@"source 被resume");
}


@end
