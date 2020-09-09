//
//  backtrace.c
//  backtrace
//
//  Created by 荣恒 on 2019/9/5.
//  Copyright © 2019 荣恒. All rights reserved.
//

#include "backtrace.h"

/// 主线程 ID 利用 C 构造函数设置
static mach_port_t _main_thread_id;

__attribute__((constructor)) static
void _setup_main_thread() {
    _main_thread_id = mach_thread_self();
}

/// 获取主线程 ID 
mach_port_t get_mach_main_thread() {
    return _main_thread_id;
}
