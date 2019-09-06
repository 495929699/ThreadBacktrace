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

/**
 获取指定线程调用栈
 
 @return 返回结果为数组字典，每一个栈帧包含在字典中
 */
NSArray<NSDictionary *>* _Nonnull bs_backtraceOfNSThread(NSThread * _Nonnull thread);
