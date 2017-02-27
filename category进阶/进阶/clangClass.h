//
//  clangClass.h
//  进阶
//
//  Created by haoyu3 on 2016/12/7.
//  Copyright © 2016年 haoyu3. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface clangClass : NSObject

- (void )printName;

@end

@interface clangClass (testHaoyu)

@property (nonatomic, strong) NSString *haoyuName;

- (void )printName;

@end
