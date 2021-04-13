//
//  APIManager.m
//  CheckAPP
//
//  Created by uDoctor on 2021/3/29.
//

#import "APIManager.h"
#import <FMDB/FMDatabase.h>

#define BundlePath(name) [[NSBundle mainBundle] pathForResource:name ofType:@"txt"]

@interface APIManager()

@property (nonatomic, copy) NSArray *apiPaths;
@property (nonatomic, strong) NSHashTable *apiTable;
@property (nonatomic, strong) NSHashTable *publicApiTable;
@property (nonatomic, strong) NSHashTable *privateFrameWorkTable;
@property (nonatomic, strong) NSHashTable *surePrivateApiTable;
@property (nonatomic, strong) NSHashTable *whiteApiTable;

@end

@implementation APIManager

- (instancetype)init
{
    self = [super init];
    if (self) {
//        our_private_apis
        self.apiTable = [NSHashTable new];
        self.publicApiTable = [NSHashTable new];
        self.privateFrameWorkTable = [NSHashTable new];
        self.surePrivateApiTable = [NSHashTable new];
        self.whiteApiTable = [NSHashTable new];
        
        NSString *p0 = BundlePath(@"framework_private_apis");
        [self readPrivateFrameworkFromPath:p0 toTable:self.apiTable];
                
        NSString *p1 = BundlePath(@"document_apis");
        [self readPrivateFrameworkFromPath:p1 toTable:self.publicApiTable];
        
        NSString *p2 = BundlePath(@"private_framwork");
        [self readPrivateFrameworkFromPath:p2 toTable:self.privateFrameWorkTable];
        
        NSString *p3 = BundlePath(@"our_private_apis");
        [self readPrivateFrameworkFromPath:p3 toTable:self.surePrivateApiTable];
        
        NSString *p4 = BundlePath(@"white_apis");
        [self readPrivateFrameworkFromPath:p4 toTable:self.whiteApiTable];
        
    }
    return self;
}

- (void)addPrivateApis:(NSArray *)apis {
    if (apis.count > 0) {
        [apis enumerateObjectsUsingBlock:^(NSString *api, NSUInteger idx, BOOL * _Nonnull stop) {
            [self.surePrivateApiTable addObject:api];
        }];
    }
}

- (NSArray *)getPrivateApiArray {
    return self.apiTable.allObjects;
}

- (BOOL)checkPrivateApiWithApi:(NSString *)api {
    if ([api hasPrefix:@"set"]) {
        NSString *dealString = [api substringFromIndex:2];
        NSString *resultString = @"";
        if (dealString.length > 0) {
            resultString = [dealString stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:[[dealString substringToIndex:1] lowercaseString]];
            return [self checkPrivateApiWithApi:resultString];
        }
    }
    
//    self.apiTable.allObjects 避免重复调用allObjects
    if (api&&api.length>0&&self.apiTable.count>0) {
        if ([self.apiTable containsObject:api] && ![self.publicApiTable containsObject:api]) {
            /// 白名单中的字段不是私有的
            if ([self.whiteApiTable containsObject:api]) {
                return NO;
            } else {
                return YES;
            }
        } else {
            return NO;
        }
    } else {
        return NO;
    }
}


- (void)readPrivateFrameworkFromPath:(NSString *)path toTable:(NSHashTable*)table {
    NSFileHandle *fh = [NSFileHandle fileHandleForReadingAtPath:path];
    NSData *data = [fh readDataToEndOfFile];
    NSArray * apis = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] componentsSeparatedByString:@","];
    [fh closeFile];
    for (NSString *name in apis) {
        [table addObject:name];
    }
}

- (BOOL)checkPrivateFrameworkWithPath:(NSString *)path {
    // /System/Library/Frameworks/Foundation.framework/Foundation
    // /usr/lib/libobjc.A.dylib
    // /usr/lib/swift/libswiftCore.dylib
    if (path&&path.length>0&&self.privateFrameWorkTable.count>0&&([path containsString:@"/System"]||[path containsString:@"/usr"])) {
        NSString *framework = [path componentsSeparatedByString:@"/"].lastObject;
        if (framework.length>0 && [self.privateFrameWorkTable containsObject:framework]) {
            return YES;
        } else {
            return NO;
        }
    } else {
        return NO;
    }
}

- (BOOL)checkSurePrivateApi:(NSString *)api {
    if (api&&api.length>0&&self.surePrivateApiTable.count>0) {
        return [self.surePrivateApiTable containsObject:api];
    } else {
        return NO;
    }
}


/// 测试方法，不使用
- (void)addPrivateApisToWhiteApis:(NSArray *)apis {
    if (apis==nil || apis.count == 0) {
        return;
    }
    NSString *path = [NSString stringWithFormat:@"%@/%@",NSHomeDirectory(),@"Library/Caches/white_apis.txt"];
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm isWritableFileAtPath:path]) {
        NSLog(@"isWritableFileAtPath:%@",path);
    }
    NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:path];
    [apis enumerateObjectsUsingBlock:^(NSString *name, NSUInteger idx, BOOL * _Nonnull stop) {
        [fh writeData:[[name stringByAppendingString:@","] dataUsingEncoding:NSUTF8StringEncoding]];
    }];
    [fh closeFile];
}

@end
