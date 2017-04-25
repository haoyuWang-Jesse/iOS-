//
//  requestMoreTime.m
//  TerminateAndEnterBackground
//
//  Created by haoyu3 on 2017/4/7.
//  Copyright © 2017年 JessesWang. All rights reserved.
//

#import "requestMoreTime.h"



/*
 IOS提供了以下多中方式处理后台任务
 
 一：beginBackgroundTaskWithExpirationHandler
 
 二：特定任务的后台处理
 
 三：后台获取
 
 四：推送唤醒
 
 五：后台传输
 
 其中后面3种方式IOS7之后才支持
 */

/*
 一：
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
        2.3：必须使用的endBackgroundTask结束任务的原因：当最大限制时间到期时，如果任务还没有执行完成，系统会强制结束任务，会触发看门狗超时等机制。所以需要主动去结束任务。
 
    参考链接：https://onevcat.com/2013/08/ios7-background-multitask/
 
    3、单例线程安全：http://www.tuicool.com/articles/MZvqAz
    4、app从启动到运行，所执行的所有函数意思
 
 */

/*
 二：特定任务的后台处理
例如：地图。语音，网络电话等
 */

/*
 三、后台获取
  iOS7后新增内容，他的核心作用是：设定一个间隔，然后每隔一段时间唤醒应用处理相应地任务，比如我们使用的社交软件，可以每个一定时间获取最新的信息，这样下次我们进入后就不需要等待刷新。
 */

/*
 四、推送唤醒
 */

/*
 五、后台传输
 iOS 7 后，系统提供了NSURLSession
 1）当加入了多个Task，程序没有切换到后台。
 这种情况Task会按照NSURLSessionConfiguration的设置正常下载，不会和ApplicationDelegate有交互。
 
 2）当加入了多个Task，程序切到后台，所有Task都完成下载。
 
 在切到后台之后，Session的Delegate不会再收到，Task相关的消息，直到所有Task全都完成后，系统会调用ApplicationDelegate的application:handleEventsForBackgroundURLSession:completionHandler:回调，之后“汇报”下载工作，对于每一个后台下载的Task调用Session的Delegate中的URLSession:downloadTask:didFinishDownloadingToURL:（成功的话）和URLSession:task:didCompleteWithError:（成功或者失败都会调用）。
 
 之后调用Session的Delegate回调URLSessionDidFinishEventsForBackgroundURLSession:。
 注意：在ApplicationDelegate被唤醒后，会有个参数ComplietionHandler，这个参数是个Block，这个参数要在后面Session的Delegate中didFinish的时候调用一下，如下：
 3）当加入了多个Task，程序切到后台，下载完成了几个Task，然后用户又切换到前台。（程序没有退出）
 　　
 切到后台之后，Session的Delegate仍然收不到消息。在下载完成几个Task之后再切换到前台，系统会先汇报已经下载完成的Task的情况，然后继续下载没有下载完成的Task，后面的过程同第一种情况。
 
 4）当加入了多个Task，程序切到后台，几个Task已经完成，但还有Task还没有下载完的时候关掉强制退出程序，然后再进入程序的时候。（程序退出了）
 
 最后这个情况比较有意思，由于程序已经退出了，后面没有下完Session就不在了后面的Task肯定是失败了。但是已经下载成功的那些Task，新启动的程序也没有听“汇报”的机会了。经过实验发现，这个时候之前在NSURLSessionConfiguration设置的NSString类型的ID起作用了，当ID相同的时候，一旦生成Session对象并设置Delegate，马上可以收到上一次关闭程序之前没有汇报工作的Task的结束情况（成功或者失败）。但是当ID不相同，这些情况就收不到了，因此为了不让自己的消息被别的应用程序收到，或者收到别的应用程序的消息，起见ID还是和程序的Bundle名称绑定上比较好，至少保证唯一性。
 */

/*
 问题：1、下载时可以在下载失败后，根据保存的内容，恢复上次下载，其实就是类似于断点续传的原理。但是上传时，杀掉app导致上传失败，下次在启动时能够恢复吗？要上传的数据会被系统保存下来吗？
    2、断点续传和后台传输，在后台传输的情况下进行断点续传？？
    3、completionHandler什么时间调用。
 参考链接：
    1、http://www.cnblogs.com/biosli/p/iOS_Network_URL_Session.html  下面的问题值得思考，总结
    2、http://www.cocoachina.com/ios/20160503/16053.html
 
    恢复下载失败的参考：https://forums.developer.apple.com/thread/24770
 */


