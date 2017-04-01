//
//  SimaBackTrace.m
//  RunloopModule
//
//  Created by haoyu3 on 2017/3/24.
//  Copyright © 2017年 JessesWang. All rights reserved.
//

#import "SimaBackTrace.h"
#import <mach/mach.h> // 内核编程
#import <pthread/pthread.h> //pthread 编程
#include <dlfcn.h>

#include <sys/types.h>
#include <limits.h>
#include <string.h>
#include <mach-o/dyld.h>
#include <mach-o/nlist.h>


/*
 寄存器状态特定于系统架构，不同架构下有着不同的寄存器，所以此处的作用是要屏蔽不同架构带来的差异。
 */
#if defined(__arm64__)

#define DETAG_INSTRUCTION_ADDRESS(A) ((A) & ~(3UL))
#define SIMA_THREAD_STATE_COUNT ARM_THREAD_STATE64_COUNT
#define SIMA_THREAD_STATE ARM_THREAD_STATE64
#define SIMA_FRAME_POINTER __fp
#define SIMA_STACK_POINTER __sp
#define SIMA_INSTRUCTION_ADDRESS __pc

#elif defined(__arm__)

#define DETAG_INSTRUCTION_ADDRESS(A) ((A) & ~(1UL))
#define SIMA_THREAD_STATE_COUNT ARM_THREAD_STATE_COUNT
#define SIMA_THREAD_STATE ARM_THREAD_STATE
#define SIMA_FRAME_POINTER __r[7]
#define SIMA_STACK_POINTER __sp
#define SIMA_INSTRUCTION_ADDRESS __pc

#elif defined(__x86_64__)

#define DETAG_INSTRUCTION_ADDRESS(A) (A)
#define SIMA_THREAD_STATE_COUNT x86_THREAD_STATE64_COUNT
#define SIMA_THREAD_STATE x86_THREAD_STATE64
#define SIMA_FRAME_POINTER __rbp
#define SIMA_STACK_POINTER __rsp
#define SIMA_INSTRUCTION_ADDRESS __rip

#elif defined(__i386__) 

#define DETAG_INSTRUCTION_ADDRESS(A) (A)
#define SIMA_THREAD_STATE_COUNT x86_THREAD_STATE32_COUNT
#define SIMA_THREAD_STATE x86_THREAD_STATE32
#define SIMA_FRAME_POINTER __ebp
#define SIMA_STACK_POINTER __esp
#define SIMA_INSTRUCTION_ADDRESS __eip

#endif

//符号解析需要用到的宏
#define CALL_INSTRUCTION_FROM_RETURN_ADDRESS(A) (DETAG_INSTRUCTION_ADDRESS((A)) - 1)

#if defined(__LP64__)
#define TRACE_FMT         "%-4d%-31s 0x%016lx %s + %lu"
#define POINTER_FMT       "0x%016lx"
#define POINTER_SHORT_FMT "0x%lx"
#define BS_NLIST struct nlist_64
#else
#define TRACE_FMT         "%-4d%-31s 0x%08lx %s + %lu"
#define POINTER_FMT       "0x%08lx"
#define POINTER_SHORT_FMT "0x%lx"
#define BS_NLIST struct nlist
#endif


//定义
typedef struct SimaStackFrameEntry{
    const struct SimaStackFrameEntry *const previous;
    const uintptr_t return_address;
} SimaStackFrameEntry;

static mach_port_t main_thread_id;

@implementation SimaBackTrace

/*
+ (void)load {
    main_thread_id = mach_thread_self(); //主线程获取threat_t最好的时机在load方法中。
}
*/

#pragma mark - get call backtrace of mach_thread

