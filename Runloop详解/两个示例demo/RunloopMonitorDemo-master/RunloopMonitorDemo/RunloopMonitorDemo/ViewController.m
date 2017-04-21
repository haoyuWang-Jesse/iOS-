//
//  ViewController.m
//  RunloopMonitorDemo
//
//  Created by game3108 on 16/4/13.
//  Copyright © 2016年 game3108. All rights reserved.
//

#import "ViewController.h"
#import "MonitorController.h"
#import "SeMonitorController.h"

#import "SimaANRMonitor.h"

#import "SimaANRDetector.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    /*
//    [[SeMonitorController sharedInstance] startMonitor];
    [[SimaANRMonitor shareInstance] registerMonitor];
//    [[SimaANRDetector shareInstance] registerMonitor];
    
    UIButton *longTimeButton = [[UIButton alloc]initWithFrame:CGRectMake(100, 50, 100, 100)];
    longTimeButton.backgroundColor = [UIColor blackColor];
    [longTimeButton addTarget:self action:@selector(runLongTime) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:longTimeButton];
    
    UIButton *printLogButton = [[UIButton alloc]initWithFrame:CGRectMake(100, 200, 100, 100)];
    printLogButton.backgroundColor = [UIColor grayColor];
    [printLogButton addTarget:self action:@selector(printLog) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:printLogButton];
    */
    [self testHaoyu];
}

- (void)runLongTime {
    NSInteger m = 0;
    for ( int i = 0 ; i < 10000 ; i ++ ){
        m++;
        NSLog(@"1111");
    }
}

- (void)printLog{
    [[SeMonitorController sharedInstance] printLogTrace];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)testHaoyu {
    NSString *str = nil;
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithObjectsAndKeys:
            @"",@"model",
            @"apple",@"brand",
            str ,@"rp", nil ];
    NSLog(@"dic ======%@",dic);
}

@end
