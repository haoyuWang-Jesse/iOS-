//
//  LDAPMCrashMonitor_Signal.m
//  MobileAnalysis
//
//  Created by 高振伟 on 17/7/18.
//

#import "LDAPMCrashMonitor_Signal.h"
#import "LDAPMCrashReporter.h"
#import "LDAPMCrashContext.h"
#include <execinfo.h>
#import <signal.h>

typedef void (*SignalHandler)(int signo, siginfo_t *info, void *context);

static SignalHandler previousSignalHandler = NULL;

@implementation LDAPMCrashMonitor_Signal

static void LDAPMSignalHandler(int signal, siginfo_t* info, void* context) {
    
    LDAPMCrashContext *crashContext = [[LDAPMCrashContext alloc] init];
    crashContext.crashName = @"Signal Exception";
    crashContext.crashReason = [NSString stringWithFormat:@"Signal %@ was raised.\n",signalName(signal)];
    crashContext.callStack = callStackOfCurrentThread();
    crashContext.threadInfo = [[NSThread currentThread] description];
    crashContext.threadName = [NSThread currentThread].name;
    
    [LDAPMCrashReporter handleCrash:crashContext];
    
    LDAPMClearSignalRigister();
    
    if (previousSignalHandler) {
        previousSignalHandler(signal, info, context);
    }
//    raise(signal);
}

static void LDAPMClearSignalRigister() {
    signal(SIGSEGV,SIG_DFL);
    signal(SIGFPE,SIG_DFL);
    signal(SIGBUS,SIG_DFL);
    signal(SIGTRAP,SIG_DFL);
    signal(SIGABRT,SIG_DFL);
    signal(SIGILL,SIG_DFL);
    signal(SIGPIPE,SIG_DFL);
    signal(SIGSYS,SIG_DFL);
}

static void LDAPMSignalRegister(int signal) {
    struct sigaction action;
    action.sa_sigaction = LDAPMSignalHandler;
    action.sa_flags = SA_NODEFER | SA_SIGINFO;
    sigemptyset(&action.sa_mask);
    sigaction(signal, &action, 0);
}

NSString *signalName(int signal) {
    NSString *signalName;
    switch (signal) {
        case SIGABRT:
            signalName = @"SIGABRT";
            break;
        case SIGBUS:
            signalName = @"SIGBUS";
            break;
        case SIGFPE:
            signalName = @"SIGFPE";
            break;
        case SIGILL:
            signalName = @"SIGILL";
            break;
        case SIGPIPE:
            signalName = @"SIGPIPE";
            break;
        case SIGSEGV:
            signalName = @"SIGSEGV";
            break;
        case SIGSYS:
            signalName = @"SIGSYS";
            break;
        case SIGTRAP:
            signalName = @"SIGTRAP";
            break;
        default:
            break;
    }
    return signalName;
}

NSArray *callStackOfCurrentThread() {
    NSMutableArray *result = [NSMutableArray array];
    void *callstack[128];
    int frames = backtrace(callstack, 128);
    char** strs = backtrace_symbols(callstack, frames);
    for (int i = 2; i <frames; ++i) {
        [result addObject:[NSString stringWithFormat:@"%s",strs[i]]];
    }
    free(strs);
    
    return [result copy];
}

+ (void)installSignalHandler {
    struct sigaction old_action;
    sigaction(SIGABRT, NULL, &old_action);
    if (old_action.sa_flags & SA_SIGINFO) {
        previousSignalHandler = old_action.sa_sigaction;
    }
    
    LDAPMSignalRegister(SIGABRT);
    LDAPMSignalRegister(SIGBUS);
    LDAPMSignalRegister(SIGFPE);
    LDAPMSignalRegister(SIGILL);
    LDAPMSignalRegister(SIGPIPE);
    LDAPMSignalRegister(SIGSEGV);
    LDAPMSignalRegister(SIGSYS);
    LDAPMSignalRegister(SIGTRAP);
}

@end