NSString *_sima_backtraceOfThread(thread_t thread) {
    //1、获取调用栈，调用栈存储在backtraceBuffer数组中，其中每一个指针对应一个栈帧，每个栈帧又对应一个函数调用，并且每个函数都有自己的符号名。
    uintptr_t backtraceBuffer[50];//声明一个缓冲区
    int i = 0;
    NSMutableString *resultString = [[NSMutableString alloc] initWithFormat:@"Backtrace of Thread %u:\n", thread];
    
    _STRUCT_MCONTEXT machineContext;
    if(!fillThreadStateIntoContext(thread,&machineContext)) { //获取线程的状态
        //获取线程状态失败直接返回
        return [NSString stringWithFormat:@"Fail to get information about thread: %u", thread];
    }
    //获取命令地址，存放到数组中。？？？？
    const uintptr_t instructionAddress = sima_mach_instructionAddress(&machineContext);
    backtraceBuffer[i] = instructionAddress;
    ++i;
    //获取注册地址 ？？？
    uintptr_t linkRegister = sima_mach_linkRegister(&machineContext);
    if (linkRegister) {
        backtraceBuffer[i] = linkRegister;
        i++;
    }
    
    if(instructionAddress == 0) {
        return @"Fail to get instruction address";
    }
    
    //创建自定义结构体
    SimaStackFrameEntry frame = {0};
    const uintptr_t framePtr = sima_mach_framePointer(&machineContext);
    if(framePtr == 0 || sima_mach_copyMem((void *)framePtr, &frame, sizeof(frame)) != KERN_SUCCESS) {
        return @"Fail to get frame pointer";
    }
    
    //这次循环的作用是什么？？？
    for(; i<50; i++) {//i 在前面已经定义
        backtraceBuffer[i] = frame.return_address;
        //根据栈的指针管理来获取上一个栈。
        if(backtraceBuffer[i] == 0 || frame.previous == 0 ||
           sima_mach_copyMem(frame.previous, &frame, sizeof(frame)) != KERN_SUCCESS ) {
            break;
        }
    }
    //2、根据栈帧的Frame Pointer 获取到这个函数调用的符号名。
    int backtraceLength = i;
    Dl_info symbolicated[backtraceLength];
    sima_symbolicate(backtraceBuffer, symbolicated, backtraceLength, 0);
    for (int i = 0; i < backtraceLength; ++i) {
        [resultString appendFormat:@"%@", bs_logBacktraceEntry(i, backtraceBuffer[i], &symbolicated[i])];
    }
    [resultString appendFormat:@"\n"];
    return [resultString copy];
    
    return nil;
}

#pragma mark - convert NSThread to mach_thread

thread_t sima_machThreadFromNSThread(NSThread *nsthread) {
    char name[256];
    mach_msg_type_number_t count;
    thread_act_array_t list;
    task_threads(mach_task_self(), &list, &count);//task_threads函数 分别需要三个参数
    
    //将时间戳作为线程名字
    NSTimeInterval currentTimestamp = [[NSDate date] timeIntervalSince1970];
    NSString *originName = [nsthread name];
    [nsthread setName:[NSString stringWithFormat:@"%f", currentTimestamp]];
    
    //由于主线程设置name后，无法用pthread_getname_np读取到，所以事先获取到主线程的thread_t，然后进行比对。
    if([nsthread isMainThread]) {
        return (thread_t)main_thread_id;//load中获取到
    }
    //其他线程处理思路：先将mach线程转换成pthread，然后利用pthread中系统提供的接口，来获取线程的名字。
    for (int i = 0; i<count; i++) {
        pthread_t pt = pthread_from_mach_thread_np(list[i]);//将mach线程转换成pthread线程，list中线程类型为thread_t类型，mach_port_t同thread_t可以相互转换。
        if([nsthread isMainThread]) {
            if(list[i] == main_thread_id) {
                return list[i]; //主线程直接返回
            }
        }
        if(pt) {
            name[0] = '\0';
            pthread_getname_np(pt, name, sizeof name);
            if(!strcmp(name, [nsthread name].UTF8String)) {//非0,字符串比较而知相同，返回0，前者大返回1，后者大返回-1.非0说明二者不相等（C语言中非0为真）
                [nsthread setName:originName];
                return list[i];
            }
        }
    }
    
    [nsthread setName:originName];
    return mach_thread_self();//没有匹配到，则返回mach线程自己的端口。
}

#pragma mark - handle context 

//获取线程状态使用的是thread_get_state函数

bool fillThreadStateIntoContext(thread_t thread,_STRUCT_MCONTEXT *machineContext) {
    mach_msg_type_number_t state_count = SIMA_THREAD_STATE_COUNT;
    kern_return_t kr = thread_get_state(thread, SIMA_THREAD_STATE, (thread_state_t)&machineContext->__ss, &state_count);
    return (kr == KERN_SUCCESS);
}

#pragma mark - 从machineContext中获取相应的信息

uintptr_t sima_mach_instructionAddress(mcontext_t const machineContext) { //获取指令地址
    return machineContext->__ss.SIMA_INSTRUCTION_ADDRESS;
}

