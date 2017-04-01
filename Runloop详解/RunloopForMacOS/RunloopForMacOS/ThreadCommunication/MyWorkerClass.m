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
    //
    [[NSThread currentThread] setName:@"HaoyuWorkerThread"];
    //设置当前线程和主线程通信的端口
    NSPort *distantPort = (NSPort *)port;
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
    NSPortMessage *messageObjc = [[NSPortMessage alloc] initWithSendPort:outPort receivePort:myPort components:nil];
    if(messageObjc) {
        uint32_t kCheckinMessage = 1002233;
        [messageObjc setMsgid:kCheckinMessage];
        BOOL sendSuccess = [messageObjc sendBeforeDate:[NSDate date]];
        if(sendSuccess) {
            NSLog(@"发送成功");
        }
    }
    
}

#pragma mark - delegate 

- (void)handlePortMessage:(NSPortMessage *)message {
    NSLog(@"接收到父线程的消息");
}

@end
