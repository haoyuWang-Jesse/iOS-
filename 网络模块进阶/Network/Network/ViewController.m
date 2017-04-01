//
//  ViewController.m
//  Network
//
//  Created by haoyu3 on 2017/3/1.
//  Copyright © 2017年 JessesWang. All rights reserved.
//

#import "ViewController.h"
#import <netdb.h>

#import <CoreFoundation/CoreFoundation.h>
#include <sys/socket.h>
#include <netinet/in.h>

#import "fishhook.h"
#import <dlfcn.h>

CFMutableDataRef responseBytes;



#define kBufferSize 1024

//fishhook

static int (*orig_close)(int);
static int (*orig_open)(const char *, int, ...);
//hook DNS IP
static int (*orig_getaddrinfo)(const char * __restrict, const char * __restrict,
                                           const struct addrinfo * __restrict,
                                           struct addrinfo ** __restrict);

@interface ViewController ()

@property (nonatomic, strong) NSMutableData *receiveData ;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //first thing
    hookDNSParse();//提前调用
    
    
//    NSLog(@"11111");
    NSArray *tempArray = [[self class] syncGetaddrinfoWithDomain:@"app.ent.sina.com.cn"];
//    NSLog(@"=======%@",tempArray);
//    http://app.ent.sina.com.cn/
//    [self CFNetworkRequestTestWithURLString:[NSURL URLWithString:@"http://app.ent.sina.com.cn/"]];
    
//    test();
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


//使用getaddrinfo进行域名解析

+ (NSArray *)syncGetaddrinfoWithDomain:(NSString *)domain
{
    if (domain.length == 0) {
        return nil;
    }
    struct addrinfo hints;
    memset(&hints, 0, sizeof(hints));
    hints.ai_family = PF_INET;
    hints.ai_protocol = IPPROTO_TCP;
    struct addrinfo *addrs, *addr;
    
    int getResult = getaddrinfo([domain UTF8String], NULL, &hints, &addrs);
    if (getResult || addrs == nil) {
        NSLog(@"Warn: DNS with domain:%@ failed:%d", domain, getResult);
        return nil;
    }
    addr = addrs;
    NSMutableArray *result = [NSMutableArray array];
    for (addr = addrs; addr; addr = addr->ai_next) {
        char host[NI_MAXHOST];
        memset(host, 0, NI_MAXHOST);
        getnameinfo(addr->ai_addr, addr->ai_addrlen, host, sizeof(host), NULL, 0, NI_NUMERICHOST);
        if (strlen(host) != 0) {
            [result addObject:[NSString stringWithUTF8String:host]];
        }
    }
    freeaddrinfo(addrs);
    
    NSLog(@"Info: DNS with domain:%@ -> %@", domain, result);
    return result;
}

#pragma mark - CFNetwork

