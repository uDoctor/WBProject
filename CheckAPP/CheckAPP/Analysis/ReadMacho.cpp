//
//  ReadMacho.cpp
//  MachOCheck
//
//  Created by uDoctor on 2020/12/21.
//

#include "ReadMacho.hpp"
#include <typeinfo>
#include <unordered_map>



//using namespace std;
namespace OB {

void ReadMacho::readMachoWithData(const void *byte) {
    if (byte == NULL||strlen((const char*)byte) <= 0) {
        printf("no data!!!\n");
        exit(-1);
    }
    uint32_t magic;
    memcpy(&magic, byte, sizeof(uint32_t));
    switch (magic) {
        case FAT_MAGIC:
        case FAT_MAGIC_64:
            struct fat_arch f_arch_big;
            structFromBytes(f_arch_big, byte, sizeof(uint32_t)*2);
            readMachoWithData((const char*)byte+f_arch_big.offset);
            break;
        case FAT_CIGAM:
        case FAT_CIGAM_64:
            struct fat_arch f_arch_small;
            structFromBytes(f_arch_small, byte, sizeof(uint32_t)*2);
            readMachoWithData((const char*)byte+OSSwapInt32(f_arch_small.offset));
            break;
        case MH_MAGIC: // 32-bit - big
        case MH_CIGAM: // 32-bit - small
            printf("feature developing");
            break;
        case MH_MAGIC_64: // 64-bit - big
            printf("64-bit - big");
            analysisForArch_64_lc(byte);
            break;
        case MH_CIGAM_64: // 64-bit - small
            printf("64-bit - small");
            break;
        default:
            break;
    }
    
    
}


void ReadMacho::analysisForArch_64_lc(const void *byte) {
    //前mach_header_len字节是header
    u_int32_t mh_len = sizeof(struct mach_header_64);
//    NSRange range = NSMakeRange(0, mach_header_len);
    
    static mach_header_64 mh;
    memcpy(&mh, byte, mh_len);
//    printf("1-filetype = %u \n",mh.filetype);
    if (!(mh.filetype == 0x1 || mh.filetype == 0x2 || mh.filetype == 0x6) ) {
        printf("只支持 : MH_OBJECT|MH_EXECUTE|MH_DYLIB\n");
        exit(-1);
    }
    
    unsigned long lc_loc = mh_len;
    unsigned long lc_len = sizeof(struct load_command);
    struct load_command lc;
    for (; ;) {
        
        memcpy(&lc, (const char *)byte + lc_loc, lc_len);
        
        switch (lc.cmd) {
            case LC_SYMTAB:
                analysisForArch_64_symtab(byte, lc_loc);
                break;
                
            case LC_LOAD_DYLIB: // cmd = 12
                analysisForArch_64_lc_load_dylib(byte,lc_loc);
                break;
            case LC_SEGMENT_64: // cmd = 25
                analysisForArch_64_lc_secgment(byte,lc_loc);
                break;
                
            case LC_CODE_SIGNATURE:
                if (this->finished) {
                    this->finished();
                }
//                NSLog(@"data read finish");
                return;
                break;
            default:
//                NSLog(@"不支持 %u command",lc.cmd);
                break;
        }
        lc_loc += lc.cmdsize;
//        printf("2-cmd = %u \n",lc.cmd);
//        printf("2-cmdsize = %u \n",lc.cmdsize);
    }
}


void ReadMacho::analysisForArch_64_lc_secgment(const void *bytes, unsigned long loc) {
    struct segment_command_64 lc_segment;
    unsigned long len = sizeof(struct segment_command_64);
    memcpy(&lc_segment, (const char*)bytes + loc, len);
    
    unsigned long sec_loc = loc + len;
    if (this->need_log) {
        printf("\n segname = %s \n",lc_segment.segname);
    }
    if (strcmp(lc_segment.segname, "__PAGEZERO") == 0) {
        this->vmSize = lc_segment.vmsize;
    }
    std::unordered_map<std::string, std::string> map;
//    map["__text"] = "__TEXT";
    map["__const"]                  = "__TEXT";
    map["__objc_methname"]          = "__TEXT";
    map["__cstring"]                = "__TEXT";
    map["__objc_classname__TEXT"]   = "__TEXT";
    map["__cstring"]                = "__TEXT";
    map["__cstring"]                = "__TEXT";
    map["__swift5_types"]           = "__TEXT";
    map["__swift5_protos"]          = "__TEXT";
    
    for (int i = 0; i < lc_segment.nsects; i ++) {
        
        struct section_64 section;
        memcpy(&section, (const char*)bytes+sec_loc, sizeof(struct section_64));
        sec_loc += sizeof(struct section_64);
        if (map.find(section.sectname) == map.end()) {
//            continue;
        }
        if (this->need_log) {
            printf("%s : %s \n",section.segname, section.sectname);
        }
        //__swift5_proto 是emun的case，它没有name，只有parent，parent就是emun
        if (strcmp(section.sectname, "__swift5_types") == 0 ||
            strcmp(section.sectname, "__swift5_protos") == 0 ) {
            analysisForArch_64_lc_swift(bytes, section);
        } else {
            this->isSwiftMethod = false;
            std::string str = stringFromBytes((const char*)bytes + section.offset, section.size);
        }
    }
    
}

void ReadMacho::analysisForArch_64_lc_swift(const void *bytes, struct section_64 &section) {
    
    uint64_t index = section.offset;
    uint64_t endLoc = index + section.size;
    uint64_t point_offset = 0;
    while (index < endLoc) {
        int point_len = sizeof(char)*4;
        // 小端模式，不需要转换
        memcpy(&point_offset, ((const char*)bytes+index), point_len);
        uint64_t classOffset = index + point_offset - this->vmSize;
        swiftClassFormBytes(bytes, classOffset);
        index += point_len;
    }
}

void ReadMacho::swiftClassFormBytes(const void *bytes, uint64_t classOffset) {
    struct ob_swift_class swiftClass;
    int len = sizeof(struct ob_swift_class);
    memcpy(&swiftClass, (const char*)bytes+classOffset, len);
    printf("flags: %d - %d - %llu - %d - %d - %d\n",  swiftClass.flags,swiftClass.parent, swiftClass.reflectionFieldDescriptor+classOffset+4*4, swiftClass.numImmediateMembers, swiftClass.numberOfFields, swiftClass.fieldOffsetVector);
    uint64_t namePoint = swiftClass.mangledNameOffset;
    uint64_t nameoff = namePoint + 8 + classOffset - this->vmSize;
//    printf("%s \n", (const char*)bytes+nameoff);
    if (this->callback) {
        this->callback((const char*)bytes+nameoff, false);
    }
}

void ReadMacho::analysisForArch_64_lc_load_dylib(const void *bytes, unsigned long loc) {
    struct dylib_command dylib_cmd;
    structFromBytes(dylib_cmd, bytes, loc);
    union lc_str cur_lc_str = dylib_cmd.dylib.name;
    const char *name = (const char*)bytes + loc + cur_lc_str.offset;
//    printf("use dylib = %s \n",name);
    if (this->callback) {
        this->callback(name, false);
    }
}



//
template <typename T>
void ReadMacho::structFromBytes(T &t,const void *bytes,unsigned long loc) {
    unsigned long len = sizeof(T);
    memcpy(&t, (const char*)bytes + loc, len);
}

    
    
void ReadMacho::analysisForArch_64_symtab(const void *bytes, unsigned long loc) {
    struct symtab_command symtab;
    structFromBytes(symtab, bytes, loc);
    this->isSwiftMethod = true;
    stringFromBytes((const char*)bytes + symtab.stroff, symtab.strsize);
   
}

std::string ReadMacho::stringFromBytes(const void *bytes, unsigned long len) {
    if (len <= 0) {
//        printf("bytes is null !!!\n");
        return "";
    }
    unsigned long index = 0;
    const char *cstr = (const char*)bytes;
    std::string str = "";
    while (index < len) {
        unsigned char ch0 = *(cstr+index);
        unsigned char ch1 = *(cstr+index + 1);
        if (*(cstr+index) == 0x00 || ch0 > 127 ||(ch0 <= 127 && ch1 > 127) ) {
            index ++;
        } else {
            unsigned long c_len = strlen((cstr+index));
            str += (cstr+index);
            int i = 0;
            bool flag = true;
            while (i< c_len) { // 过滤地址
                unsigned char ch = *(cstr+index + i);
                if (ch > 127) {
                    flag = false;
                    break;
                } else {
                    flag = true;
                }
                i ++;
            }
            if (!flag) {
                index += c_len;
                continue;
            }
            if (this->callback) {
                this->callback((cstr+index), this->isSwiftMethod);
            }
            if (strlen((cstr+index)) > 2) {
                str += "<br>";
            }
            index += c_len;
        }
    }
    
    return str;
}


std::string ReadMacho::stringFromBytes2(const void *bytes, unsigned long len) {
    if (len <= 0) { return ""; }
    unsigned long index = 0;
    const char *cstr = (const char*)bytes;
    std::string str = "";
    while (index < len) {
        unsigned char ch0 = *(cstr+index);
        unsigned char ch1 = *(cstr+index + 1);
        if (*(cstr+index) == 0x00 || ch0 > 127 ||(ch0 <= 127 && ch1 > 127) ) {
            index ++;
        } else {
            if (ch0 == 0x5f && ch1 == 0x5f) {
                while (*(cstr+index) != 0x2C && index < len) {
                    str += (cstr+index);
                    index ++;
                }
            } else {
                index ++;
            }
        }
    }
    return str;
}




//std::string ReadMacho::demangleSwiftFuncName(char *funcName) {
//    int (*swift_demangle_getDemangledName)(const char *,char *,int ) = (int (*)(const char *,char *,int))dlsym(RTLD_DEFAULT, "swift_demangle_getDemangledName");
//
//    if (swift_demangle_getDemangledName) {
//        char *demangleName = (char *)malloc(CLASSNAME_MAX_LEN + 1);
//        int length = CLASSNAME_MAX_LEN + 1;
//        swift_demangle_getDemangledName([mangleName UTF8String],demangleName,length);
//        NSString *demangleNameStr = [NSString stringWithFormat:@"%s",demangleName];
//        free(demangleName);
//        return demangleNameStr;
//    }
//    return mangleName;
//}
//+ (NSString *)getDemangleName:(NSString *)mangleName{
//    int (*swift_demangle_getDemangledName)(const char *,char *,int ) = (int (*)(const char *,char *,int))dlsym(RTLD_DEFAULT, "swift_demangle_getDemangledName");
//
//    if (swift_demangle_getDemangledName) {
//        char *demangleName = (char *)malloc(CLASSNAME_MAX_LEN + 1);
//        int length = CLASSNAME_MAX_LEN + 1;
//        swift_demangle_getDemangledName([mangleName UTF8String],demangleName,length);
//        NSString *demangleNameStr = [NSString stringWithFormat:@"%s",demangleName];
//        free(demangleName);
//        return demangleNameStr;
//    }
//    return mangleName;
//}


//struct swiftObj {
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

};
