//
//  requestMoreTime.m
//  TerminateAndEnterBackground
//
//  Created by haoyu3 on 2017/4/7.
//  Copyright © 2017年 JessesWang. All rights reserved.
//

#import "requestMoreTime.h"

/*
 app退出（或切换至后台）后，保证数据保存等耗时操作完成的攻略：
    1、app退出时，保证耗时任务能够完成的方法：
        当app退出时会触发applicationWillTerminate:代理方法,apple官方文档中针对该方法给出的解释是：
            这个方法是用来告诉你的app进程，它将要终结并从内从中释放掉。可以使用该方法为我们的app做一些最终的clean-up操作。例如：释放共享资源、将timer关闭、保存用户数据等。我们月有5秒钟的时间去执行这些操作，然后返回。如果时间到期前仍然没有返回，系统可能杀死进程。
            需要注意的是：文档上讲，系统给了5秒的额外存活时间。这里有个点需要思考：系统从什么时候开始计时？
            这5秒的计时是从applicationWillTerminate:这个delegate method中被回调执行开始的。但是在五秒计时结束前，执行了reurn。那app就会被真正kill掉。不会等到5秒计时结束。
            所以，我们有耗时任务需要执行时，只能以同步方式来执行，换句话来说就是要阻塞住主线程。实际上，虽然系统给设定的时间是5秒，但是如果阻塞住主线程，执行时间会很长。亲测几十秒的延迟是可行的。所以关于这里的结论是：耗时的任务需要在该函数中以同步方式执行，切记使用异步方式执行任务。异步方式会导致任务还未启动，或者未执行完，进程就被杀死。（ex:app被kill掉时的日志上报，需要以同步方式发送日志。否则会出现有时日志能上报成功，有时失败的情形）
            但是我们尽量将需要做的任务控制在5秒内完成。
 
    补充总结：
        当使用阻塞主线程的方式防止app退出时，在debug模式下，不会存在问题。但是在实际环境中（release）下，会产生iOS的看门狗崩溃日志。
    原因：从iOS 4.x开始，退出应用时，应用不会立即终止，而是退到后台。但是，如果你的应用响应不够快，操作系统有可能会终止你的应用，并产生一个崩溃日志。
    实测：在release或者真机上运行时，会收到看门狗崩溃日志。所以我们上面设想的方案是不可取的。
    关于看门狗知识，参考如下链接：
    http://www.jianshu.com/p/ed92082c477f
    http://www.cnblogs.com/qingche/p/5209226.html
 
 
    2、app切换进后台时：
        app切换进入后台时，会触发applicationDidEnterBackground:代理方法，官方文档中给出的说明为：
        有大约5秒的时间在该方法中执行一些任务，例如：释放共享资源、将timer置为无效，保存app的状态信息，使得app重启时能够恢复到当前的状态。另外需要避免在后台使用系统共享资源（例如通讯录），重要的一点是，应该避免在后台时使用OpengGL ES.
        此外还提到一点：如果需要更多的时间（>5s）来执行任务最后的任务，可以通过beginBackgroundTaskWithExpirationHandler:函数来向系统请求更多的时间。完成任务后使用endBackgroundTask:来返回。
        也就是说，当app切换至后台后，不需要也不应该通过阻塞主线程的方式，让app获得额外的后台时间。因为系统提供了对应的api来获得更多的执行时间。
        下面具体说一下这两个方法：
        2.1）- (UIBackgroundTaskIdentifier)beginBackgroundTaskWithExpirationHandler:(void (^)(void))handler;
            参数：当app后台最大运行时间到期后，执行该block。
                    2.1.1）在这个block中需要清空后台任务同时将后台任务置为结束。（若不能明确的结束任务，将导致app终结）
                    2.1.2）这个block会在主线程中同步被调用。
            返回值：为每一个后台任务返回唯一的任务标识identifier，需要将该值传给endBackgroundTask：函数。这两个函数需要成对使用。
 
            这个方法用来在app进入后台时向系统请求更多的执行时间，每一次调用该方法，都需要对称的调用endBackgroundTask:方法。否则系统会在到期前终止app。（关于这一点，系统是如何检验的，并不能知道，但是我们还是应该按照官方文档声明来做）
            这个方法可以被调用多次，但是每个任务结束时，必须分别单独结束。
            总结：
                我们通过调用这个函数像系统请求额外的执行时间，保证主线程和子线程能够继续执行，而不因为app切换到后台而停止掉。
            注意：这个方法可在子线程中被安全调用。
 
        2.2）- (void)endBackgroundTask:(UIBackgroundTaskIdentifier)identifier;
        参数是由beginBackgroundTaskWithExpirationHandler：方法返回的identifier。
        作用：
            同beginBackgroundTaskWithExpirationHandler：对称的调用。
            该函数也可在子线程中被安全调用。
 
    3、单例线程安全：http://www.tuicool.com/articles/MZvqAz
    4、app从启动到运行，所执行的所有函数意思
 
 
 */

@interface requestMoreTime ()
{
    NSUInteger _times;
}
@property (nonatomic, assign) UIBackgroundTaskIdentifier taskFlag;


@end

@implementation requestMoreTime

- (void)beginTask {
    NSLog(@"begin=============");
    self.taskFlag = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        //超时回调的block。10分
        [self endTask];
    }];
}

- (void)endTask {
    NSLog(@"**********结束*******");
    [[UIApplication sharedApplication] endBackgroundTask:self.taskFlag]; //!!!:Wang Haoyu - 成对出现
    self.taskFlag = UIBackgroundTaskInvalid;
}

- (void)doSomeWorkWithTimer:(NSTimer *)timer {
    NSLog(@"一直在执行");
    _times++;
    if(_times == 20) {
        [timer invalidate];
        [self endTask];
    }
}

+ (void)test {
    NSLog(@"xxxxx");
    for (NSInteger i = 0; i< 10000; i++) {
        NSLog(@"====i:%ld",(long)i);
    }
}

- (void)consumeTaskRequestMoreSystemTime {
    
    
    //请求耗时任务
    __weak __typeof__ (self) wself = self;
    self.taskFlag = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        //结束任务：
        //最大时间到期后，执行的block，一般最大时间为10分钟
        if(self.taskFlag != UIBackgroundTaskInvalid) {
            __strong __typeof (wself) sself = wself;
            [[UIApplication sharedApplication] endBackgroundTask:sself.taskFlag];
            sself.taskFlag = UIBackgroundTaskInvalid;
        }
    }];
    
}

@end
