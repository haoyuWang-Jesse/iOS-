//
//  SimaURLProtocol.m
//  ThreadAndCallStack
//
//  Created by haoyu3 on 2017/6/10.
//  Copyright © 2017年 sina. All rights reserved.
//

#import "SimaURLProtocol.h"

@implementation SimaURLProtocol

//实现2个类方法，2个实例方法

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    //告诉系统，这个网络请求会否要接管。
    return YES;
}


//重入：
//startloadding时设置一个标志配合canInitwithRequest：防止同一个网络请求重复进入

//优点：内容过滤 、 协议定制、静态资源管理、缓存管理、+配合UIWebView可做网络浏览器、所有的基于URL的请求都可以处理
//缺点：性能不好 1、发出网络：创建connection 、session 、request 2、NSURLProtocol 允许注册很多个，会有相互影响。从第一个注册开始一次询问，谁能处理这个网络请求。如果在startLoading时创建一个请求发出去，算不算一个新的请求。？
/*
 3、最大问题：缓存问题，需要很仔细处理。工作量很大
    重入问题：重入问题：用can和start来防止重入，但是实际开发中，有时没有走caninit直接到startloading，所以防重入需要在startloadding中防止重入
    client端线程和runloop mode问题：对同步调用，不存在线程改变和runloop mode变化问题。delegate调用时是异步的。这是它的线程和runloop有可能和客户端不一致了。这是虽然调用方法就可能会由于线程 和 runloop mode不一样：客户端一直等不到，一直等。  ？？
 
 除了webview，其他都不使用该方法。
 
 所以有了：method swizzling ,拦截住、调回去。
 定义一个类实际上是产生两个类，class 和 meta class
 
 1、原理
 2、基本步骤
 3、应用场景：1、允许我们对无源码的代码，做一定的修改 2、
 4、有点：
    缺点：
    1、可能引起死循环：调回去时，需要查表，查谁的表？那个类的表，self去找隐藏的类，self是谁创建的？当前类？不一定。可能是当前类的子类：有继承关系的两个类，同一个方法都被拦截了，不需要处理，不处理就会死循环。
    2、同第三方SDK冲突，对消息selector，cmd参数判断，导致出错。？？
    坑：
 5、改进：利用block：
    利用block实现imp：具体步骤如下：
    1、获取到原始IMP，保存到变量
    2、定义block，其中引用原始IMP，就为了调回去
    3、block转成imp
    4、目标方法直接替换掉就可以
 例子：优点：解决了死循环问题。这时往回调的时候，根本不是发消息了，前面发消息出现死循环，是因为二异性，一旦self是从子类来，就有二义性。因为子类也有同名方法，这里imp获得是就是一个指针，直接调回去，不用发消息了。不会出错。
        优点二：不需要查表了，性能提高了。
 method swizzling:针对的是类，这个类的实例都受到影响，有时不想所有类实例都受影响。只想拦截某个实例，所以就有了下面的技术：
 isa swizzling:
 特点：只针对一个对象
 原理：修改isa指针
 使用步骤：
    1、（动态）创建目标对象类的子类
    2、（动态）为子类添加方法
    3、修改目标对象的isa(怎样修改isa指针)
 应用场景：只影响一个对象，而不是一个类
 缺点：调用方法前会判断：isKindofclass：时必须特殊处理下，因为把isa修改掉了，可能就不走了。这是主要缺点。
 
 三个swizzling的共同特点： 要拦截的目标方法都知道，有几个参数，什么类型都事先知道，分别下对应的方法。如果：写一个方法，不管几个参数，都能处理？
 在32位时不是难题，参数都是通过栈来传递。有一种办法能达到目的：isa swizzling + NSProxy
 原理：基于OC的消息转发机制，给一个对象发消息，要是找不到，并不会立即抛出异常。实际上并不是立即抛出异常，会走几个方法。forwardingTargetForSelector，forwardingInvocation：等一套流程，给你机会去转发处理。
 NSProxy：经常应用到IOP，为什么选他？
    两个必须实现的实例方法：-(void)forwardInvocation:(NSInvocation*)invocation
                        -(nullable NSMethodSignatureForSelector *)methodSignatureForSelector:(SEL)sel
        一个可以实现的方法：+(BOOL)responseToSelector:(SEL)aSelector 、//不是强行的，但是最好事先，因为很多人会判断。
 
    优点：
    缺点：判断下，应对流程上的变化。
 
 
 fishhook:c层面上的拦截:iOS9后系统调用底层函数，就拦截不到了，我们自己调用底层函数还是可以拦截到。
 Runloop观察者(开始可结束有两个消息，监控这两个消息就知道转这一圈多长时间)/CADisplayLink：
    取栈：崩溃瞬间，栈就凝固了，但是卡顿不同：不见得反映真实情况，因为栈起起落落。

 sendEvent/addTarget:::
 
 WKwebview:
 听云：fishhook在iOS8时用来拦截tcp层数据。
 9以后拦截不了，自己的framework，每一次iOS启动时合并成一个cache。这样调用就不经过符号表了。
 c层拦截任意一个方法：
 
 
 
 swizzle的3种方式：
 1、method swizzling
 2、改进后的method swizzling
 3、isa swizzling
 
 关于swizzling的相关连载文章：
 1、isa swizzling http://www.nscookies.com/isa-swizzling/
 2、method swizzling http://www.nscookies.com/method-swizzling/
 3、isKindOfClass和isMemberOfClass: http://www.nscookies.com/runtime-objectmodel/
 4、http://ios.jobbole.com/88803/
 5、哈哈，把之前不是很理解的kvo的实现讲清楚了：http://blog.csdn.net/bravegogo/article/details/50699594
 感悟：知识还是需要不断的反复，只有不停的咀嚼，终有一天会明白的。还是那句老话：书读百遍，其义自见
 */

@end
