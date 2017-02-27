//
//  ViewController.m
//  KVC&&KVO
//
//  Created by haoyu3 on 2017/1/19.
//  Copyright © 2017年 JessesWang. All rights reserved.
//

#import "ViewController.h"
#import "people.h"
#import "friend.h"

#import "KVOViewController.h"

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
//    [self KVCOperate];
//    [self KVCOperateGettter];
//    [self KVCOPerateGetterArray];
//    [self KVOMutableArrayOperation];
//    [self KVCMutableSetOperation];
//    [self KVCValidateValue];
//    [self KVCCollectionOperator];
    [self KVOTest];
}

#pragma mark - KVC

#pragma mark - 一、KVC使用
/*
 KVC使用
 
 获取值
 valueForKey: 传入NSString属性的名字。
 valueForKeyPath: 属性的路径，xx.xx
 valueForUndefinedKey 默认实现是抛出异常，可重写这个函数做错误处理
 
 修改值
 setValue:forKey:
 setValue:forKeyPath:
 setValue:forUnderfinedKey:
 setNilValueForKey: 对非类对象属性设置nil时调用，默认抛出异常。
 */

#pragma mark - 二、KVC键值查找

- (void)KVCOperate {
    people *p = [people new];
    [p setValue:@"jesses" forKey:@"peopleName"];
    NSLog(@"通过kvc方式储存的值=====%@",[p valueForKey:@"peopleName"]);
}

- (void)KVCOperateGettter {
    people *p = [people new];
     [p setValue:@"jesses" forKey:@"peopleName"];
    NSLog(@"通过KVC取得方式====%@",[p valueForKey:@"peopleName"]);
}

- (void)KVCOPerateGetterArray {
    people *p = [people new];
//    [p setValue:@[@1,@2,@3] forKey:@"friends"];
    NSLog(@"KVC查找有序集合array=====%@",[p valueForKey:@"friends"]);
}

#pragma mark - 查找有序集合 例如：NSMutableArray

- (void)KVOMutableArrayOperation {
    people *p = [people new];
    p.privateArray = [NSMutableArray array];
    p.privateArray = [@[@"哈哈",@"嘿嘿"] mutableCopy];
   // [p mutableSetValueForKey:@"friends"];
//    NSLog(@"查找有序集合。例如NSMutableArray=====%@",[p mutableArrayValueForKey:@"friends"]);
    
    NSMutableArray *array = [p mutableArrayValueForKey:@"friends"];
    [array addObject:@"aa"];
    NSLog(@"修改过后的array====%@",array);
    
}

#pragma mark - 查找无序集合 例如：NSMutableSet

- (void)KVCMutableSetOperation {
    people *p = [people new];
    p.privateSet = [[NSMutableSet alloc] initWithObjects:@"111",@"222",@"333", nil];
    NSMutableSet *set = [p mutableSetValueForKey:@"friendSet"];
    [set addObject:@"aaaaNN"];
       
    NSLog(@"====set查找：%@",[p mutableSetValueForKey:@"friendSet"]);
}

#pragma mark - 三、KVC提供功能

#pragma mark - 值的正确性核查

- (void)KVCValidateValue {
    friend *f = [friend new];
    NSString *frienfNameStr = @"petter";
    NSError *error;
    BOOL isValidate = [f validateValue:&frienfNameStr forKey:@"friendName" error:&error];
    if(isValidate) { //要设置的值通过校验，允许进行下一步操作
        [f setValue:frienfNameStr forKey:@"friendName"];
        NSLog(@"值通过校验，设置值成功");
    }
    else {
        NSLog(@"要设置的值，不通过校验");
    }
}


#pragma mark - 集合运算符

- (void)KVCCollectionOperator {
    friend *f = [friend new];
    [f simpleCollectionOperator];
    [f ObjcCollectionOperator];
    [f ArrayAndSetCollectionOperator];
}

#pragma mark - KVO执行机制

- (void)KVOTest{
    KVOViewController *kvo = [KVOViewController new];
    kvo.array1 = @[@1,@2,@"haha"];
    [kvo addObserver:kvo forKeyPath:@"userName1" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:nil];
//    kvo.userName1 = @"aaaa";
    [kvo setValue:@"aaaaassss" forKey:@"userName1"];
    [kvo removeObserver:kvo forKeyPath:@"userName1"];
    
    //监听array1
    [kvo addObserver:kvo forKeyPath:@"array1" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:nil];
    kvo.array1 = @[@3,@6];
    [kvo removeObserver:kvo forKeyPath:@"array1"];

}

#pragma mark - kvo delegate 

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    NSLog(@"=====%@",keyPath);
    //???:这个方法应该写在哪里？如果在这个controller中观察一个属性，然后再监听KVOViewcontroller中的一个属性，同时改变着两个属性，会怎么调用
}



@end
