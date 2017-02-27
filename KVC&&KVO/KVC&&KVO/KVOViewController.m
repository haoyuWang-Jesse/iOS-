//
//  KVOViewController.m
//  KVC&&KVO
//
//  Created by haoyu3 on 2017/2/4.
//  Copyright © 2017年 JessesWang. All rights reserved.
//

#import "KVOViewController.h"
#import <objc/runtime.h>

@interface KVOViewController ()

@end

@implementation KVOViewController

//@dynamic userName1;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

#pragma mark - KVO实现机制

/*
 1、当某个类的对像被观察时，系统就会在runtime时期创建该类的一个派生类。在这个派生类中重写基类中任何被观察属性的setter方法。派生类在被重写的setter方法中实现真正的通知机制。
 2、派生类还重写了class方法，以“欺骗”外部调用者它就是原来的那个类。系统将这个对象的isa指针指向了新诞生的派生类，因此这个对象就成了派生类的对象，因而在该对象上对setter的调用就会调用重写的setter方法。
 3、派生类还重写了dealloc方法来释放资源。
 总结：
 KVO实现实际上就是做了以下几件事情：
 （1）创建一个派生类
 （2）在派生类中重写class方法、setter、dealloc、添加_isKVOA
 */

#pragma mark - 重写class

/*
 重写class方法是为了我们调用class方法的时候返回跟重写继承类之前同样的内容。以达到欺骗的目的
*/
//下面的调用要分别在使用KVO前和使用KVO对比查看输出结果，衍生类类名的格式为：NSKVONotifying_MYClass

- (void)overrideClass {
    NSLog(@"self->isa:%@",NSStringFromClass(object_getClass(self)));//self->isa已经被废弃了
    NSLog(@"self class:%@",[self class]);
}

#pragma mark - 重写setter方法

/*
    上面讲到会在衍生类中重写setter方法，到底是怎样重写的setter方法。下面看一下：
    会在衍生类的setter方法中增加另外两个方法的调用：
        - (void)willChangeValueForKey:(NSString *)key
        - (void)didChangeValueForKey:(NSString *)key
    其中在didChangeValueForKey:中调用下面的方法：
        - (void)observeValueForKeyPath:(NSString *)keyPath
                          ofObject:(id)object
                            change:(NSDictionary *)change
                           context:(void *)context
    这就是KVO的实现原理。
 */
- (void)setUserName11:(NSString *)userName1 {
    [self willChangeValueForKey:@"userName1"];
    _userName1 = userName1;
    [self didChangeValueForKey:@"nuserName1ow"];
}

#pragma mark - 能够触发KVO的几种方式

/*
 1、使用了KVC
    1）如果没有访问器（setter和getter）方法，-setValue:forKey:方法（也就是KVC）会直接调用：will和didChangeValue方法，实现kvo。可验证
    2）如果有访问器方法，KVC会先调用访问器方法，然后在调用will和didChangeValue方法。
 2、直接使用访问器(setter\getter)方法（大多通过.语法来调用访问器方法）也会触发KVO
 3、显示调用will\didChangeValueForKey:函数会触发KVO
 4、调用mutableArrayValueForKey:获得一个新数组时：
   // Use mutableArrayValueForKey: to retrieve a relationship proxy object.
   Transaction *newTransaction = <#Create a new transaction for the account#>;
   NSMutableArray *transactions = [account mutableArrayValueForKey:@"transactions"];
   [transactions addObject:newTransaction];
 */

#pragma mark - KVO是基于KVC实现的结论分析
/*
 各种博客上说KVO是基于KVC实现的，大概就是基于一下这点：在衍生类重写的setter方法中，赋值时使用KVC方式。
 实际上KVO的实现并无直接关联，官方文档上介绍为：想实现KVO观察机制的类的property必须是遵守KVC机制。
 跟同事大体讨论了下：其实二者并没有太多关联，官方文档上有句话，摘录出来
 In order to be considered KVO-compliant for a specific property, a class must ensure the following:
 
 The class must be <#key-value coding compliant#> for the property, as specified in Ensuring KVC Compliance.
 KVO supports the same data types as KVC, including Objective-C objects and the scalars and structures listed in Scalar and Structure Support.
 那怎样才是<#key-value coding compliant#>呢?官网上还有一句话
 How you make a property KVC compliant depends on whether that property is an attribute, a to-one relationship, or a to-many relationship. For attributes and to-one relationships, a class must implement at least one of the following in the given order of preference (key refers to the property key):
 
 （1）The class has a declared property with the name key.
 （2）It implements accessor methods named key and, if the property is mutable, setKey:. (If the property is a Boolean attribute, the getter accessor method has the form isKey.)
 （3）It declares an instance variable of the form key or _key.
 什么意思呢：就是上面三条要至少满足一条才能认定某个类的property符合kvc规范。
 既然这姑且就认为KVO实现原理中会重写setter方法，那就认为这一点就是KVO是基于KVC实现的牵强理由吧。有问题或异议可同本人联系我们相互学习：1223556769@qq.com
 */



