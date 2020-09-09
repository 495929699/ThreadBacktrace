//
//  backtrace.h
//  backtrace
//
//  Created by 荣恒 on 2019/9/5.
//  Copyright © 2019 荣恒. All rights reserved.
//

#ifndef backtrace_h
#define backtrace_h

#include <mach/mach.h>

/// 获取主线程 ID, 程序启动时 已初始化
mach_port_t get_mach_main_thread(void);

#endif
