//
//  ViewController.m
//  RACDemo1
//
//  Created by haoyu3 on 2017/1/4.
//  Copyright © 2017年 JessesWang. All rights reserved.
//

#import "ViewController.h"
#import <ReactiveCocoa/ReactiveCocoa.h>


@interface ViewController ()

@property (nonatomic, strong) UITextField *textFileld;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
//    self.view.backgroundColor = [UIColor lightGrayColor];
    [self setUpUI];
    
    //[self repeatOperation];
    //[self mapOperation];
    //[self filterOperation];
    //[self flattenOperation];
    [self RACDisposableOperation];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)setUpUI {
    CGFloat screenWidth = self.view.frame.size.width;
    self.textFileld = [[UITextField alloc] initWithFrame:CGRectMake(10, 20, screenWidth - 20, 44)];
    self.textFileld.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.textFileld.layer.borderWidth = 1;
    [self.view addSubview:self.textFileld];
    //
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:@"确定" forState:UIControlStateNormal];
    button.frame = CGRectMake((screenWidth-100)/2, CGRectGetMaxY(self.textFileld.frame), 100, 40);
    button.backgroundColor = [UIColor lightGrayColor];
    [button addTarget:self action:@selector(switchToLatestOperation1) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:button];
}

#pragma mark - RAC signal 

#pragma mark - repeat

- (void)repeatOperation {
    RACSignal *signal = @[@1,@2,@3].rac_sequence.signal;
    [signal subscribeNext:^(id x) {
        NSLog(@"订阅前的值===%@",x);
    }];
    //repeat :123,123,123,.......一直重复信号内所有值，并将这个这些值作为一个新信号的输出。
    RACSignal *newSignal = [signal repeat];
    [newSignal subscribeNext:^(id x) {
        NSLog(@"repeat后的值是======%@",x);
    }];
}

#pragma mark - map（匹配信号所有的数据，并且需要全部返回）

- (void)mapOperation {
    RACSignal *signal = @[@2,@4,@3].rac_sequence.signal;
    RACSignal *newSignal = [signal map:^id(NSNumber *value) {
        /*
        if([value integerValue] % 2 == 0) { //匹配能被2整除的
            return value ;
        }
        else { //匹配到不能被2整除的就乘2后返回
            NSInteger tempNumber = [value integerValue];
            return  [NSString stringWithFormat:@"%ld",(long)(tempNumber * 3)] ;
        }
         */
        return @(value.integerValue * 3);
    }];
    
    [newSignal subscribeNext:^(id x) {
        NSLog(@"map处理后的值是===%@",x);
    } error:^(NSError *error) {
        NSLog(@"map -- signal出错了");
    } completed:^{
        NSLog(@"map--信号完成");
    }];
}

#pragma mark -filter（可以过滤掉一部分数据：block中提供的是”过滤条件“，即需要返回的数据要满足什么条件）

- (void)filterOperation {
    RACSignal *signal = @[@"aaa",@"bbb",@"ccc"].rac_sequence.signal;
    RACSignal *newSignal = [signal filter:^BOOL(NSString *value) {
        return  [value isEqualToString:@"bbb"] == NO;
    }];
    [newSignal subscribeNext:^(id x) {
        NSLog(@"经过过滤得到的值===%@",x);
    } error:^(NSError *error) {
        NSLog(@"filter出错了");
    } completed:^{
        NSLog(@"信号完成");
    }];
    
}

#pragma mark - flatten (将多维信号拍平)

- (void)flattenOperation {
    RACSignal *signal = @[@"aa",@"bb",@"cc"].rac_sequence.signal;
    //高阶信号
    RACSignal *highLevelSignal = [signal map:^id(id value) {
        return [RACSignal return:value];
    }];
    
    //订阅高阶信号
    [highLevelSignal subscribeNext:^(id x) {
        NSLog(@"高阶信号的得到的数据是==%@：",x);
    }];
    
    //被拍平后的普通信号
    RACSignal *otherOneLevelSignal = [highLevelSignal flatten];
    
    //订阅拍平后的信号
    [otherOneLevelSignal subscribeNext:^(id x) {
        NSLog(@"被拍平后的信号的值===%@",x);
    } error:^(NSError *error) {
        NSLog(@"出错了");
    } completed:^{
        NSLog(@"flatten完成,这三个block都会被置为nil");
    }];
}

