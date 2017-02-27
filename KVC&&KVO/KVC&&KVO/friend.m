//
//  friend.m
//  KVC&&KVO
//
//  Created by haoyu3 on 2017/1/23.
//  Copyright © 2017年 JessesWang. All rights reserved.
//

#import "friend.h"

@implementation children


@end

@implementation friend

#pragma mark - 键值校验

- (BOOL)validateFriendName:(id *)friendName error:(NSError **)outError {
    if(*friendName == nil) {
        NSLog(@"friendName的值是nil");
        return NO;
    }
    if([*friendName length] > 10 || [*friendName length] < 3) {
        NSLog(@"friendName的值长度不在3-10字节范围内");
        return NO;
    }
    return YES;
}


- (BOOL)validateName:(id *)name error:(NSError **)error {
    if (*name == nil) {
        return NO;
    }
    else if([*name length] > 10)
    {
        return NO;
    }
    else {
        *name = [*name localizedUppercaseString];
        return YES;
    }
}

/*
 KVO提供了value的校验API：（下面两个）
 -(BOOL)validateValue:(inout id  _Nullable __autoreleasing *)ioValue forKey:(NSString *)inKey error:(out NSError * _Nullable __autoreleasing *)outError
 - (BOOL)validateValue:(inout id  _Nullable __autoreleasing *)ioValue forKeyPath:(NSString *)inKeyPath error:(out NSError * _Nullable __autoreleasing *)outError
总结： 这两个方法允许我们对value指针指向的内容进行校验，检验过程，内部会调用-validate<Key>:error:方法。
 1、-validate<key>:error:方法说明：
   （1）若果内部没有实现该方法，则默认返回YES。
 
 2、这两个校验API作用：
    主要用来使用KVC赋值时，在赋值前校验将要赋值给指定key的值是否符合要求。例如本例中的需求：要求赋给friendName变量的值，（1）不能为空（2）长度在3-10字节长度范围内。
 3、键值验证用的非常少，几乎见不到，因为以上这些工作在set方法里就可以做到。所以适用场景不是很广，就学习下。
 ！！！：需要指出的是，KVC是不会自动调用键值验证方法的，就是说我们需要手动验证。但是有些技术，比如CoreData会自动调用。
 */

#pragma mark - 对数值和结构体类型的数据支持

/*
 苹果的KVC机制KVC可以自动的将“数值”或“结构体型”的数据打包或解包成NSNumber或NSValue对象
    什么时候返回的是NSNumber，什么时候返回的是NSValue？
    1、可以使用NSNumber的数据类型，都会返回NSNumber对象
 可以使用NSNumber的数据类型有：
 + (NSNumber *)numberWithChar:(char)value;
 + (NSNumber *)numberWithUnsignedChar:(unsigned char)value;
 + (NSNumber *)numberWithShort:(short)value;
 + (NSNumber *)numberWithUnsignedShort:(unsigned short)value;
 + (NSNumber *)numberWithInt:(int)value;
 + (NSNumber *)numberWithUnsignedInt:(unsigned int)value;
 + (NSNumber *)numberWithLong:(long)value;
 + (NSNumber *)numberWithUnsignedLong:(unsigned long)value;
 + (NSNumber *)numberWithLongLong:(long long)value;
 + (NSNumber *)numberWithUnsignedLongLong:(unsigned long long)value;
 + (NSNumber *)numberWithFloat:(float)value;
 + (NSNumber *)numberWithDouble:(double)value;
 + (NSNumber *)numberWithBool:(BOOL)value;
 + (NSNumber *)numberWithInteger:(NSInteger)value NS_AVAILABLE(10_5, 2_0);
 + (NSNumber *)numberWithUnsignedInteger:(NSUInteger)value NS_AVAILABLE(10_5, 2_0);
 
 ***总之就是一些常见的数值型数据。***
 
    2、NSValue主要用于处理结构体类型的数据。
 
 + (NSValue *)valueWithCGPoint:(CGPoint)point;
 + (NSValue *)valueWithCGSize:(CGSize)size;
 + (NSValue *)valueWithCGRect:(CGRect)rect;
 + (NSValue *)valueWithCGAffineTransform:(CGAffineTransform)transform;
 + (NSValue *)valueWithUIEdgeInsets:(UIEdgeInsets)insets;
 + (NSValue *)valueWithUIOffset:(UIOffset)insets NS_AVAILABLE_IOS(5_0);
 只有有限的6种而已！那对于其它自定义的结构体怎么办？别担心，任何结构体都是可以转化成NSValue对象的，具体实现方法参见我之前的一篇文章：
 http://blog.csdn.net/wzzvictory/article/details/8614433
 
 小提示：为什么对于数据类型要转换成NSNumber或者NSValue？
    因为OC中常用的数据容器，例如：NSArrey和NSDictionary等，只能处理“对象”级别的数据类型，对于c中许多数据类型，int、float等是无法直接处理的，针对这种问题，OC提供了NSNumber 和 NSValue将C中的基本数据类型转化成OC可以直接处理的对象。
    例如：NSArray *arr = [[NSArray alloc] initWithObjects:@"1",1, nil];这行代码是无法编译的。
 
 */

#pragma mark - 集合运算符
/*
 集合运算符是一个特殊的keyPath，可以作为参数传给valueForKeyPath:,注意：只能是传给valueForKeyPath:不是valueForKey:
 语法格式：运算符是以@开头的特殊字符串。
 集合.@集合运算符.属性 <==>(Left key path . collection operator .Right key path)

 */


