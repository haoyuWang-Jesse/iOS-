好雨知时节技术分享 @王浩宇
===========

本地址为技术分享地址，有技术博客、录制视频、demo等内容，后续会提供不同的技术分享，如果大家觉得可以，后续会录制相关视频，针对性讲解相关知识点。<br>
作者：新浪技术开发<br>
##目录：<br>
##1、使用instrument提高iOS和react native开发界面的流畅性。

##2、ReactiveCocoa实战教程，后续会录制视频给大家详细讲解，大约分为5-6次视频录制。跟志同道合的技术人员一起分享。

##3、Category进阶。这个东西很常用，但是对它又有多少的了解呢？为了对程序做精细化的控制，我们需要了解一些机制。

##4、KVC && KVO：详细的总结了一下，二者的底层实现机制以及使用。


###目录摘要：
####1、KVC使用
####2、KVC内部执行机制
#####2.1、单值查找
######(1)setValue:forKey:查找顺序
######(2)valueForKey:查找顺序
#####2.2、查找有序集合成员，比如NSMutableArray、NSArray
######(1)set修改查找顺序(只有可变数类型数据才会有set操作NSMutableArray)
######(2)get获取查找顺序
#####2.3、搜索无序集合成员，比如NSSet、NSMutableSet
######(1)set修改查找顺序（只有可变数类型数据才会有set操作NSMutableSet）
######(2)get获取查找顺序
####3、KVC提供的功能 
#####3.1、键值校验
#####3.2、对数值和结构体类型的数据支持
#####3.3、集合运算符
######（1）简单“集合”运算符
######（2）对象运算符:distinctUnionOfObjects、unionOfObjects
######（3）Array和Set操作符:distinctUnionOfArrays、unionOfArrays
####4、KVC实现原理
####5、参考链接：https://github.com/garnett/DLIntrospection    关于runtime封装，写的很好<br>

##5、iOS客户端启动速度优化
###参考链接：https://gold.xitu.io/entry/589985df128fe10058f3f3c7

##6、保证线程安全的几种方式和性能对比.
###（项目中我们经常会在多线程情况下访问同一组变量或者我们有需要保持同步的需求，这就需要用到锁）

##7、dispatch_barrier_async 同 dispatch_barrier_sync异同。
###这是GCD中两个用来控制队列中任务执行顺序的函数，供大家参考。（demo6和demo7为同一个工程，可在上节的工程中找到相关示例代码）。

##8、APM实践

##9、Basic protocols 之 NSCoping协议 、 NSCoding协议 、NSMutableCopying协议
###1、copyWithZone: 
###2、mutableCopyWithZone:
###3、encodeWithCoder:和initWithCoder:
#### 参考链接：http://blog.csdn.net/developercenter/article/details/9630643
###4、实战案例：

##10、iOS路由设计与实现

##11、RunLoop详解

##12、Runtime详解(共6次)



    
