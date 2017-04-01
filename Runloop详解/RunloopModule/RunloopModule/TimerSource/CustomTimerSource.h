//
//  TimerSource.h
//  RunloopModule
//
//  Created by haoyu3 on 2017/3/31.
//  Copyright © 2017年 JessesWang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CustomTimerSource : NSObject

- (void)setupTimerSource;

- (void)setupTimerSourceWithdefaultMethod;

- (void)cancleTimer;

- (void)setUpDispatchSource;
- (void)setUpCancle;
- (void)setupResume;

@end