uintptr_t sima_mach_linkRegister(mcontext_t const machineContext) { //获取注册地址
#if defined(__i386__) || defined(__x86_64__)
    return 0;
#else
    return machineContext->__ss.__lr;
#endif
}

uintptr_t sima_mach_framePointer(mcontext_t const machineContext) { //获取frame（帧）指针
    return machineContext->__ss.SIMA_FRAME_POINTER;
}

//拷贝内存？？？获取frame pointer指针
kern_return_t sima_mach_copyMem(const void *const src, void *const dst, const size_t numBytes){
    vm_size_t bytesCopied = 0;
    return vm_read_overwrite(mach_task_self(), (vm_address_t)src, (vm_size_t)numBytes, (vm_address_t)dst, &bytesCopied);
}


#pragma mark - Symbolicate 符号解析

/*
 符号解析分为以下几步：
    1、根据 Frame Pointer 找到函数调用的地址
    2、找到 Frame Pointer 属于哪个镜像文件
    3、找到镜像文件的符号表
    4、在符号表中找到函数调用地址对应的符号名
 */

void sima_symbolicate(const uintptr_t* const backtraceBuffer,
                      Dl_info* const symbolsBuffer,
                      const int numEntries,
                      const int skippedEntries) {
    
}

bool bs_dladdr(const uintptr_t address, Dl_info* const info) {
    info->dli_fname = NULL;
    info->dli_fbase = NULL;
    info->dli_sname = NULL;
    info->dli_saddr = NULL;
    
    const uint32_t idx = bs_imageIndexContainingAddress(address);
    if(idx == UINT_MAX) {
        return false;
    }
    const struct mach_header* header = _dyld_get_image_header(idx);
    const uintptr_t imageVMAddrSlide = (uintptr_t)_dyld_get_image_vmaddr_slide(idx);
    const uintptr_t addressWithSlide = address - imageVMAddrSlide;
    const uintptr_t segmentBase = bs_segmentBaseOfImageIndex(idx) + imageVMAddrSlide;
    if(segmentBase == 0) {
        return false;
    }
    
    info->dli_fname = _dyld_get_image_name(idx);
    info->dli_fbase = (void*)header;
    
    // Find symbol tables and get whichever symbol is closest to the address.
    const BS_NLIST* bestMatch = NULL;
    uintptr_t bestDistance = ULONG_MAX;
    uintptr_t cmdPtr = bs_firstCmdAfterHeader(header);
    if(cmdPtr == 0) {
        return false;
    }
    for(uint32_t iCmd = 0; iCmd < header->ncmds; iCmd++) {
        const struct load_command* loadCmd = (struct load_command*)cmdPtr;
        if(loadCmd->cmd == LC_SYMTAB) {
            const struct symtab_command* symtabCmd = (struct symtab_command*)cmdPtr;
            const BS_NLIST* symbolTable = (BS_NLIST*)(segmentBase + symtabCmd->symoff);
            const uintptr_t stringTable = segmentBase + symtabCmd->stroff;
            
            for(uint32_t iSym = 0; iSym < symtabCmd->nsyms; iSym++) {
                // If n_value is 0, the symbol refers to an external object.
                if(symbolTable[iSym].n_value != 0) {
                    uintptr_t symbolBase = symbolTable[iSym].n_value;
                    uintptr_t currentDistance = addressWithSlide - symbolBase;
                    if((addressWithSlide >= symbolBase) &&
                       (currentDistance <= bestDistance)) {
                        bestMatch = symbolTable + iSym;
                        bestDistance = currentDistance;
                    }
                }
            }
            if(bestMatch != NULL) {
                info->dli_saddr = (void*)(bestMatch->n_value + imageVMAddrSlide);
                info->dli_sname = (char*)((intptr_t)stringTable + (intptr_t)bestMatch->n_un.n_strx);
                if(*info->dli_sname == '_') {
                    info->dli_sname++;
                }
                // This happens if all symbols have been stripped.
                if(info->dli_saddr == info->dli_fbase && bestMatch->n_type == 3) {
                    info->dli_sname = NULL;
                }
                break;
            }
        }
        cmdPtr += loadCmd->cmdsize;
    }
    return true;
}

