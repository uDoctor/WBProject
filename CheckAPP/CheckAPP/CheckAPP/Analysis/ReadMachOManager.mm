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

@interface ReadMachOManager()
/// 去重的table
@property (nonatomic, strong) NSHashTable *oneStrTable;

@end

@implementation ReadMachOManager

static ReadMachOManager *_manager = nil;
- (instancetype)init {
    self = [super init];
    if (self) {
        self.clsMethodDict = [NSMutableDictionary new];
        self.oneStrTable = [NSHashTable new];
    }
    return self;
}
void mycallback(const char * cs, StringType type) {
    if ([_manager.delagate respondsToSelector:@selector(manager:field:type:)]) {
        NSString *field = [[NSString alloc] initWithCString:cs encoding:NSUTF8StringEncoding];
        if (type == StringTypeSwiftMethod) {
            NSString *method = [_manager methodStringFromDemangleString:swiftDemangleMethod(field, @"")];
            if (![_manager.oneStrTable containsObject:method]) {
                [_manager.delagate manager:_manager field:method type:FieldTypeSwiftMethod];
                [_manager.oneStrTable addObject:method];
            }
        } else {
            [_manager.delagate manager:_manager field:field type:(FieldType)type];
        } 
    }
}

NSArray* getKeyValueFromStartEnd(NSString *origin,NSString *start,NSString *end,NSString *separate) {
    CGFloat loc = [origin rangeOfString:start].location + [origin rangeOfString:start].length;
    NSRange range = NSMakeRange(loc, [origin rangeOfString:end].location-loc);
    NSString * classMethod = [origin substringWithRange:range];
    return [classMethod componentsSeparatedByString:separate];
}

void callbackForStringTable(const char * cs) {
    NSString *field = [[NSString alloc] initWithCString:cs encoding:NSUTF8StringEncoding];
    if ([field containsString:@"-["] && [field containsString:@"]"]) {

        NSArray *keyValue = getKeyValueFromStartEnd(field,@"-[",@"]",@" ");
        NSString * cls = keyValue.firstObject;
        NSString * method = keyValue.lastObject;
        if (cls.length > 0 && method.length > 0) {
            [_manager.clsMethodDict setValue:cls forKey:method];
        }
    } else if ([field containsString:@"+["] && [field containsString:@"]"]) {
        NSArray *keyValue = getKeyValueFromStartEnd(field,@"+[",@"]",@" ");
        NSString * cls = keyValue.firstObject;
        NSString * method = keyValue.lastObject;
        if (cls.length > 0 && method.length > 0) {
            [_manager.clsMethodDict setValue:cls forKey:method];
        }
    }
    else if ([field containsString:@"_OBJC_IVAR_$"]) {
        NSString * classAndIvar = [field componentsSeparatedByString:@"_OBJC_IVAR_$"].lastObject;
        NSString *cls = [classAndIvar componentsSeparatedByString:@"."].firstObject;
        NSString *ivar = [classAndIvar componentsSeparatedByString:@"."].lastObject;
        if (cls.length > 0 && ivar.length > 0) {
            [_manager.clsMethodDict setValue:cls forKey:ivar];
        }
    }
}

void finishedback() {
    if ([_manager.delagate respondsToSelector:@selector(readFinished:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_manager.delagate readFinished:_manager];
        });
    }
}

- (void)analysisMachoWithData:(NSData *)fileData {
    _manager = nil;
    _manager = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        ReadMacho *macho = new ReadMacho(mycallback, false);
        macho->finished = finishedback;
        macho->callbackST = callbackForStringTable;
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
    NSArray *tmpArr = [frontString componentsSeparatedByString:@"."];
    NSString *methodStr = tmpArr.lastObject;
    NSString *cls = [tmpArr objectAtIndex:tmpArr.count-2]; //记录class
    if (methodStr.length <= 1) {
        return nil;
    }
    NSString *met = [methodStr substringToIndex:methodStr.length];
    if (cls.length > 0 && met.length > 0) {
        [_manager.clsMethodDict setValue:cls forKey:met]; //将class和method放入dict
    }
    return met;
}

@end
