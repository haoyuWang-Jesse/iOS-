//
//  First_stack.h
//  ThreadAndCallStack
//
//  Created by haoyu3 on 2017/6/8.
//  Copyright © 2017年 sina. All rights reserved.
//

1、调用栈：调用栈其实是栈的一种抽象概念，它表示了方法之间的调用关系，一般来说从栈中可以解析出调用栈。·
栈：由许多栈帧（Frame）组成，每个<#栈帧#>对应一个函数调用。
栈帧：栈帧就是一个函数调用，有三部分组成：（1）函数参数 (2)返回地址 （3）函数内容定义的局部变量
Stack pointer:栈指针，表示当前栈的顶部
Frame pointer:帧指针，指向的地址中，存储了上一次的Stack Pointer的值，也就是返回地址。

2、task_threads(task,)


参考链接：
1、http://blog.csdn.net/gykimo/article/details/9132157
2、http://blog.chinaunix.net/uid-29270124-id-4968608.html
3、