#pragma mark - switchToLatest

- (void)switchToLatestOperation {
    RACSignal *textFieldSignal = [self.textFileld rac_textSignal];
    RACSignal *requestSignal = [textFieldSignal map:^id(NSString *value) {
        NSString *urlString = [NSString stringWithFormat:@"%@?q=%@",@"http://app.ent.sina.com.cn/public/search/",value];
        NSURL *url = [NSURL URLWithString:urlString];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        return [NSURLConnection rac_sendAsynchronousRequest:request];
    }];
    
    RACSignal *searchResultSignal = [requestSignal switchToLatest];
    
    /*
     NSURLConnection的rac_sendAsynchronousRequest:创建的信号，生成的值是RACTuple([http状态响应，返回值data类型])
     */
    
    [[searchResultSignal deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(RACTuple *value) {
        NSData *data = [value second];
        NSDictionary *resultDic = [NSJSONSerialization JSONObjectWithData:data options:0 error:0];
        NSLog(@"dic ===== %@",resultDic);

    } error:^(NSError *error) {
        NSLog(@"数据请求出错");
    } completed:^{
        NSLog(@"数据请求完成");
    }];
    
    
    /* //会在当前线程调用，所以有UI更新时需要切换到主线程，详细看RAC并发编程笔记
    [searchResultSignal subscribeNext:^(RACTuple *value) {
        NSData *data = [value second];
        NSDictionary *resultDic = [NSJSONSerialization JSONObjectWithData:data options:0 error:0];
        NSLog(@"====%@",resultDic);
    } error:^(NSError *error) {
        NSLog(@"数据请求出错");
    } completed:^{
        NSLog(@"数据请求完成");
    }];
    */
}

- (void)switchToLatestOperation1 {
//    RACSignal *signal = @[@1,@2,@3].rac_sequence.signal;
//    RACSignal *signal1 = [signal switchToLatest];
    RACSignal *textFieldSignal = [self.textFileld rac_textSignal];
     RACSignal *signal1 = [textFieldSignal switchToLatest];
    [signal1 subscribeNext:^(id x) {
        NSLog(@"非高阶信号也可以使用switchToLatest=====%@",x);
    }];
}

#pragma mark - scanWithStart


#pragma mark - RACDisposable的使用及理解

/*
 RACDisposeable是一个销毁（撤销）操作对象，可以销毁其对应的任务。例如电影大片中的销毁按钮，触发后所有的任务都会被销毁。
 注：下面的代码执行逻辑：
 1、第一次runloop将各种对象创建完毕，第二次runloop会执行[disposable dispose];，执行完后会触发didsubscriber这个block中的disposable的block.
 2、执行完后会销毁disposable1和disposable2对应的任务。即不会再打印x的value====2
 3、如果断点调试，断点设置在disposable1和disposable2上就会导致系统定时器启动，但是断点并没有把定时器定住，所以会导致，第二次runloop执行的是两个disposable的block中的代码。当然这是设置断点导致的，是一种错误的执行逻辑。
 */

- (void)RACDisposableOperation {
   RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
       [subscriber sendNext:@1];
       RACDisposable *disposable1 = [RACScheduler.mainThreadScheduler afterDelay:2 schedule:^{
           [subscriber sendNext:@2];
       }];
       RACDisposable *disposable2 = [RACScheduler.mainThreadScheduler afterDelay:2 schedule:^{
//           [subscriber sendCompleted];
           [subscriber sendNext:@3];
       }];
       return [RACDisposable disposableWithBlock:^{
           [disposable1 dispose];
           [disposable2 dispose];
           NSLog(@"执行到didsubscriber这个block中dispose的block参数了");
       }];
   }];
    
  RACDisposable *disposable = [signal subscribeNext:^(id x) {
      NSLog(@"x的value====%@",x);
  } error:^(NSError *error) {
      NSLog(@"signal发送error");
  } completed:^{
      NSLog(@"signal发送完成");
  }];
    
  [RACScheduler.mainThreadScheduler afterDelay:1 schedule:^{
      NSLog(@"我要执行外部的dispose了");
      [disposable dispose]; //执行了这句会触发执行内部的dispose
  }];
    
}

@end
