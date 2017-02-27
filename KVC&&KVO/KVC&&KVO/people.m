//
//  people.m
//  KVC&&KVO
//
//  Created by haoyu3 on 2017/1/19.
//  Copyright © 2017年 JessesWang. All rights reserved.
//

#import "people.h"






@implementation people
//@dynamic friends;
+(BOOL)accessInstanceVariablesDirectly {
    return YES;
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    NSLog(@"只要重写该方法，程序就不会crash");
}

- (id)valueForUndefinedKey:(NSString *)key {
    return @"";
}


#pragma makr - getter
#pragma makr - 二、valueForKey:的搜索方式

/*
 1.1、首先查找getKey,key,isKey方式查找getter方法
 */

//- (NSString *)getPeopleName {
//    return @"先查找get<Key>";
//}

//- (NSString *)peopleName {
//    return @"先查找<Key>";
//}

//- (NSString *)isPeopleName {
//    return @"再查找is<Key>";
//}


/*
 1.2、经过1，既没有属性，也没有相关上述三种getter方法，“这时系统会认为key的类型可能为NSArray类型”，则查找-countOf<Key>,-objectIn<Key>AtIndex:(或者<key>AtIndexs:二选一)。
 */

/*
- (NSUInteger)countOfFriends {
    return 3;
 }
 
- (NSString *)objectInFriendsAtIndex:(NSUInteger)index {
    return @"XXX";
 }
//或者实现下面的方法也可：二者必须实现其一
- (NSArray *)friendsAtIndexes:(NSIndexSet *)indexesm{
    return @[];
}
*/
//1.2.1 上面的三个方法没有找到，“系统会认为他有可能是set集合类型”，则搜索countOf<Key>、enumeratorOf<Key>、memberOf<Key>格式的方法,注意：必须同时实现下面这三个方法。
/*
- (NSUInteger)countOfFriends {
    return 3;
}

- (NSEnumerator *)enumeratorOfFriends {
    NSSet *set = [[NSSet alloc] initWithObjects:@"aaa",@"bbb",@"ccc", nil];
    NSEnumerator *enumerate = [set objectEnumerator];
    return enumerate;
}

- (id)memberOfFriends:(id)object {
    return object;
}
*/
/*
 1.3、以上都没查到，如果类方法accessInstanceVariablesDirectly返回YES，那么按_<key>、_<isKey>、<Key>、<isKey>顺序搜索成员变量，从中取值。
    查找顺序的验证：可以解开1.1中任意一个方法，然后在.h中添加成员变量，调用时setValue：forKey将值赋值给成员变量。然后调用valueForKey：发现得到的值还是"先查找get<Key>"。
 */
/*
 1.4、经过以上步骤都找不到，则会调用valueForUndefinedKey。同样可以重写该方法
 */

#pragma mark - 三、查找有序集合成员
/*
    1、查找NSArray：搜索countOf<Key>、objectsIn<Key>AtIndex:或者<Key>AtIndexs:
    2、查找NSMutableArray：
        （1）mutableArrayValueForKey查找顺序：countOf<Key>、objectsIn<Key>AtIndex:
 
 */
//- (NSUInteger)countOfFriends {
//    return [self.privateArray count];
//}
//
//- (NSString *)objectInFriendsAtIndex:(NSUInteger)index {
//    return [self.privateArray objectAtIndex:index];
//}


 //（2）set是的顺序：insertObject:in<Key>AtIndex:、removeObjectFrom<Key>AtIndex:、replace
 
//- (void)insertObject:(NSString *)object inFriendsAtIndex:(NSUInteger)index {
//    [self.privateArray addObject:object];
//    NSLog(@"NSMutableArray 这个方法需要实现");
//}
//
//- (void)removeObjectFromFriendsAtIndex:(NSUInteger)index {
//    [self.privateArray removeObjectAtIndex:index];
//    NSLog(@"NSMutableArray 这个方法也需要实现");
//}

/*
 //3、set操作时：如果经过2没有找到上面格式的函数，就查找set<Key>，调用这个方法时：是取出所有数据并修改后，使用set<Key>:赋值回去。这样做效率会差很多。
 
- (void)setFriends:(NSMutableArray *)friends {
    self.privateArray = friends;
    NSLog(@"没有找到insert、remove、则会调用set<Key>");
}
*/

/*
 //4、经过步骤3，都没找到则按照_<key>、_is<key>、<key>、is<Key>顺序搜索成员变量。
 //5、再没查到，调用valueForUndefinedKey:
 总结：
    1、通过KVC方式获取对象中的一个可变数组，使用mutableArrayValueForKey：查找方式：（1）先查找countOf<key>、objectsIn<Key>AtInedx:
 (2)查不到则查找_<key>、_is<key>、<key>、<isKey>变量，如果仍然查不到，则执行（3）valueForUndefinedKey:
    2、通过KVC方式设置对象的可变数组时，查找顺序为：（1）查找insert、remove(这两个方法必须同时实现)、replace(这是可选实现的)，如果查不到，则（2）查找set<key>格式函数。（3）若果还没找到，则查找_<key>、_is<key>、<key>、is<key>变量。若仍然没查到则查找（4）setValue:forUndefinedKey:
 */

#pragma mark 四、查找无序集合


/*
 //只考虑set时的查找顺序
 */

- (NSInteger)countOfFriendSet {
    return [self.privateSet count];
}

- (NSEnumerator *)enumeratorOfFriendSet {
    return [self.privateSet objectEnumerator];
}
- (id)memberOfFriendSet:(id)object {
    return [self.privateSet member:object];
}

/*
 // 1、add<Key>Object:、remove<key>Object(或者add<Key>:remove<Key>:)
 
- (void)addFriendSetObject:(NSString *)object {
    [self.privateSet addObject:object];
}

- (void)removeFriendSetObject:(NSString *)object {
    [self.privateArray removeObject:object];
}
 */
/*
// 2、上面格式的方法没有找到，则查找set<key>:这个方法，是先取出所有的数据，然后添加新的数据进去，最后将得到的结果，使用set<Key>重新赋值回去，也就是friendsSet。

- (void)setFriendSet:(NSMutableSet *)friendSet {
    [self.privateSet setSet:friendSet];
}
*/

/*
 //如果reciever是ManagedObejct，那么就不会继续搜索了。
 // 3、如果上面的方法都没有找到，则按_<key>、_is<key>、<key>、is<Key> 顺序查找成员名，找到则发送消息给这个成员处理。
 // 4、上面的都没找到，则执行setValue:forUndefinedKey:
 */

#pragma mark - 五、KVC提供的功能
//!!!Haoyu - 为了保证能够更加清晰的了解，关于KVC提供的功能代码，在新的类friend中实现.


@end