- (void)CFNetworkRequestTestWithURLString:(NSURL *)url {
    NSString * host = [url host];
    NSInteger port = [[url port] integerValue] ?:8081;
    
    CFURLRef theURL = CFURLCreateWithString(kCFAllocatorDefault, CFSTR("http://app.ent.sina.com.cn/"), NULL);
    CFHTTPMessageRef requestMessage = CFHTTPMessageCreateRequest(kCFAllocatorDefault, CFSTR("GET"), theURL, kCFHTTPVersion1_1);
    CFRelease(theURL);
    
    CFReadStreamRef readStream = CFReadStreamCreateForHTTPRequest(kCFAllocatorDefault, requestMessage);
    CFRelease(requestMessage);
    
    //创建上下文--
    CFStreamClientContext ctx = {0,(__bridge void *)(self), NULL, NULL, NULL};
    //指定回调函数触发事件
    CFOptionFlags registeredEvents = (kCFStreamEventHasBytesAvailable | kCFStreamEventEndEncountered | kCFStreamEventErrorOccurred);
    //创建流
//    CFReadStreamRef readStream;
//    CFWriteStreamRef writeStream;
    //创建流
//    CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, (__bridge CFStringRef)host, (unsigned int)port, &readStream, &writeStream);
    //设置回调同时将流add进runloop
   
    if (CFReadStreamSetClient(readStream, registeredEvents, socketCallBack, &ctx)) {
        CFReadStreamScheduleWithRunLoop(readStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
    }
    else {
        NSLog(@"Failed to assign callback method");
        return;
    }
    
    // 显示调用，open流
    if (CFReadStreamOpen(readStream) == NO) {
        NSLog(@"Failed to open read stream");
        return;
    }
}

#pragma mark - callback


void socketCallBack(CFReadStreamRef stream, CFStreamEventType event, void * myPtr) {//param:流，eventType,ptr(回调对象)
     NSLog(@"INFO:WangHaoyu -  socketCallback in Thread %@", [NSThread currentThread]);
    ViewController * controller = (__bridge ViewController *)myPtr;
    if(!responseBytes) {
        responseBytes = CFDataCreateMutable(kCFAllocatorDefault, 0);
    }
    switch (event) { //对应枚举：CFStreamEventType
        case kCFStreamEventHasBytesAvailable: //接收到数据
        {
            //读取数据
            while(CFReadStreamHasBytesAvailable(stream)) {//Bool：当前是否有数据
                UInt8 buffer[kBufferSize];
                 CFIndex numberOfBytesRead = CFReadStreamRead(stream, buffer, kBufferSize);//返回值是CFIndex,下标
                if (numberOfBytesRead > 0) {
                    CFDataAppendBytes(responseBytes, buffer, numberOfBytesRead);
                }
            }
        }
            break;
        case kCFStreamEventErrorOccurred://出错
        {
            CFErrorRef error = CFReadStreamCopyError(stream);
            if (error != NULL) {
                if (CFErrorGetCode(error) != 0) {
                    NSString * errorInfo = [NSString stringWithFormat:@"Failed while reading stream; error '%@' (code %ld)", (__bridge NSString*)CFErrorGetDomain(error), CFErrorGetCode(error)];
                    NSLog(@"读取数据流出错:%@",errorInfo);
                }
                CFRelease(error);
            }
        }
            break;
            
        case kCFStreamEventEndEncountered: //结束
        {
            //解析数据
            if(responseBytes) {
                NSMutableData *receiveData = (__bridge NSMutableData *)responseBytes;
                NSError *error;
                NSString *jsonString = [NSJSONSerialization JSONObjectWithData:receiveData options:0 error:&error];
//                NSString *jsonString = [[NSString alloc] initWithData:receiveData encoding:NSUTF8StringEncoding];
                if(error) {
                    NSLog(@"ERROR是=====%@",error.localizedDescription);
                }
                else {
                    NSLog(@"json格式的数据是=====%@",jsonString);
                }
            }
            // Clean up
            CFReadStreamClose(stream);
            CFReadStreamUnscheduleFromRunLoop(stream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);//关闭流的同时需要将其
            CFRunLoopStop(CFRunLoopGetCurrent());
            
        }
             break;
        default:
            break;
    }
}

#pragma mark - fishhook test
/*
 dlsym函数：
    函数原型是
    void* dlsym(void* handle,const char* symbol)
    该函数在文件中。
    handle是由dlopen打开动态链接库后返回的指针，symbol就是要求获取的函数的名称，函数  返回值是void*,指向函数的地址，供调用使用。
 参考链接：http://blog.chinaunix.net/uid-21961753-id-1810668.html
 */
void save_original_symbols() {
    orig_close = dlsym(RTLD_DEFAULT, "close");//获取动态链接库中的函数指针
    orig_open = dlsym(RTLD_DEFAULT, "open");
}

int my_close(int fd) {
    printf("回调手动修改的关闭函数(%d)\n", fd);
    return orig_close(fd);
}

int my_open(const char *path, int oflag, ...) {
    va_list ap = {0};
    mode_t mode = 0;
    
    if ((oflag & O_CREAT) != 0) {
        // mode only applies to O_CREAT
        va_start(ap, oflag);
        mode = va_arg(ap, int);
        va_end(ap);
        printf("回调手动打开的函数('%s', %d, %d)\n", path, oflag, mode);
        return orig_open(path, oflag, mode);
    } else {
        printf("回调手动打开的函数('%s', %d)\n", path, oflag);
        return orig_open(path, oflag, mode);
    }
}

void test() {
    save_original_symbols();
    //fishhook用法
    rebind_symbols((struct rebinding[2]){{"close", my_close}, {"open", my_open}}, 2);
    //
    int fd = open(NULL, O_RDONLY);
    //
    uint32_t magic_number = 0;
    read(fd, &magic_number, 4);
    printf("Mach-O Magic Number: %x \n", magic_number);
    //
    close(fd);
}


#pragma mark - hook getaddrinfo 

void get_original_symbols() {
    orig_getaddrinfo = dlsym(RTLD_DEFAULT, "getaddrinfo");//获取动态链接库中的函数指针
}

int my_getaddrinfo(const char *domain, const char *value, const struct addrinfo *hints, struct addrinfo **addrinfo){
    NSLog(@"在这里hook住了");
    int result =  orig_getaddrinfo(domain, value, hints, addrinfo);
    NSLog(@"在这里hook结束");
    return result;
}

void hookDNSParse() {
    get_original_symbols();
    NSLog(@"1111");
    //fishhook用法
    rebind_symbols((struct rebinding[1]){{"getaddrinfo", my_getaddrinfo}}, 1);
    //提前调用是否可以？？

    NSLog(@"22222");
}


#pragma mark - CFNetwork 层面上的hook



@end
