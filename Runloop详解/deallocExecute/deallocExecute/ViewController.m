//
//  ViewController.m
//  deallocExecute
//
//  Created by haoyu3 on 2017/3/20.
//  Copyright © 2017年 JessesWang. All rights reserved.
//

#import "ViewController.h"
#import "TestDeallocManager.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
     [TestDeallocManager haoyuTest];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