#pragma mark - 添加_isKVOA私有方法

/*
    这个私有方法估计是用来标示该类是一个 KVO 机制声称的类。
 */


- (void)willChangeValueForKey:(NSString *)key {
    NSLog(@"调用了willChangeValue这个方法");
    [super willChangeValueForKey:key];
}

- (void)didChangeValueForKey:(NSString *)key {
    NSLog(@"调用了didChangeValue这个方法,这个方法调用了observerValueForKeyPath:");
    [super didChangeValueForKey:key];
}

#pragma mark - 下面的这方法是由didchangevalue来调用的

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    NSLog(@"=====%@",keyPath);
    /*
     （1）???:这个方法应该写在哪里？如果在这个controller中观察一个属性，然后再监听KVOViewcontroller中的一个属性，同时改变着两个属性，会怎么调用
        该方法在哪里调用取决于：[objc addObserver:XXXX forKeyPath:];观察者是哪个对象，必须在观察者对象所属的类中实现obserValueForKeyPath:函数。调用的就是“观察者对象”中的该函数。
     （2）[被观察对象 addObserver:观察者 forKeyPath:options:error:];
    */
    
}



#pragma mark - KVC && KVO 关于基于isa_swizzling技术实现的理解与总结

/*
 1、KVO说是基于isa-swizzling技术实现的是毋庸置疑的，因为通过在运行时创建衍生类，并将对象的isa指针指向新创建的衍生类，从而执行衍生类中的setter方法，达到偷梁换柱的目的，来实现KVO机制
 2、KVC如果也是说基于isa-swizzling技术实现的多少有些牵强，以setValue:forKey为例，首先生成其sel，然后根据对象的isa找到该对象的原类，并结合sel，找到对应方法的IMP，最后去执行IMP。一个基本的runtime时期的方法执行过程。并没有涉及到isa-swizzling,或许对KVC机制理解还是不够深刻，有问题或异议可同本人联系：1223556769@qq.com
 */


#pragma mark - KVO应用
#pragma mark - 手动通知和自动通知

//这个方法可以控制是否需要自动通知

+(BOOL)automaticallyNotifiesObserversOfArray1 {
    return NO;
}

#pragma mark - 巧妙使用context
/*
 有时我们会有理由不想用 KeyValueObserver 辅助类。创建另一个观察对象会有额外的性能开销。如果我们观察很多个键的话，这个开销可能会变得明显。
 */

#pragma mark - 在value被改变前就收到通知

/*
 之前和之后
 当我们注册 KVO 通知的时候，我们可以添加 NSKeyValueObservingOptionPrior 选项，这能使我们在键值改变之前被通知。这和-willChangeValueForKey:被触发的时间相对应。
 
 如果我们注册通知的时候附加了 NSKeyValueObservingOptionPrior 选项，我们将会收到两个通知：一个在值变更前，另一个在变更之后。变更前的通知将会在 change 字典中有不同的键。我们可以像以下这样区分通知是在改变之前还是之后被触发的：
 
 if ([change[NSKeyValueChangeNotificationIsPriorKey] boolValue]) {
 // 改变之前
 } else {
 // 改变之后
 }
 
 */

#pragma mark - 获取value初始化时候的值

/*
 我们常常需要当一个值改变的时候更新 UI，但是我们也要在第一次运行代码的时候更新一次 UI。我们可以用 KVO 并添加 NSKeyValueObservingOptionInitial 的选项 来一箭双雕地做好这样的事情。这将会让 KVO 通知在调用 -addObserver:forKeyPath:... 到时候也被触发。
 */

#pragma mark - KVO同多线程

/*
 KVO的行为是同步的，观察这与发生变化的value操作应该是在同一条线程上
 当我们试图从其他线程改变属性值的时候我们应当十分小心，除非能确定所有的观察者都用线程安全的方法处理 KVO 通知。
 通常来说，我们不推荐把 KVO 和多线程混起来。如果我们要用多个队列和线程，我们不应该在它们互相之间用 KVO。
 */


#pragma mark - 参考文档

//https://www.objccn.io/issue-7-3/
//http://blog.csdn.net/wzzvictory/article/details/9674431
//http://blog.csdn.net/chaoyuan899/article/details/44699503
//http://blog.sunnyxx.com/2014/03/09/objc_kvo_secret/
//https://github.com/garnett/DLIntrospection    runtime封装，写的很好
//http://tech.glowing.com/cn/implement-kvo/  自己动手实现KVO机制，这里的作者实现并非是模仿系统实现，而是在此基础上进行的通过runtime进行的实现，有需要的可以看一下

@end
