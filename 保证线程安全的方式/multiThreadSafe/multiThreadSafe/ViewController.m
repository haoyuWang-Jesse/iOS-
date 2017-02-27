//
//  ViewController.m
//  multiThreadSafe
//
//  Created by haoyu3 on 2017/2/22.
//  Copyright © 2017年 JessesWang. All rights reserved.
//

#import "ViewController.h"
#import <pthread/pthread.h>
#import <libkern/OSAtomic.h>

@interface ViewController ()

@property (nonatomic, strong) NSString *testString;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //[self lock_synchronized];
//    [self lock_dispatch_semaphore];
//    [self lock_NSLock];
//    [self lock_NSRecursiveLock];
//    [self lock_NSConditionLock];
//    [self lock_NSCondition];
//    [self lock_NSCondition2];
//    [self lock_pthread_mutex];
//    [self pthread_mutex_recursive_lock];
//    [self OSSpinLock];
    
    [self dispatch_barrier_sync_use];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - @synchronized

/**
 1、@synchronized(obj)中的obj为该锁的唯一标识，只有当标识相同时，才为满足互斥，如果线程2中的@synchronized(obj)改为@synchronized(self),刚线程2就不会被阻
 2、@synchronized指令实现锁的优点就是我们不需要在代码中显式的创建锁对象，便可以实现锁的机制，但作为一种预防措施，@synchronized块会《隐式的添加一个异常处理例程》来保护代码，该处理例程会在异常抛出的时候自动的释放互斥锁。所以如果不想让隐式的异常处理例程带来额外的开销，你可以考虑使用锁对象
 */
- (void)lock_synchronized {
    NSObject *objc = [NSObject new];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @synchronized (objc) {
            NSLog(@"同步操作-----1");
            sleep(3);
//            NSString *string1 = nil;
//            NSDictionary *dic = @{@"aa":string1}; //异常处理机制：遇到异常，会自动释放锁，不会造成阻塞。
            NSLog(@"同步操作-----2");
        }
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        sleep(1);//保证线程2的代码后执行
        @synchronized (objc) {
            NSLog(@"同步操作----3");//这一步代码，最终是在3秒后开始执行
        }
    });
}

#pragma mark - dispatch_semaphore


/**
 1、dispatch_semaphore是GCD用来同步的一种方式，与他相关的共有三个函数，分别是dispatch_semaphore_create、dispatch_semaphore_signal，dispatch_semaphore_wait。
 2、dispatch_semaphore_signal函数会使信号的值加1.
 3、dispatch_semaphore_wait函数会判断信号量的值是否>0,如果>0,则执行它下面的代码，如果=0（注意不会出现<0的状况）,则阻塞当前线程等待timeout.
    3.1 如果等待的期间dispatch_semaphore的值被dispatch_semaphore_signal函数加1了，且该函数（即dispatch_semaphore_wait）所处线程获得了信号量，那么就继续向下执行并将信号量减1。
    3.2 如果等待期间没有获取到信号量或者信号量的值一直为0，那么等到timeout时，其所处线程自动执行其后语句。
 4、问题：阻塞的时间并不准确？下面的代码中，理论上结果应该是：123，但实际确实132
    (1) 如果有多条线程处于阻塞状态，会怎样执行？？？？？？
 
    (2) 如果处于等待的线程，超时时间到时，正好正在执行的线程也处于执行中，会如何执行？？？
        cpu实际上不会真正的实现并行，微观上还是串行执行任务。结果是：会执行处于阻塞状态的线程。
 */
