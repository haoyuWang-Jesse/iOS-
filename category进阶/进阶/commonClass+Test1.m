//
//  commonClass+Test1.m
//  进阶
//
//  Created by haoyu3 on 2016/12/5.
//  Copyright © 2016年 haoyu3. All rights reserved.
//

#import "commonClass+Test1.h"
#import <objc/runtime.h>


@implementation commonClass (Test1)
//@dynamic haoyuTestName; //这句代码只能使编译器不会报警告

#pragma mark -  一 、覆盖原有类中的同名方法

//覆盖原类中同名方法，不需要将category的头文件导入

- (void)stringOne {
    NSLog(@"我替换了原有类中的同名方法");
}

/*
 1、category并不是真正替换掉原来类的同名方法，只是category中的方法在方法列表的前面而已。
 2、如果我们想调用原来类中被category覆盖掉的方法，只需要遍历method_list,取到最后一个方法就可以了。（遍历过程要用到runtime知识。）
 */
//示例函数参考ViewController中的getOriginalClassMethod


#pragma mark - 二、为已有的类添加新的方法

+ (void)addNewMethod {
    NSLog(@"我是新添加的方法");
}

#pragma mark - 三、在分类中添加属性

/*
 分类中添加属性，编译器会报警告，编译器不会为分类中属性生成setter &  getter 方法
 验证：在外部使用该属性时： unrecognized selector sent to instance 0x60000001f2b0'
 解决：1、使用@dynamic：只是编译时不会有警告，实际使用时还会报错。
      2、添加setter和 getter方法: 但是这里不支持使用成员变量（知识支持：在setter和getter方法中时不能使用使用“点语法”的，因为点语法的实质就是setter和getter，所以要是在这个里面使用点语法，结果就是造成死循环）。属性 == 成员变量 + setter + getter
 问题：使用方法2时，由于发现不能使用成员变量，要想实现setter和getter方法就是很扯淡的事情了。我们引出四：关联对象
 */

/* //这时可以看出我们没有可以存储通过setter方法赋的值，所以就不能实现真正意义上的属性
 
- (NSString *)haoyuTestName {
    return @"不能使用成员变量，咱们就只能返回固定值";
}

- (void)setHaoyuTestName:(NSString *)haoyuTestName {
    if(haoyuTestName) {
        NSLog(@"不能使用成员变量，传过来的数据没有位置存");
    }
}
 */


#pragma mark - 四、category 和 关联对象
/*
    1、使用关联对象的原因：category 无法添加成员变量（category是在运行时来决定的，而运行时期对象的内存结构已经确定，可以往method_list中添加方法，这改变的仅仅是method list的长度，并未改变对象的内存结构，所以category中不能够添加成员变量），但是很多时候需要在category中添加与对象关联的值。这时可以求助关联对象来实现。
    2、使用方法如下：
 */

- (NSString *)haoyuTestName {
    //第二个参数是自定义的key，
    return objc_getAssociatedObject(self, "customKey1");
}

- (void)setHaoyuTestName:(NSString *)haoyuTestName {
    objc_setAssociatedObject(self, "customKey1", haoyuTestName, OBJC_ASSOCIATION_COPY);
}


/*
    经过以上处理，我们可以实现在category中添加关联对象的操作，或者通过使用关联对象，来实现了为category添加 "可用"属性 的操作。
    3、但是问题又来了：关联对象存在什么地方呢？如何存储？
    答：这就需要借助runtime源码了。附上源码下载地址：https://opensource.apple.com/tarballs/objc4/
    在objc_set_associative_reference：方法，里面有个AssociationsManager，所有的关联对象都由AssociationsManager管理，AssociationsManager是一个结构体，里面由一个静态的AssociationsHashMap来存储所有的关联对象。
    AssociationsManager是一个全局变量，类似往全局的map里面保存了一个AssociationsManager变量，key是这个变量的地址，value则是：AssociationsHashMap，里面包含了所有关联对象的kv对。
    4、对象销毁的时候如何处理关联对象呢？
    销毁一个对象时会先检查该对象是否有关联对象，若是有则调用_object_remove_associations(obj)清理掉关联对象。具体可参照：objc-runtime-new.mm:中的void *objc_destructInstance(id obj)函数
 */



#pragma mark - 五、category和+load方法
/*
 1、在类的load方法中，能够调用category中的load方法吗？可以，将category附加到类上的时机早于load执行的时机。可以看到log中，同名方法的替换log在load log之前被打印出，所以category被附加到类上的事件早于load执行。
 2、类、category1、category2中的load方法调用顺序是怎样的？（1）先执行类，再执行category。（2）至于歌category之间load方法的执行顺序，取决于编译顺序。
 */

+ (void)load {
    [super load];
    NSLog(@"category中的load");
}


#pragma mark - 六 、category 总结
/*
 1、category是什么 ？
 2、category在runtime运行期是如何加载的？
 以上问题可以参考这篇技术博客：http://tech.meituan.com/DiveIntoCategory.html
 */

#pragma mark - 七、category同extension 区别
/*
 1、先来说一下区别：extension总是跟category放在一起来讲，但是实际上二者完全是两个东西。
    （1）extension是在<#编译期#>决定的，它就是类的一部分，也就是说在编译期和类的.h文件里的@interface和.m文件里的@implement一起形成一个完整的类。随着类的产生而产生，随着类的消亡而消亡。
    （2）extension一般用来隐藏类的私有信息，你必须有一个类的源码才能为一个类添加extension(也即是必须要有.m文件)，所以你无法为系统的类比如NSString添加extension。
 */


@end
