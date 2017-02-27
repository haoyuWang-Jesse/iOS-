//
//  clangClass.m
//  进阶
//
//  Created by haoyu3 on 2016/12/7.
//  Copyright © 2016年 haoyu3. All rights reserved.
//

#import "clangClass.h"

@implementation clangClass

- (void)printName {
    NSLog(@"clangClass");
}

@end

@implementation clangClass (testHaoyu)

- (void)printName {
    NSLog(@"clangClass");
}

@end