//符号解析要用到的函数
uintptr_t bs_firstCmdAfterHeader(const struct mach_header* const header) {
    switch(header->magic) {
        case MH_MAGIC:
        case MH_CIGAM:
            return (uintptr_t)(header + 1);
        case MH_MAGIC_64:
        case MH_CIGAM_64:
            return (uintptr_t)(((struct mach_header_64*)header) + 1);
        default:
            return 0;  // Header is corrupt
    }
}

uint32_t bs_imageIndexContainingAddress(const uintptr_t address) {
    const uint32_t imageCount = _dyld_image_count();
    const struct mach_header* header = 0;
    
    for(uint32_t iImg = 0; iImg < imageCount; iImg++) {
        header = _dyld_get_image_header(iImg);
        if(header != NULL) {
            // Look for a segment command with this address within its range.
            uintptr_t addressWSlide = address - (uintptr_t)_dyld_get_image_vmaddr_slide(iImg);
            uintptr_t cmdPtr = bs_firstCmdAfterHeader(header);
            if(cmdPtr == 0) {
                continue;
            }
            for(uint32_t iCmd = 0; iCmd < header->ncmds; iCmd++) {
                const struct load_command* loadCmd = (struct load_command*)cmdPtr;
                if(loadCmd->cmd == LC_SEGMENT) {
                    const struct segment_command* segCmd = (struct segment_command*)cmdPtr;
                    if(addressWSlide >= segCmd->vmaddr &&
                       addressWSlide < segCmd->vmaddr + segCmd->vmsize) {
                        return iImg;
                    }
                }
                else if(loadCmd->cmd == LC_SEGMENT_64) {
                    const struct segment_command_64* segCmd = (struct segment_command_64*)cmdPtr;
                    if(addressWSlide >= segCmd->vmaddr &&
                       addressWSlide < segCmd->vmaddr + segCmd->vmsize) {
                        return iImg;
                    }
                }
                cmdPtr += loadCmd->cmdsize;
            }
        }
    }
    return UINT_MAX;
}

uintptr_t bs_segmentBaseOfImageIndex(const uint32_t idx) {
    const struct mach_header* header = _dyld_get_image_header(idx);
    
    // Look for a segment command and return the file image address.
    uintptr_t cmdPtr = bs_firstCmdAfterHeader(header);
    if(cmdPtr == 0) {
        return 0;
    }
    for(uint32_t i = 0;i < header->ncmds; i++) {
        const struct load_command* loadCmd = (struct load_command*)cmdPtr;
        if(loadCmd->cmd == LC_SEGMENT) {
            const struct segment_command* segmentCmd = (struct segment_command*)cmdPtr;
            if(strcmp(segmentCmd->segname, SEG_LINKEDIT) == 0) {
                return segmentCmd->vmaddr - segmentCmd->fileoff;
            }
        }
        else if(loadCmd->cmd == LC_SEGMENT_64) {
            const struct segment_command_64* segmentCmd = (struct segment_command_64*)cmdPtr;
            if(strcmp(segmentCmd->segname, SEG_LINKEDIT) == 0) {
                return (uintptr_t)(segmentCmd->vmaddr - segmentCmd->fileoff);
            }
        }
        cmdPtr += loadCmd->cmdsize;
    }
    return 0;
}

#pragma mark - GenerateBacbsrackEnrty 产生栈帧入口

NSString* bs_logBacktraceEntry(const int entryNum,
                               const uintptr_t address,
                               const Dl_info* const dlInfo) {
    char faddrBuff[20];
    char saddrBuff[20];
    
    const char* fname = bs_lastPathEntry(dlInfo->dli_fname);
    if(fname == NULL) {
        sprintf(faddrBuff, POINTER_FMT, (uintptr_t)dlInfo->dli_fbase);
        fname = faddrBuff;
    }
    
    uintptr_t offset = address - (uintptr_t)dlInfo->dli_saddr;
    const char* sname = dlInfo->dli_sname;
    if(sname == NULL) {
        sprintf(saddrBuff, POINTER_SHORT_FMT, (uintptr_t)dlInfo->dli_fbase);
        sname = saddrBuff;
        offset = address - (uintptr_t)dlInfo->dli_fbase;
    }
    return [NSString stringWithFormat:@"%-30s  0x%08" PRIxPTR " %s + %lu\n" ,fname, (uintptr_t)address, sname, offset];
}

const char* bs_lastPathEntry(const char* const path) {
    if(path == NULL) {
        return NULL;
    }
    
    char* lastFile = strrchr(path, '/');
    return lastFile == NULL ? path : lastFile + 1;
}


@end
