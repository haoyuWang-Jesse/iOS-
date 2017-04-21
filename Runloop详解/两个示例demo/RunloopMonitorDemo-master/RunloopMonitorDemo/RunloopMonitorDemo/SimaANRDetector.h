//
//  SimaANRDetector.h
//  RunloopMonitorDemo
//
//  Created by haoyu3 on 2017/3/23.
//  Copyright © 2017年 com.sina. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SimaANRDetector : NSObject

+ (instancetype)shareInstance;

- (void)registerMonitor;

@end
