//
//  ViewController.m
//  RunloopForMacOS
//
//  Created by haoyu3 on 2017/3/20.
//  Copyright © 2017年 JessesWang. All rights reserved.
//

#import "ViewController.h"
#import "MyClass.h"

@interface ViewController()<NSMachPortDelegate>

@property (nonatomic, strong) MyClass *myclassObjc;//!!!:WangHaoyu - 一定要让该对象被持有，否则会被释放掉。

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    self.myclassObjc = [MyClass new];
    [self.myclassObjc launchThread];
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


@end
