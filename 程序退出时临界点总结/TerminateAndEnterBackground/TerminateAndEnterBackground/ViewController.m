//
//  ViewController.m
//  TerminateAndEnterBackground
//
//  Created by haoyu3 on 2017/4/7.
//  Copyright © 2017年 JessesWang. All rights reserved.
//

#import "ViewController.h"
#import "requestMoreTime.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.\
    
    [[requestMoreTime new] beginDownload];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
