//
//  Demangler.h
//  MachOCheck
//
//  Created by uDoctor on 2020/12/23.
//

#ifndef Demangler_h
#define Demangler_h
extern "C" {
/// 解析swift的方法名
/// @param string 原始未解析的方法
/// @param machoFileName macho文件的名字，用来筛选swift方法
NSString* demangleMethod(NSString *string,NSString *machoFileName);


/// 解析swift的方法名
/// @param string 原始未解析的方法
/// @param machoFileName macho文件的名字，用来筛选swift方法
NSString* swiftDemangleMethod(NSString *string,NSString *machoFileName);
}
#endif /* Demangler_h */
