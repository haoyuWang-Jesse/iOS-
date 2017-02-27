//
//  people.h
//  KVC&&KVO
//
//  Created by haoyu3 on 2017/1/19.
//  Copyright © 2017年 JessesWang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface people : NSObject



#pragma mark - setter
#pragma makr - 一、setValue:forKey:的搜索方式

/*
//1、当使用KVC赋值时(也就是setValue:forKey:) key对应的属性存在时：会直接调用属性的setter函数（setKey:方法），也就是说KVC在调用了setValue：forKey后，内部仍然是去调用了setter方法。
@property (nonatomic, strong) NSString *peopleName;
*/

/*
 //2、key对应的属性不存在时，则无setter方法，如果此时accessInstanceVariablesDirectly返回YES（注：这是NSKeyValueCodingCatogery中实现的类方法，默认实现为返回YES），会按_key、_isKey、key、isKey的顺序搜索遍历成员名。
 
{
//    NSString *_peopleName;
//    NSString *_isPeopleName;
//    NSString *peopleName;
//    NSString *isPeopleName;
}
*/

/*
 3、经历了第二部，没有这四种的变量存在，则会调用setValue:forUndefinedKey: 此时可以重写该方法来保证程序不会crash，或者做特殊操作，例如利用该特性实现万能容器类。
 */

#pragma mark - getter
//对应.m中的1.3
/*
{
    NSString *peopleName;
}
*/
//@property (nonatomic, strong) NSArray *friends;
//@property (nonatomic, strong) NSSet *friends;

//@property (nonatomic, strong) NSMutableArray *friends;

/*
//对应.m文件中 二、5
{
    NSMutableArray *_friends;
    NSMutableArray *_isFriends;
    NSMutableArray *friends;
    NSMutableArray *isFriends;
}
*/

//private array 
@property (nonatomic, strong) NSMutableArray *privateArray;

//对应.m文件中 三、3
//{
//    NSMutableSet *_friendSet;
//    NSMutableSet *friendSet;
//    NSMutableSet *_isFriendSet;
//    NSMutableSet *isFriendSet;
//}
//@property (nonatomic, strong) NSMutableSet *friendSet;

@property (nonatomic, strong) NSMutableSet *privateSet;

@end
