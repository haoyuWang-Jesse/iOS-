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

#define kCheckinMessage 100

- (void)handlePortMessage:(id)message {
    NSLog(@"接收到子线程传递的消息=====%@",message);
    //消息的id
//      NSUInteger msgId = [[message valueForKeyPath:@"msgid"] integerValue];
    //只能用KVC的方式取值
    NSArray *array = [message valueForKeyPath:@"components"];
    NSMachPort *localPort = [message valueForKeyPath:@"localPort"];
    NSMachPort *remotePort = [message valueForKeyPath:@"remotePort"];
    
    NSData *data =  array[0];
    NSString *s1 = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"%@",s1);

}


//- (void)handleMachMessage:(void *)msg {
//    NSLog(@"收到另一条线程发送来的消息=======%@",msg);
//}

/*
 使用NSMachPort进行线程间通信
    1、其中NSPortMessage是定义在Mac OS中的，并未在iOS文档中声明。
    2、代理方法会执行回调，但是不能够从NSPortMessage中取到任何信息，如果您有好办法，请联系我。@QQ:1223556769
    补充：已经想到解决办法：基于KVC机制，使用id类型来获取对应的值。
    即需要注意两点：
    1）- (void)handlePortMessage:(id)message这里这个代理的参数，从.h里去复制过来的为NSPortMessage类型的一个对象，但是我们发现苹果只是在.h中@class进来，我们无法调用它的任何方法。所以我们用id声明，然后通过KVC去取它的属性。
    2）关于components参数的传值的问题。见MyWorkClass类。

 */


#pragma mark - iOS进程间通信

//参考地址：http://blog.csdn.net/yxh265/article/details/51483822

@end
