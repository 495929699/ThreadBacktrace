//
//  BSBacktraceLogger.h
//  BSBacktraceLogger
//
//  Created by 张星宇 on 16/8/27.
//  Copyright © 2016年 bestswifter. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * _Nonnull const BacktraceImageName;
extern NSString * _Nonnull const BacktraceAddress;
extern NSString * _Nonnull const BacktraceFuncName;
extern NSString * _Nonnull const BacktraceOffset;

@interface BSBacktraceLogger : NSObject

/**
 获取指定线程调用栈

 @param thread 要获取的线程
 @return 返回结果为字典数组，线程回调栈数据在字典中
 */
+ (nonnull NSArray<NSDictionary *> *)bs_backtraceOfNSThread:(nonnull NSThread *)thread;

@end

