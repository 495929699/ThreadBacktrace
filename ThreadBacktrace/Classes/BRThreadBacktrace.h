//
//  Boy-Rong.h

#import <Foundation/Foundation.h>

extern NSString * _Nonnull const BRBacktraceImageName;
extern NSString * _Nonnull const BRBacktraceAddress;
extern NSString * _Nonnull const BRBacktraceFuncName;
extern NSString * _Nonnull const BRBacktraceOffset;

/**
 获取指定线程调用栈
 
 @return 返回结果为数组字典，每一个栈帧包含在字典中
 */
NSArray<NSDictionary *>* _Nonnull br_backtraceOfNSThread(NSThread * _Nonnull thread);
