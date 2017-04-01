//
//  ViewController.m
//  RunloopModule
//
//  Created by haoyu3 on 2017/3/19.
//  Copyright © 2017年 JessesWang. All rights reserved.
//

#import "ViewController.h"
#import "MyClass.h"
#import "CustomSource.h"
#import "CustomTimerSource.h"

@interface ViewController ()

@property (nonatomic,strong) MyClass *myClassObjc;

@property (nonatomic,strong) CustomTimerSource *customSource;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self setUpUI];
    //1、基于开端口的输入源
//    self.myClassObjc = [MyClass new];
//    [self.myClassObjc launchThread];
    self.customSource = [CustomTimerSource new];
    //2、自定义的输入源
   // [[CustomSource new] createCustomSource];
    
    //3、NSTimer
    //[self.customSource setupTimerSource];
   // [[CustomTimerSource new] setupTimerSourceWithdefaultMethod];
    
    //4、高精确度的dispatch_source_t
    [self.customSource setUpDispatchSource];
}



- (void)setUpUI {
    UIButton *longTimeButton = [[UIButton alloc] initWithFrame:CGRectMake(100, 50, 200, 50)];
    longTimeButton.backgroundColor = [UIColor lightGrayColor];
    [longTimeButton setTitle:@"点我" forState:UIControlStateNormal];
    [longTimeButton addTarget:self action:@selector(cancleTimer) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:longTimeButton];
    
    UIButton *longTimeButton1 = [[UIButton alloc] initWithFrame:CGRectMake(100, 110, 200, 50)];
    longTimeButton1.backgroundColor = [UIColor lightGrayColor];
    [longTimeButton1 setTitle:@"取消dispatch_source" forState:UIControlStateNormal];
    [longTimeButton1 addTarget:self action:@selector(cancleDispatchSource) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:longTimeButton1];
    
    UIButton *longTimeButton2 = [[UIButton alloc] initWithFrame:CGRectMake(100, 170, 200, 50)];
    longTimeButton2.backgroundColor = [UIColor lightGrayColor];
    [longTimeButton2 setTitle:@"继续dispatch_source" forState:UIControlStateNormal];
    [longTimeButton2 addTarget:self action:@selector(resumeDispatchSource) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:longTimeButton2];
}

- (void)cancleTimer {
    [self.customSource cancleTimer];
    self.customSource = nil;//打断self对customSource的持有，否则customSource不会执行dealloc。
}

- (void)cancleDispatchSource {
    [self.customSource setUpCancle];
}

- (void)resumeDispatchSource {
    [self.customSource setupResume];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - base64 && gzip




@end
