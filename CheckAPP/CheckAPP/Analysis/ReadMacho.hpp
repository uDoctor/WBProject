//
//  ReadMacho.hpp
//  MachOCheck
//
//  Created by uDoctor on 2020/12/21.
//

#ifndef ReadMacho_hpp
#define ReadMacho_hpp

#include <stdio.h>
#import <mach-o/loader.h>
#include <string.h>
//#include <iostream>
#include <string>
#include <mach-o/fat.h>


//#ifdef __OBJC__
//#import <Foundation/Foundation.h>
////#import <UIKit/UIKit.h>
//#endif

typedef enum : int {
    StringTypeDylib,
    StringTypeOCClass,
    StringTypeOCMethod,
    StringTypeSwiftClass,
    StringTypeSwiftMethod,
    StringTypeSwiftProperty,
    StringTypeCString,
    StringTypeOther
} StringType;

typedef  void(*Callback)(const char *, StringType stringType);
typedef  void(*CBStringTable)(const char *);
typedef  void(*FinishCallback)();
namespace OB {
class ReadMacho {
public:
    
    FinishCallback finished;
    ReadMacho(Callback cb, bool needlog):callback(cb),need_log(needlog){};
    ReadMacho():callback(NULL){};
    ~ReadMacho(){
        this->callback = NULL;
        this->callbackST = NULL;
    };
    void readMachoWithData(const void *byte);
    
    std::string stringFromBytes(const void *bytes, unsigned long len);
    std::string stringFromBytes2(const void *bytes, unsigned long len);
    CBStringTable callbackST;

private:
    bool need_log = false;
    bool isFinished = false;
    Callback callback;
    StringType strType = StringTypeOther;
    uint64_t vmSize;
    void analysisForArch_64_lc(const void *byte);
        
    template <typename T>
    void structFromBytes(T &t,const void *bytes,unsigned long loc);
    
//    template <class T>
    void analysisForArch_64_lc_secgment(const void *byte,unsigned long loc);
    
    void analysisForArch_64_lc_load_dylib(const void *bytes, unsigned long loc);
    
    
    void analysisForArch_64_symtab(const void *bytes, unsigned long loc);
    
    void analysisForArch_64_lc_swift(const void *bytes, struct section_64 &section);
    void swiftClassFormBytes(const void *bytes, uint64_t classOffset);
    

    std::string demangleSwiftFuncName(char *funcName);
    
    
    
};


};
//void readMachoWithData(NSData * fileData);


#endif /* ReadMacho_hpp */

/**
 __TEXT：__const             swift的class，struct，protocol，emun的名
 __TEXT：__objc_methname     oc的方法名
 __TEXT：__cstring           常量字符串
 __TEXT：__objc_classname__TEXT oc的类名
 __TEXT：__swift5_reflstr__TEXT swift的属性名字
 
 lc_symtab  swift的方法名
 
 */


struct ob_fat_header {
    uint32_t    magic;      /* FAT_MAGIC or FAT_MAGIC_64 */
    uint32_t    nfat_arch;  /* number of structs that follow */
};

struct ob_mach_header_64 {
    uint32_t    magic;        /* mach magic number identifier */
    cpu_type_t    cputype;    /* cpu specifier */
    cpu_subtype_t    cpusubtype;    /* machine specifier */
    uint32_t    filetype;    /* type of file */
    uint32_t    ncmds;        /* number of load commands */
    uint32_t    sizeofcmds;    /* the size of all the load commands */
    uint32_t    flags;        /* flags */
    uint32_t    reserved;    /* reserved */
};

struct ob_segment_command_64 { /* for 64-bit architectures */
    uint32_t    cmd;        /* LC_SEGMENT_64 */
    uint32_t    cmdsize;    /* includes sizeof section_64 structs */
    char        *segname[16];    /* segment name */
    uint64_t    vmaddr;        /* memory address of this segment */
    uint64_t    vmsize;        /* memory size of this segment */
    uint64_t    fileoff;    /* file offset of this segment */
    uint64_t    filesize;    /* amount to map from the file */
    vm_prot_t    maxprot;    /* maximum VM protection */
    vm_prot_t    initprot;    /* initial VM protection */
    uint32_t    nsects;        /* number of sections in segment */
    uint32_t    flags;        /* flags */
};

struct ob_section_64 { /* for 64-bit architectures */
    char        sectname[16];    /* name of this section */
    char        segname[16];    /* segment this section goes in */
    uint64_t    addr;        /* memory address of this section */
    uint64_t    size;        /* size in bytes of this section */
    uint32_t    offset;        /* file offset of this section */
    uint32_t    align;        /* section alignment (power of 2) */
    uint32_t    reloff;        /* file offset of relocation entries */
    uint32_t    nreloc;        /* number of relocation entries */
    uint32_t    flags;        /* flags (section type and attributes)*/
    uint32_t    reserved1;    /* reserved (for offset or index) */
    uint32_t    reserved2;    /* reserved (for count or sizeof) */
    uint32_t    reserved3;    /* reserved */
};
struct ob_symtab_command {
    uint32_t    cmd;        /* LC_SYMTAB */
    uint32_t    cmdsize;    /* sizeof(struct symtab_command) */
    uint32_t    symoff;        /* symbol table offset */
    uint32_t    nsyms;        /* number of symbol table entries */
    uint32_t    stroff;        /* string table offset */
    uint32_t    strsize;    /* string table size in bytes */
};


struct ob_swift_class {
    uint32_t    flags;
    uint32_t    parent;
    uint32_t    mangledNameOffset;
    uint32_t    fieldTypesAccessor;
    uint32_t    reflectionFieldDescriptor;
    uint32_t    superClsRef;
    uint32_t    metadataNegativeSizeInWords;
    uint32_t    metadataPositiveSizeInWords;
    uint32_t    numImmediateMembers;
    uint32_t    numberOfFields;
    uint32_t    fieldOffsetVector;
};

//struct _ClassContextDescriptor: _ContextDescriptorProtocol {
//    var flags: Int32
//    var parent: Int32
//    var mangledNameOffset: Int32
//    var fieldTypesAccessor: Int32
//    var reflectionFieldDescriptor: Int32
//    var superClsRef: Int32
//    var metadataNegativeSizeInWords: Int32
//    var metadataPositiveSizeInWords: Int32
//    var numImmediateMembers: Int32
//    var numberOfFields: Int32
//    var fieldOffsetVector: Int32
//}


//segname= __PAGEZERO
//segname= __TEXT
//__TEXT:__text
//__TEXT:__stubs
//__TEXT:__stub_helper
//__TEXT:__const
//__TEXT:__objc_methname
//__TEXT:__cstring
//__TEXT:__ustring
//__TEXT:__objc_classname__TEXT
//__TEXT:__objc_methtype
//__TEXT:__swift5_typeref__TEXT
//__TEXT:__swift5_fieldmd__TEXT
//__TEXT:__swift5_reflstr__TEXT
//__TEXT:__swift5_types
//__TEXT:__swift5_protos
//__TEXT:__swift5_proto
//__TEXT:__entitlements
//__TEXT:__unwind_info
//__TEXT:__eh_frame
//segname= __DATA_CONST
