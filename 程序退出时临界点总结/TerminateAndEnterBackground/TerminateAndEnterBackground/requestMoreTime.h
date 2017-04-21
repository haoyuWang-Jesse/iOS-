//
//  requestMoreTime.h
//  TerminateAndEnterBackground
//
//  Created by haoyu3 on 2017/4/7.
//  Copyright © 2017年 JessesWang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface requestMoreTime : NSObject

- (void)beginTask;
- (void)endTask;
- (void)doSomeWorkWithTimer:(NSTimer *)timer;

+ (void)test;
@end
