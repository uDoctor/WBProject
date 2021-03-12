//
//  MachOManager.m
//  CheckAPP
//
//  Created by uDoctor on 2021/1/5.
//

#import "ReadMachOManager.h"
#import "ReadMacho.hpp"
#import "Demangler.h"
using namespace OB;
@implementation ReadMachOManager

static ReadMachOManager *_manager = nil;
void mycallback(const char * cs, bool isSwift) {
    if ([_manager.delagate respondsToSelector:@selector(manager:field:)]) {
        NSString *field = [[NSString alloc] initWithCString:cs encoding:NSUTF8StringEncoding];
        if (isSwift) {
            
            [_manager.delagate manager:_manager field:[_manager methodStringFromDemangleString:swiftDemangleMethod(field, @"")]];
        } else {
            [_manager.delagate manager:_manager field:field];
        }
    }
}

void finishedback() {
    if ([_manager.delagate respondsToSelector:@selector(readFinished)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_manager.delagate readFinished];
        });
    }
}

- (void)analysisMachoWithData:(NSData *)fileData {
    _manager = nil;
    _manager = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        ReadMacho *macho = new ReadMacho(mycallback, false);
        macho->finished = finishedback;
        macho->readMachoWithData([fileData bytes]);
        
        delete macho;
    });
}

- (NSString *)methodStringFromDemangleString:(NSString *)demangleString {
    //过滤  Test_swift_oc_1.MainViewController.obTestSwiftMethod() -> ()
    if (![demangleString containsString:@"->"]) {
        return nil;
    }
    //  Test_swift_oc_1.MainViewController.obTestSwiftMethod()
    NSString *rawString = [demangleString componentsSeparatedByString:@"->"].firstObject;
    NSRange range = [rawString rangeOfString:@"("];
    if (range.length == 0 ) {
        return nil;
    }
    
    //  Test_swift_oc_1.MainViewController.obTestSwiftMethod(
    NSString * frontString = [rawString substringToIndex:range.location];
    
    if ([frontString rangeOfString:@"."].length == 0 ) {
        return nil;
    }
    
    //  obTestSwiftMethod(
    NSString *methodStr = [frontString componentsSeparatedByString:@"."].lastObject;
    if (methodStr.length <= 1) {
        return nil;
    }
    return [methodStr substringToIndex:methodStr.length];
}

@end
