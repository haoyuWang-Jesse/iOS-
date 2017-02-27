//
//  ViewController.m
//  进阶
//
//  Created by haoyu3 on 2016/12/5.
//  Copyright © 2016年 haoyu3. All rights reserved.
//

#import "ViewController.h"
#import "commonClass.h"
#import "commonClass+Test1.h"
#import <objc/runtime.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //1 category
    [[commonClass new] stringOne];
    //[commonClass addNewMethod];
    
    //2、test property which defined in category
    commonClass *com = [commonClass new];
    com.haoyuTestName = @"XXXX";
    NSLog(@"————--------11111111------");
    NSLog(@"使用关联对象取到的值是======%@",com.haoyuTestName);
    [self getOriginalClassMethod];
}


- (void)getOriginalClassMethod {
    Class currentClass = [commonClass class];
    commonClass *com = [commonClass new];
    if(currentClass) {
        unsigned int methodCount ;
        Method *methodList = class_copyMethodList(currentClass, &methodCount);//返回一个 内部元素的类型为Method，用来描述实例方法的指针数组
        IMP lastImp = NULL;
        SEL lastSel = NULL;
        for (NSUInteger i = 0; i<methodCount; i++) {
            Method tempMethod = methodList[i];
            NSString *methodName = [NSString stringWithCString:sel_getName(method_getName(tempMethod)) encoding:NSUTF8StringEncoding];
            if([methodName isEqualToString:@"stringOne"]) {
                lastImp = method_getImplementation(tempMethod);
                lastSel = method_getName(tempMethod);
            }
        }
        typedef void (*fn)(id,SEL); //模拟IMP生成一个函数，最后调用这个函数
        if(lastImp != NULL) {
            fn f = (fn)lastImp;
            f(com,lastSel);
        }
        free(methodList);
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