- (void)lock_dispatch_semaphore {
    dispatch_semaphore_t signal = dispatch_semaphore_create(1);
    dispatch_time_t overTime = dispatch_time(DISPATCH_TIME_NOW, 3*NSEC_PER_SEC);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_semaphore_wait(signal, overTime);
        NSLog(@"同步------1");
        sleep(3);
        NSLog(@"同步------2");
        dispatch_semaphore_signal(signal);
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        sleep(1);
        dispatch_semaphore_wait(signal, overTime);
        NSLog(@"同步------3");
        dispatch_semaphore_signal(signal);
    });
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        sleep(1);
//        dispatch_semaphore_wait(signal, overTime);
//        NSLog(@"同步------4");
//        dispatch_semaphore_signal(signal);
//    });
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        sleep(1);
//        dispatch_semaphore_wait(signal, overTime);
//        NSLog(@"同步------5");
//        dispatch_semaphore_signal(signal);
//    });
}

#pragma mark - NSLock

/**
 NSLock的原理：在线程A 调用unlock方法之前，另一个线程B调用了同一锁对象的lock方法。那么，线程B只有等待。直到线程A调用了unlock。
 1、NSLock是Cocoa提供给我们最基本的锁对象，这也是我们经常所使用的，除lock和unlock方法外，
 2、NSLock还提供了tryLock和lockBeforeDate:两个方法，
    (1) 前一个方法会尝试加锁，如果锁不可用(已经被锁住)，刚并不会阻塞线程，并返回NO。
    (2) lockBeforeDate:方法会在所指定Date之前尝试加锁，如果在指定时间之前都不能加锁，则返回N
 */
- (void)lock_NSLock {
    NSLock *lock = [NSLock new];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [lock lock];
        NSLog(@"同步操作-----1");
        self.testString = @"abc";
        sleep(5);
        NSLog(@"同步操作-----2");
        self.testString = @"111";
        [lock unlock];
    });
    //tryLock 和 lockBeforeDate的使用
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        sleep(1);
//        if([lock tryLock]) {//尝试获取锁，如果获取不到返回NO，不会阻塞该线程
//            NSLog(@"锁可用");
//            [lock unlock];
//        }
//        else {
//            NSLog(@"获取锁失败");
//        }
//        
//        NSDate *date = [[NSDate alloc] initWithTimeIntervalSinceNow:3];
//        if([lock lockBeforeDate:date]) {//尝试在未来的3s内获取锁，并阻塞该线程，如果3s内获取不到恢复线程, 返回NO,不会阻塞该线程
//            NSLog(@"获取到锁");
//            [lock unlock];
//        }
//        else {
//            NSLog(@"超时，没有获得锁");
//        }
//    });
    
    //保持同步的应用举例：
    //1、使用lockBeforeDate。保持变量同一时间，只允许前一线程修改完成后，才能其他线程访问。
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        sleep(1);
//        if([lock tryLock]) { //判断当前是否加锁，若是没有加锁，则操作变量
//            self.testString = @"222";
//            NSLog(@"=====%@",self.testString);
//            [lock unlock];
//        }
//        if([lock lockBeforeDate:[NSDate distantFuture]]) { //尝试在未来一段时间内获取锁，并阻塞线程。如果获取不到则不会阻塞线程。
//            NSLog(@"xxxxx");
//            [lock unlock];
//        }
//        
//    });
    
    //2、直接使用lock保持同步
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [lock lock];
        NSLog(@"等待前一把锁解锁后才能执行");
        [lock unlock];
    });
}

#pragma mark - NSRecursiveLock
/*
 1、这段代码是一个典型的死锁情况。在我们的线程中，RecursiveMethod是递归调用的。所以每次进入这个block时，都会去加一次锁，而从第二次开始，由于锁已经被使用了且没有解锁，所以它需要等待锁被解除，这样就导致了死锁，线程被阻塞住了
 2、递归锁可以被同一线程多次请求，而不会引起死锁。主要用在循环和递归操作中。递归锁会跟踪锁被lock的次数，每次lock都必须平衡调用unlock操作。只有达到这种平衡，锁最后才会被释放。
 
 */