//1、简单集合运算符 共有5种：@avg @count @max @min @sum

- (void)simpleCollectionOperator {
    NSMutableArray *array1 = [NSMutableArray array];
    for (NSInteger i= 0; i<3; i++) {
        children *c = [children new];
        c.age = i*5;
        c.boyName = @"haoyu";
        [array1 addObject:c];
    }
    NSNumber *avgNumber = [array1 valueForKeyPath:@"@avg.age"];
    NSLog(@"array1数组中对象的age属性的平均值是====%@",avgNumber);
    
    NSNumber *count = [array1 valueForKeyPath:@"@count"];
    NSLog(@"array中元素的数目===%@",count);
}

//2、对象运算符,能够以数组的方式返回指定的内容：@distinctUnionOfObjects，@unionOfObjects
//它们的返回值都是NSArray，区别是前者返回的元素都是唯一的，是去重以后的结果；后者返回的元素是全集。


- (void)ObjcCollectionOperator {
    NSMutableArray *array1 = [NSMutableArray array];
    for (NSInteger i= 0; i<5; i++) {
        children *c = [children new];
        c.boyName = @"july";
        if(i % 2 == 0) {
            c.boyName = @"peter";
        }
        [array1 addObject:c];
    }
    NSArray *distinctUnion = [array1 valueForKeyPath:@"@distinctUnionOfObjects.boyName"];
    NSLog(@"去重后的数组元素数目====%@",distinctUnion);
    NSArray *unionArray = [array1 valueForKeyPath:@"@unionOfObjects.boyName"];
    NSLog(@"未去重后的数组元素数目====%@",unionArray);
}


//3、Array 和 Set操作符:有以下三种，前两个针对的集合是Arrays，后一个针对的集合是Sets。因为Sets中的元素本身就是唯一的，所以没有对应的@unionOfSets操作符。
/*
 @distinctUnionOfArrays
 @unionOfArrays
 @distinctUnionOfSets
 */

- (void)ArrayAndSetCollectionOperator {
    NSMutableArray *arrayTop = [NSMutableArray array];
    NSMutableArray *array1 = [NSMutableArray array];
    for (NSInteger i= 0; i<5; i++) {
        children *c = [children new];
        c.boyName = @"july";
        if(i % 2 == 0) {
            c.boyName = @"peter";
            c.age = i;
        }
        [array1 addObject:c];
    }
    NSMutableArray *array2 = [NSMutableArray array];
    for (NSInteger i= 0; i<5; i++) {
        children *c = [children new];
        c.boyName = @"july2";
        if(i % 2 == 0) {
            c.boyName = @"peter2";
        }
        [array2 addObject:c];
    }
    
    [arrayTop addObject:array1];
    [arrayTop addObject:array2];
//    children *c = [children new];
//    c.boyName = @"july3";
//    [arrayTop addObject:c];
//
    NSArray *distinctUnionObject = [arrayTop valueForKeyPath:@"@distinctUnionOfObjects.boyName"];
    NSLog(@"去重后的数组元素数目====%@",distinctUnionObject);
    NSArray *unionObject = [arrayTop valueForKeyPath:@"@unionOfObjects.boyName"];
    NSLog(@"未去重后的数组元素数目====%@",unionObject);
    
    
//    NSArray *distinctUnionArray = [arrayTop valueForKeyPath:@"@distinctUnionOfArrays.boyName"];
//    NSLog(@"去重后的数组元素数目====%@",distinctUnionArray);
//    NSArray *unionArray = [arrayTop valueForKeyPath:@"@unionOfArrays.boyName"];
//    NSLog(@"未去重后的数组元素数目====%@",unionArray);
}

/*
 1、@distinctUnionOfArrays :会遍历集合中的所有元素（也就是集合），对每一个集合执行@distinctUnionOfObjects:,将得到的结果放到一个数组中返回。对得到的结果中重复的会再做一次去重。
 2、@unionOfArrays:同上，会遍历所有集合，并对每个集合执行unionOfOnbjects:但是不做去重操作。
 3、这三种操作只对集合的集合生效。
 */
 
/*
 总结：
    (1)distinctUnionOfObjects\unionOfObjects的作用范围 > distinctUnionOfArrays\unionOfArrays，!!!:也就是说后者要求，集合中的元素必须是集合array或者set）。而前者可以是集合，也可以是普通对象。
    (2)如果distinctUnionOfObjects处理的元素是集合(array或者set)，会将这个集合（array或set）当做普通对象来处理。不会对集合内部的子元素进行操作。而且两个集合是相同的，像处理普通对象元素一样，也是可以成功去重。例如：2个相同的数组，会被去掉一个。
        返回结果：返回结果仍然是一个集合的集合。
    (3)distinctUnionOfArrays\unionOfArrays返回结果：就是一个一阶数组。
 */


#pragma mark - KVC实现原理

/*
    KVC实现是根据isa-swizzling技术实现的。
 */



#pragma mark - 参考文章
//http://www.cnblogs.com/zy1987/p/4616063.html
//http://blog.csdn.net/omegayy/article/details/7381301
//http://www.jianshu.com/p/104a811e8658
//下面的博客讲解较为详细，也可以参考官方开发文档，结合自己实际使用，才能真正有比较深刻的理解
//http://blog.csdn.net/wzzvictory/article/details/9674431

@end
