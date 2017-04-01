//
//  MyWorkerClass.m
//  RunloopModule
//
//  Created by haoyu3 on 2017/3/19.
//  Copyright © 2017年 JessesWang. All rights reserved.
//

#import "MyWorkerClass.h"

@interface MyWorkerClass ()<NSMachPortDelegate>

@property (nonatomic, strong) NSPort *remotePort;

@end

@implementation MyWorkerClass


- (void)LaunchThreadWithPort:(id)port {
    //设置当前线程和主线程通信的端口
    NSPort *distantPort = (NSPort *)port;
    self.remotePort = distantPort;
    
    //初始化当前当前类的对象
    MyWorkerClass *work = [MyWorkerClass new];
    //给主线程发送消息
    [work sendMessageToOtherThread:distantPort];
    //启动当前线程的runloop
    [[NSRunLoop currentRunLoop] run];
    
}

//private method
- (void)sendMessageToOtherThread:(NSPort *)outPort {
    self.remotePort = outPort;
    //创建工作线程自己的端口并绑定工作线程
    NSPort* myPort = [NSMachPort port];
    [myPort setDelegate:self];
    [[NSRunLoop currentRunLoop] addPort:myPort forMode:NSDefaultRunLoopMode];
    //创建签到消息
    NSString *targetString = @"this a string";
    NSData *data = [targetString dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableArray *mutableArray = [@[data,] mutableCopy];
    
    uint32_t kCheckinMessage = 1002233;
    [self.remotePort sendBeforeDate:[NSDate date]
                              msgid:kCheckinMessage
                         components:mutableArray
                               from:myPort
                           reserved:0];
    
}

/*
 2）关于components这个参数传值类型的问题：
 NSMutableArray *array = [NSMutableArray arrayWithArray:@[mainPort,data]];
 作者在这困惑了好一会。。之前我是往数组里添加的是String或者其他类型的对象，但是发现参数传过去之后，变成nil了。
 从这段描述中我们可以看出，这个传参数组里面只能装两种类型的数据，一种是NSPort的子类，一种是NSData的子类。所以我们如果要用这种方式传值必须得先把数据转成NSData类型的才行。
 */

@end