- (void)lock_NSRecursiveLock {
//    NSLock *lock = [[NSLock alloc] init];
    NSRecursiveLock *lock = [NSRecursiveLock new];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        static void (^testMethod)(int);
        testMethod = ^(int value ) {
            [lock lock];
            if(value > 0) {
                NSLog(@"value=====%ld",(long)value);
                sleep(1);
                testMethod(value - 1);
            }
            [lock unlock];
        };
        testMethod(5);
    });
}

#pragma mark - NSConditionLock

/**
 条件锁：我们在处理资源共享的时候，多数情况是只有满足一定条件时才能打开这把锁。    
 在条件锁内部有一个condition，上条件锁的情况是：1、当前锁未锁上。2、条件符合当前锁对象中的条件。二者缺一不可。
 下面是API详细介绍：
 1)  [xxx lockWhenCondition:A条件]; 表示如果没有其他线程获得该锁，但是该锁内部的condition不等于A条件，它依然不能获得锁，仍然等待。如果内部的condition等于A条件，并且没有其他线程获得该锁，则进入代码区，同时设置它获得该锁，其他任何线程都将等待它代码的完成，直至它解锁。
 
 2)  [xxx unlockWithCondition:A条件]; 表示释放锁，同时把内部的condition设置为A条件

 */
- (void)lock_NSConditionLock {
    NSInteger nodata = 9;
    NSConditionLock *conditionLock = [[NSConditionLock alloc] initWithCondition:nodata];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (true) {
            [conditionLock lockWhenCondition:100];
            NSLog(@"获得满足条件是102的锁");
            [conditionLock unlockWithCondition:9];
        }
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (true) {
            [conditionLock lockWhenCondition:9];
            NSLog(@"获得满足条件是9的锁");
            sleep(3);
            [conditionLock unlockWithCondition:100];
        }
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        while (true) {
            BOOL isgetLock = [conditionLock lockWhenCondition:100 beforeDate:[NSDate dateWithTimeIntervalSinceNow:5]];
            if(isgetLock) {
                NSLog(@"获得满足条件是100的锁");
            }
            NSLog(@"获得满足条件是1001的锁");//未获得所是否这行
            [conditionLock unlockWithCondition:9];
//        }
    });
    
}

// 3) lockWhenCondition: beforeDate: 如果未获得锁，则超过该时间后不再阻塞线程。同lockBeforeDate一样，会在一定的时间间隔内不断的去尝试获取锁。

- (void)lock_NSConditionLock2 {
    NSInteger nodata = 9;
    NSConditionLock *conditionLock = [[NSConditionLock alloc] initWithCondition:nodata];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (true) {
            [conditionLock lockWhenCondition:9];
            NSLog(@"获得满足条件是9的锁");
            sleep(3);
            [conditionLock unlockWithCondition:100];
        }
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //        while (true) {
        BOOL isgetLock = [conditionLock lockWhenCondition:100 beforeDate:[NSDate dateWithTimeIntervalSinceNow:5]];
        if(isgetLock) {
            NSLog(@"获得满足条件是100的锁");
        }
        NSLog(@"获得满足条件是1001的锁");//未获得所是否这行
        [conditionLock unlockWithCondition:9];
        //        }
    });
}

#pragma mark - NSCondition 

/**
 最基本的条件锁。手动控制线程wait和signal。类似GCD的信号量，wait之后当前线程会被阻塞直到 lock signal。
 在用的时候注意，首先对lock对象进行lock.
 */
- (void)lock_NSCondition {
    NSCondition *condition = [[NSCondition alloc] init];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [condition lock];
        NSLog(@"线程1将要开始等待");
        [condition wait];
        NSLog(@"线程1等待完成");
        [condition unlock];
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [condition lock];
        NSLog(@"线程2将要开始等待");
        [condition wait];
        NSLog(@"线程2等待完成");
        [condition unlock];
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [condition lock];
//        [condition signal];//任意通知一个线程,前两条线程只有一条会被随机通知。
        [condition broadcast];//通知所有等待的线程
        [condition unlock];
    });
}

