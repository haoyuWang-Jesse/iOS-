//
//  TestDeallocManager.m
//  deallocExecute
//
//  Created by haoyu3 on 2017/3/20.
//  Copyright © 2017年 JessesWang. All rights reserved.
//

#import "TestDeallocManager.h"

@implementation TestDeallocManager

+ (void)haoyuTest {
    NSLog(@"之次那个了该方法");
}

- (void)dealloc {
    NSLog(@"deallocXXXXXXXXXXXX");
}

/*
 dealloc不会执行：
    因为是类方法，外部没有实例化该类的对象，所以也不会去执行释放操作。
 */

@end
