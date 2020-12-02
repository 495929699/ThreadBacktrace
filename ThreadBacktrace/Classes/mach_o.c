//
//  mach_o.c
//  ThreadBacktrace
//
//  Created by rongheng on 2020/11/19.
//

#include "mach_o.h"

#include <dlfcn.h>
#include <mach-o/loader.h>
#include <mach-o/dyld.h>
#include <mach-o/getsect.h>
#include <mach/mach.h>
#include <sys/types.h>
#include <malloc/malloc.h>

#include <objc/runtime.h>

#pragma mark - 平台定义
#ifdef __LP64__

typedef struct mach_header_64 mach_header_t;
typedef struct segment_command_64 segment_command_t;
typedef struct section_64 section_t;
typedef struct nlist_64 nlist_t;
typedef uint64_t uint_t;
typedef struct segment_command_64 segment_command_t;

#else

typedef struct mach_header mach_header_t;
typedef struct segment_command segment_command_t;
typedef struct section section_t;
typedef struct nlist nlist_t;
typedef uint32_t uint_t;
typedef struct segment_command segment_command_t;

#endif

static const char * text_segment = "__TEXT";
static const char * objc_classlist_section = "__objc_classlist";

typedef struct {
    Class objc;
    struct objc_method * method_list;
} objc_method_symbol;

/// 获取 Image ASLR
static uintptr_t _image_aslr(const uint32_t image_index) {
    return _dyld_get_image_vmaddr_slide(image_index);
}

/// 返回可执行文件的 Image 索引
static uint32_t _mach_execute_image(void) {
    uint32_t image_count = _dyld_image_count();
    for (uint32_t index = 0; index < image_count; index ++) {
        mach_header_t * mach_header = _dyld_get_image_header(index);
        if (mach_header->filetype == MH_EXECUTE) {
            return index;
        }
    }
    
    return UINT32_MAX;
}

static void _mach_objc_method_list(objc_method_symbol * class_method_list) {
    uint32_t image_index = _mach_execute_image();
    mach_header_t * image_header = _dyld_get_image_header(image_index);
    
    struct section * classlist_section = getsectbynamefromheader(image_header, text_segment, objc_classlist_section);
    
    printf("section address: %p\n", (uint_t)classlist_section);
    printf("section addvm: %p\n", classlist_section->addr);
    
    uint_t start_addr = classlist_section->addr;
    uint_t end_addr = start_addr + classlist_section->size;
    size_t len = sizeof(Class);
    uint_t class_count = ceill((end_addr - start_addr) / len);
    
    size_t class_list_count = sizeof(objc_method_symbol) * class_count;
    objc_method_symbol *symbol_list = malloc(class_list_count);
    
    for (uint_t addr = start_addr; addr <= end_addr; addr += len) {
        Class class = (Class)addr;
        struct objc_method_list * method_list = class->methodLists;
        
        int method_count = method_list->method_count;
        uint method_list_size = sizeof(struct objc_method) * method_count;
        struct objc_method * class_method_list = (struct objc_method *)malloc(method_list_size);
        
        for (int i = 0; i < method_count; i++) {
            struct objc_method method = method_list->method_list[0];
            class_method_list[i] = method;
        }
        
        objc_method_symbol *symbol = (objc_method_symbol *)malloc(sizeof(objc_method_symbol));
//        *symbol = { class, class_method_list };
        
        uint_t class_index = addr / len;
//        symbol_list[class_index] = symbol;
    }
    
    return ;
}