@interface requestMoreTime () <NSURLSessionDownloadDelegate,NSURLSessionDelegate>
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
        //结束任务：主动结束任务是为了，不让系统杀掉app，触发看门狗超时崩溃
        //在主线程中回调：在主线程中同步清空任务。
        //最大时间到期后，执行的block，一般最大时间为10分钟
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if(self.taskFlag != UIBackgroundTaskInvalid) {
                __strong __typeof (wself) sself = wself;
                //do some clean up work
                [[UIApplication sharedApplication] endBackgroundTask:sself.taskFlag];
                sself.taskFlag = UIBackgroundTaskInvalid;
            }
        });
    }];
    
}


#pragma mark - 

- (NSURLSession*)backgroundSession {
    NSString *uniqueID = @"backgroundSessionID";
    NSURLSessionConfiguration *configureObjc = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:uniqueID];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configureObjc delegate:self delegateQueue:nil];
    return session;
}

- (NSURLSession*)defaultSession {
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
    return session;
}

- (void)beginDownload {
    NSString *URLString = @"http://dlsw.baidu.com/sw-search-sp/soft/9d/25765/sogou_mac_32c_V3.2.0.1437101586.dmg";
    NSURL *downloadUrl = [NSURL URLWithString:URLString];
    NSURLRequest *request = [NSURLRequest requestWithURL:downloadUrl];
    NSURLSession *session = [self backgroundSession];
    NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithRequest:request];
    [downloadTask resume];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    NSLog(@"taskID:%ld,download=====%@",(long)downloadTask.taskIdentifier,[location absoluteString]);
}


- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if(error) {
        NSLog(@"taskID:%ld  error:======%@",(long)task.taskIdentifier,error.localizedDescription);
        NSData *data= error.userInfo[NSURLSessionDownloadTaskResumeData];
        if([self __isValidResumeData:data]) {
            NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithResumeData:data];
            [downloadTask resume];
        }
    }
    else {
        NSLog(@"======下载完成");
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
   NSString *progressText = [NSString stringWithFormat:@"下载进度:%f",(double)totalBytesWritten/totalBytesExpectedToWrite];
    NSLog(@"taskID:%ld, 进度======%@",(long)downloadTask.taskIdentifier,progressText);
}

//仔细看会发现回调的方法里面并没用NSData传回来，多了一个location，顾名思义，location就是下载好的文件写入沙盒的地址，打印一下发现下载好的文件被自动写入的temp文件夹下面了
//不过在下载完成之后会自动删除temp中的文件，所有我们需要做的只是在回调中把文件移动(或者复制，反正之后会自动删除)到caches中。


- (BOOL)__isValidResumeData:(NSData *)data{
    if (!data || [data length] < 1) return NO;
    
    NSError *error;
    NSDictionary *resumeDictionary = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:NULL error:&error];
    if (!resumeDictionary || error) return NO;
    
    NSString *resumeDataFileName = resumeDictionary[@"NSURLSessionResumeInfoTempFileName"];
    NSString *newTempPath = NSTemporaryDirectory();
    NSString *newResumeDataPath = [newTempPath stringByAppendingPathComponent:resumeDataFileName];
    [resumeDictionary setValue:newResumeDataPath forKey:@"NSURLSessionResumeInfoLocalPath"];
    
    
    
    
    NSString *localTmpFilePath = [resumeDictionary objectForKey:@"NSURLSessionResumeInfoLocalPath"];
    if ([localTmpFilePath length] < 1) return NO;
    
    BOOL result = [[NSFileManager defaultManager] fileExistsAtPath:localTmpFilePath];
    
    if (!result) {
        NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
        NSString *localName = [localTmpFilePath lastPathComponent];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *cachesDir = [paths objectAtIndex:0];
        NSString *localCachePath = [[[cachesDir stringByAppendingPathComponent:@"com.apple.nsurlsessiond/Downloads"]stringByAppendingPathComponent:bundleIdentifier]stringByAppendingPathComponent:localName];
        result = [[NSFileManager defaultManager] moveItemAtPath:localCachePath toPath:localTmpFilePath error:nil];
    }
    return result;
}

@end
