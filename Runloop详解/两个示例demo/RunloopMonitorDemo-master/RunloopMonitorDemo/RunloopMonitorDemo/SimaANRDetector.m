//
//  SimaANRDetector.m
//  RunloopMonitorDemo
//
//  Created by haoyu3 on 2017/3/23.
//  Copyright © 2017年 com.sina. All rights reserved.
//

#import "SimaANRDetector.h"
#import "SimaBackTrace.h"

@interface SimaDetectorModel : NSObject

@property (nonatomic, assign) CFRunLoopActivity currentActivity; //detector线程runloop当前的状态
@property (nonatomic, strong) NSDate *sourceHandleStartDate; //处理自定义事件和source0的时间
@property (nonatomic, strong) NSDate *renderStartDate; //刷新UI的开始时间

@end


@implementation SimaDetectorModel

@end


@interface SimaANRDetector ()

{
    CFRunLoopObserverRef _observer;
//    dispatch_semaphore_t _semaphore;
    NSMutableArray *_backtrace;
}

@property (nonatomic, strong) SimaDetectorModel *detectorModel;
@property (nonatomic, strong) dispatch_semaphore_t semaphore;

@end

@implementation SimaANRDetector

+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    static SimaANRDetector *sharedObject = nil;
    dispatch_once(&onceToken, ^{
        sharedObject = [[SimaANRDetector alloc] init];
    });
    return sharedObject;
}

#pragma mark - private method

//!!!:Wang Haoyu -  需要对activity,source0,renderStatrtDate 做同步操作

static void mainRunloopObserverCallback(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info) {
    
    dispatch_semaphore_t tempSemaphore = [SimaANRDetector shareInstance].semaphore;
    dispatch_semaphore_wait(tempSemaphore, dispatch_time(DISPATCH_TIME_NOW, 3*NSEC_PER_SEC));
    
    
    SimaDetectorModel *detector = [SimaANRDetector shareInstance].detectorModel ?: [SimaDetectorModel new];
    detector.currentActivity = activity;
    //record start time of kCFRunLoopBeforeSources and kCFRunLoopAfterWaiting
    switch (activity) {
        case kCFRunLoopBeforeSources:
        {
            //
            detector.sourceHandleStartDate = [NSDate date];
        }
            break;
        case kCFRunLoopBeforeWaiting:
        {
            //保证所记录的时间是在一次loop之内的计时
            detector.sourceHandleStartDate = nil;
            detector.renderStartDate = nil;
        }
            break;
        case kCFRunLoopAfterWaiting:
        {
            //
            detector.renderStartDate = [NSDate date];
        }
            break;
        default:
            break;
    }
    dispatch_semaphore_signal(tempSemaphore);
    NSLog(@"当前的activity===%lu",activity);
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
    [self setUpModel];
    //create monitor thread
    [self createDetectorThread];
}

- (void)setUpModel {
    self.semaphore = dispatch_semaphore_create(1);
    self.detectorModel = [SimaDetectorModel new];
}

- (void)removeMonitor {
    if (!_observer) { return; }
    CFRunLoopRemoveObserver(CFRunLoopGetMain(), _observer, kCFRunLoopCommonModes);
    CFRelease(_observer);
    _observer = NULL;
}

- (void)createDetectorThread {
    NSThread *detectorThread = [[NSThread alloc] initWithTarget:self selector:@selector(configureDetectorThread) object:nil];
    [detectorThread setName:@"SimaDetectorThread"];
    if([detectorThread respondsToSelector:@selector(setQualityOfService:)]) { //iOS 8.0+
        detectorThread.qualityOfService = NSQualityOfServiceUserInitiated; //setting priority
    }
    [detectorThread start];
}

- (void)configureDetectorThread {
    NSRunLoop *currentRunloop = [NSRunLoop currentRunLoop];
    NSTimer *timer = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(detectorMainThread) userInfo:nil repeats:YES];
    [currentRunloop addTimer:timer forMode:NSDefaultRunLoopMode];
    [currentRunloop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
}

#pragma mark - detector main thread 

- (void)detectorMainThread {
    NSLog(@"后台常驻线程调用该方法");
    //开始检测主线程
    long semphoreTimeOut = dispatch_semaphore_wait(self.semaphore, 3*NSEC_PER_SEC);
    if(semphoreTimeOut != 0) {
        NSLog(@"超时");
    }
    SimaDetectorModel *tempModel = self.detectorModel;
    dispatch_semaphore_signal(self.semaphore);
    //检测主线程
    CFRunLoopActivity activity = tempModel.currentActivity;
    double sourceTimeInterval = 0.0; double renderTimeInterval = 0.0;
    if(activity == kCFRunLoopBeforeSources && tempModel.sourceHandleStartDate) {
        sourceTimeInterval = [[NSDate date] timeIntervalSince1970] - [tempModel.sourceHandleStartDate timeIntervalSince1970];
    }
    if(activity == kCFRunLoopAfterWaiting && tempModel.renderStartDate) {
        renderTimeInterval = [[NSDate date] timeIntervalSince1970] - [tempModel.renderStartDate timeIntervalSince1970];
    }
    
    if((sourceTimeInterval > 2) || (renderTimeInterval > 2)) { // 主线程Runloop执行超过两秒则进行检测
        NSString *backtrace = [SimaBackTrace bs_backtraceOfMainThread];
        NSLog(@"检测到卡顿，主线程的堆栈是=====%@",backtrace);
        NSLog(@"具体卡段的时间====source0:%f :render:%f ",sourceTimeInterval,renderTimeInterval);
    }
    
    
}

@end
