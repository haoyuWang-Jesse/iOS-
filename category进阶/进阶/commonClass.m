//
//  commonClass.m
//  进阶
//
//  Created by haoyu3 on 2016/12/5.
//  Copyright © 2016年 haoyu3. All rights reserved.
//

#import "commonClass.h"

@implementation commonClass

- (void)stringOne {
    NSLog(@"原来类中的方法");
}

+ (void)load {
    [super load];
    NSLog(@"原类中的load");
}

@end
