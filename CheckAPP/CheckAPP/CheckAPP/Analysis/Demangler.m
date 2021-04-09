//
//  Demangler.m
//  MachOCheck
//
//  Created by uDoctor on 2020/12/23.
//

#import <Foundation/Foundation.h>
#import <dlfcn.h>
#import "CheckAPP-Swift.h"


/// 解析swift的方法名
/// @param string 原始未解析的方法
/// @param machoFileName macho文件的名字，用来筛选swift方法
NSString* demangleMethod(NSString *string,NSString *machoFileName) {

    if (string.length <2) {
        return  string;
    }
    // _$xxxx
    string = [string substringFromIndex:2];

//    string = @"s15Test_swift_oc_110OBResponstC12responseCodeSiSgvM";
    NSString *bitcodeCmd = [NSString stringWithFormat:@"xcrun swift-demangle %@",string];
    //NSData *d = command(bitcodeCmd);
    NSData *d;
    NSString *rs = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
//    printf("%s\n",[rs UTF8String]);

    if ([rs containsString:@"--->"]) {
        NSString *swiftMethodString = [rs componentsSeparatedByString:@"--->"].lastObject;
        if (![swiftMethodString containsString:@"->"]) {
            return nil;
        }
        if (![swiftMethodString containsString:machoFileName]) {
            return nil;
        }
        NSRange machoFileNameRange = [swiftMethodString rangeOfString:machoFileName];
        NSInteger fromIndex = NSMaxRange(machoFileNameRange) + 1;
        NSString *needMethodString = [swiftMethodString substringFromIndex:fromIndex];

        NSString *objName = [needMethodString componentsSeparatedByString:@"."].firstObject;
        NSString *methodname = nil;
        if (objName==nil || objName.length == 0) {
            NSUInteger index = NSMaxRange([needMethodString rangeOfString:objName]) +1;
            methodname = [needMethodString substringFromIndex:index];
        } else {
            methodname = needMethodString;
        }

        if (![methodname containsString:@"("]) {
            return nil;
        }
        NSUInteger finalLen = [methodname rangeOfString:@"("].location;
        NSString *finalMethodname = [methodname substringToIndex:finalLen];
//        printf("%s === %s\n", [finalMethodname UTF8String],[needMethodString UTF8String]);
        return finalMethodname;
    }
    return nil;
}


NSString* swiftDemangleMethod(NSString *string,NSString *machoFileName) {
    
    DemanglerSwift *demangle = [[DemanglerSwift alloc] init];
    NSString *cs = [demangle getSwiftMethodDemangleWithName:string];
 
    return cs;
}


//
NSString* getDemangleName(NSString *mangleName) {

    int (*swift_demangle_getDemangledName)(const char *,char *,int ) = (int (*)(const char *,char *,int))dlsym(RTLD_SELF, "swift_demangle_getDemangledName");
    int CLASSNAME_MAX_LEN = 100;
    if (swift_demangle_getDemangledName) {
        char *demangleName = (char *)malloc(CLASSNAME_MAX_LEN + 1);
        int length = CLASSNAME_MAX_LEN + 1;
        swift_demangle_getDemangledName([mangleName UTF8String],demangleName,length);
        NSString *demangleNameStr = [NSString stringWithFormat:@"%s",demangleName];
        free(demangleName);
        return demangleNameStr;
    }
    return mangleName;
}