//1、当多个线程访问同一段代码时，会以wait为分水岭。一个线程等待另一个线程unlock之后，再走wait之后的代码。
//2、！！！：注意signal发送的时机，signal的发送要在wait之后。否则，signal发送后不会引起任何反应。
- (void)lock_NSCondition2 {
    NSCondition *condition = [[NSCondition alloc] init];
    //线程1：
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [condition lock];
        [condition wait];//必须以wait作为分水岭,等待前一个线程释放后，才能去访问。
        [self commonCode];
        [condition unlock];
    });
    //线程2:
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [condition lock];
        //开始访问共享代码段，进行操作，知道所有任务完成后再进行释放。
        [self commonCode];
        sleep(10);
        [condition signal];//任意通知一个线程,前两条线程只有一条会被随机通知。
        [condition unlock];
    });
    
}

- (void)commonCode {
    NSLog(@"这段代码同一时间只能被一条线成访问");
    //例如：操作数据库中的某一条数据，某一个变量等
}


#pragma mark - pthread_mutex

/**
 1：pthread_mutex_init(pthread_mutex_t mutex,const pthread_mutexattr_t attr);
 初始化锁变量mutex。attr为锁属性，NULL值为默认属性。
 2：pthread_mutex_lock(pthread_mutex_t mutex);加锁
 3：pthread_mutex_tylock(*pthread_mutex_t *mutex);加锁，但是与2不一样的是当锁已经在使用的时候，返回为EBUSY，而不是挂起等待。
 4：pthread_mutex_unlock(pthread_mutex_t *mutex);释放锁
 5：pthread_mutex_destroy(pthread_mutex_t* mutex);使用完后释放
 */

- (void)lock_pthread_mutex {
    __block pthread_mutex_t clock; //这里用到__block的作用是：为了在block修改变量 “clock”。
    pthread_mutex_init(&clock,NULL);//需要导入系统头文件
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        pthread_mutex_lock(&clock);
        NSLog(@"同步状态--------1");
        sleep(3);
        NSLog(@"同步状态--------2");
        pthread_mutex_unlock(&clock);
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        sleep(1);
        int result = pthread_mutex_trylock(&clock);
        NSLog(@"pthread_mutex_trylock:result=====%d",result);
        pthread_mutex_lock(&clock);
        NSLog(@"同步状态--------3");
        pthread_mutex_unlock(&clock);
    });
}

#pragma mark - pthread_mutex(recursive)
/*  C中的递归锁作用同NSRecursiveLock作用相同。
    只需要在创建锁时，通过pthread_mutexattr_t指定锁的“递归属性”即可。
    pthread_mutexattr_init(pthread_mutexattr_t * _Nonnull) :初始化attribute属性
    pthread_mutexattr_settype(pthread_mutexattr_t * _Nonnull,int) :为指定的锁，指定属性类型。值为枚举类型
    pthread_mutexattr_destroy(pthread_mutexattr_t * _Nonnull) :使用完后需要主动释放掉。
 */

- (void)pthread_mutex_recursive_lock {
    __block pthread_mutex_t cRecursiveLock;
    pthread_mutexattr_t t;
    
    pthread_mutexattr_init(&t); //初始化attribute对象
    pthread_mutexattr_settype(&t, PTHREAD_MUTEX_RECURSIVE);//类型设置，可参考对应的枚举，共有4种类型。
    pthread_mutex_init(&cRecursiveLock, &t);
    pthread_mutexattr_destroy(&t);//使用完成后主动释放掉
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
         static void (^testMethod)(int);
        testMethod = ^(int value) {
            pthread_mutex_lock(&cRecursiveLock);
            if(value > 0) { //递归结束的条件
                NSLog(@"value======%d",value);
                sleep(2);
                testMethod(value - 1);
            }
            pthread_mutex_unlock(&cRecursiveLock);
        };
        testMethod(5);
        
    });
}

