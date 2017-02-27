//
//  friend.h
//  KVC&&KVO
//
//  Created by haoyu3 on 2017/1/23.
//  Copyright © 2017年 JessesWang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface children : NSObject

@property (nonatomic, strong) NSString *father;

@property (nonatomic, strong) NSString *boyName;
@property (nonatomic, assign) NSInteger age;

@end




@interface friend : NSObject

@property (nonatomic, strong) NSString *friendName;

- (void)simpleCollectionOperator;
- (void)ObjcCollectionOperator;
- (void)ArrayAndSetCollectionOperator;
@end
