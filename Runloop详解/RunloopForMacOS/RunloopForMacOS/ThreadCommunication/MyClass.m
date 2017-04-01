//
//  MyClass.m
//  RunloopModule
//
//  Created by haoyu3 on 2017/3/19.
//  Copyright © 2017年 JessesWang. All rights reserved.
//

#import "MyClass.h"
#import "MyWorkerClass.h"

@interface MyClass ()<NSMachPortDelegate>

@end

@implementation MyClass

- (void)launchThread {
    NSPort *myport = [NSMachPort port];
    if(myport) {
        //让本类持有即将到来的端口消息。
        [myport setDelegate:self];
        //将port添加到当前的runloop
        [[NSRunLoop currentRunLoop] addPort:myport forMode:NSDefaultRunLoopMode];
        //当前线程调起工作线程
        [NSThread detachNewThreadSelector:@selector(LaunchThreadWithPort:) toTarget:[MyWorkerClass new] withObject:myport];
    }
}

#pragma mark - port delegate 

#define kCheckinMessage 1002233

- (void)handlePortMessage:(NSPortMessage *)message {
    NSLog(@"接收到子线程额消息");
    //消息的id
    uint32_t messageID = message.msgid;
    //获取远程端口，也就是工作线程的端口。线程通信需要两个端口？？
    /*
     * 本地线程和远程线程可以使用相同的端口对象进行“单边通信”，（换句话说）一个线程创建的“本地端口对象”成为另一个线程的“远程端口对象”。
     *
     */
    NSPort *distanPort = nil;
    if(messageID == kCheckinMessage) {
        //获取工作线程关联的端口
        distanPort = message.sendPort;
    }
    NSLog(@"工作线程的port===%@",distanPort);
}






@end