#pragma mark - OSSpinLock

- (void)OSSpinLock {
    __block OSSpinLock theLock = OS_SPINLOCK_INIT;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        OSSpinLockLock(&theLock);
        NSLog(@"同步线程1--开始");
        sleep(3);
        NSLog(@"同步线程1--结束");
        OSSpinLockUnlock(&theLock);
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        OSSpinLockLock(&theLock);
        sleep(1);
        NSLog(@"同步线程2");
        OSSpinLockUnlock(&theLock);
    });
}

/*
 1、OSSpinLock 自旋锁，性能最高的锁。原理很简单，就是一直 do while 忙等。它的缺点是当等待时会消耗大量 CPU 资源，所以它不适用于较长时间的任务。 不过最近YY大神在自己的博客 《不再安全的OSSpinLock》 中说明了OSSpinLock已经不再安全，请大家谨慎使用。
 2、可以看到对应的APi已经被废弃，解决办法：使用dispatch_semaphore和Pthread来替换。apple：使用pthread_metux替换 google:使用dispatch_semaphore替换。参考链接：http://blog.ibireme.com/2016/01/16/spinlock_is_unsafe_in_ios/
 */

//总结：在实际应用中优先考虑使用pthread_metux和dispatch_semaphore。其他可结合实际情况来使用。@synchronized和NSConditionLock效率较差
//参考链接：http://www.jianshu.com/p/938d68ed832c 等




#pragma mark - dispatch_barrier_async 同 dispatch_barrier_sync 异同

- (void)dispatch_barrier_async_use {
    dispatch_queue_t queue = dispatch_queue_create("testCase", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(queue, ^{
        NSLog(@"任务1");
    });
    dispatch_async(queue, ^{
        NSLog(@"任务2");
    });
    dispatch_async(queue, ^{
        NSLog(@"任务3");
    });
    dispatch_barrier_async(queue, ^{
        sleep(5);
        NSLog(@"------------barrier----------");
    });
    NSLog(@"aaaaa");
    dispatch_async(queue, ^{
        NSLog(@"任务4");
    });
    NSLog(@"bbbbb");
    dispatch_async(queue, ^{
        NSLog(@"任务5");
    });
}

- (void)dispatch_barrier_sync_use {
    dispatch_queue_t queue = dispatch_queue_create("testCase1", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(queue, ^{
        NSLog(@"任务1");
    });
    dispatch_async(queue, ^{
        NSLog(@"任务2");
    });
    dispatch_async(queue, ^{
        NSLog(@"任务3");
    });
    dispatch_barrier_sync(queue, ^{
        sleep(5);
        NSLog(@"------------barrier----------");
    });
    NSLog(@"aaaaa");
    dispatch_async(queue, ^{
        NSLog(@"任务4");
    });
    NSLog(@"bbbbb");
    dispatch_async(queue, ^{
        NSLog(@"任务5");
    });
}

/*
    上面两个函数分别调用后，得出的结果是不一样的。前者aa,bbb一定是在---barrier----前执行的。而后者一定是在---barrier----后执行。
 我们开始总结
 ******** dispatch_barrier_sync和dispatch_barrier_async的共同点：**********
 1、都会等待在它前面”插入队列“的任务（1、2、3）先执行完
 2、都会等待他们自己的任务（0）执行完再执行后面的任务（4、5、6）
 
 ******** dispatch_barrier_sync和dispatch_barrier_async的不共同点：（在于插入到队列时）********
 1、在将任务插入到queue的时候，dispatch_barrier_sync需要等待自己的任务（0）结束之后才会继续程序，然后插入被写在它后面的任务（4、5、6），然后执行后面的任务
 2、而dispatch_barrier_async将自己的任务（0）插入到queue之后，不会等待自己的任务结束，它会继续把后面的任务（4、5、6）插入到queue
 参考链接：http://blog.csdn.net/u013046795/article/details/47057585
 */

@end
