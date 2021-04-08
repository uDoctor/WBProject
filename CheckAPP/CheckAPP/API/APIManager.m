//
//  APIManager.m
//  CheckAPP
//
//  Created by uDoctor on 2021/3/29.
//

#import "APIManager.h"
#import <FMDB/FMDatabase.h>


#define DBPath @"/Library/Caches/mkj_private_apis.db"
@interface APIManager()

@property (nonatomic, copy) NSArray *apiPaths;
@property (nonatomic, strong) NSHashTable *apiTable;
@property (nonatomic, strong) NSHashTable *publicApiTable;
@property (nonatomic, strong) NSHashTable *privateFrameWorkTable;
@property (nonatomic, strong) NSHashTable *surePrivateApiTable;
@property (nonatomic, strong) FMDatabase *db;

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
        
        [self readDB];
        [self readApiFromFile];
        [self readPublicApiFromDB];
        NSString *p0 = [NSString stringWithFormat:@"%@/Library/Caches/private_framwork.txt",NSHomeDirectory()];
        [self readPrivateFrameworkFromPath:p0 toTable:self.privateFrameWorkTable];
        
        NSString *p1 = [NSString stringWithFormat:@"%@/Library/Caches/our_private_apis.txt",NSHomeDirectory()];
        [self readPrivateFrameworkFromPath:p1 toTable:self.surePrivateApiTable];
        
    }
    return self;
}
- (void)readDB {
    //
    //all_private_apis
    //all_private_apis             framework_private_apis
    //document_apis                private_framework_dump_apis
    //framework_dump_apis          white_list_apis
    //framework_header_apis
    NSString *path = [NSString stringWithFormat:@"%@%@",NSHomeDirectory(),DBPath];
    NSLog(@"path:%@",path);
    self.db = [[FMDatabase alloc] initWithPath:path];
    if ([self.db open]) {
        NSLog(@" open database ");
    } else {
        NSLog(@"fail to open database %@",self.db );
    }
}

- (BOOL)selectWithName:(NSString *)name {
    if (![self.db open]) { return NO; }
    // 查询
    NSString *sql = [NSString stringWithFormat:@"select * from framework_private_apis where api_name = '%@'",name];
    FMResultSet *rs = [self.db executeQuery:sql];
    NSUInteger size = 0;
    BOOL flag = NO;
    NSHashTable *table = [NSHashTable new];
    while ([rs next]) {
        size ++;
        int idNum = [rs intForColumnIndex:0];
        NSString *name = [rs stringForColumnIndex:1];
        NSString * className = [rs stringForColumnIndex:2];
        [table addObject:name];
        NSLog(@"%d-%@-%@",idNum,name,className);
        flag = YES;
    }
    return flag;
}


- (NSUInteger)apiCount {
    return self.apiTable.count;
}

- (void)readApiFromFile {
    if (![self.db open]) { return; }
    // 查询
    NSString *sql = [NSString stringWithFormat:@"select api_name from framework_private_apis"];
    FMResultSet *rs = [self.db executeQuery:sql];
    NSUInteger size = 0;
    NSHashTable *table = [NSHashTable new];
    while ([rs next]) {
        size ++;
        NSString *name = [rs stringForColumnIndex:0];
        [table addObject:name];
    }
    NSLog(@"size=%lu",size);
    self.apiTable = table;
  
}

- (void)readPublicApiFromDB {
    if (![self.db open]) {
        return;
    }
    // 查询
    NSString *sql = [NSString stringWithFormat:@"select api_name from document_apis"];
    FMResultSet *rs = [self.db executeQuery:sql];
    NSHashTable *table = [NSHashTable new];
    while ([rs next]) {
        NSString *name = [rs stringForColumnIndex:0];
        [table addObject:name];
    }
    self.publicApiTable = table;
}

- (NSArray *)getApiArray {
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
            return YES;
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


- (void)removeApiWithArray:(NSArray *)apis {
//    NSString *path =  [NSString stringWithFormat:@"%@/Library/Caches/apis1.txt",NSHomeDirectory()];
//    NSFileManager *fm = [NSFileManager defaultManager];
//    
//    [apis enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL * _Nonnull stop) {
//        [self.apiTable removeObject:obj];
//    }];
//    NSError *error;
//    if (![fm fileExistsAtPath:path]) {
//        if (![fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error]) {
//        }
//        if (error) {
//            NSLog(@"create Failed:%@",[error localizedDescription]);
//        }
//    }
//    
//    NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:path];
//
//    for (NSString *name in self.apiTable.allObjects) {
//        [fh writeData:[[name stringByAppendingString:@","] dataUsingEncoding:NSUTF8StringEncoding]];
//    }
//    [fm removeItemAtPath:self.apiPath error:&error];
//    if (error) {
//        NSLog(@"remove origin txt failed:%@",[error localizedDescription]);
//    }
//    [fm copyItemAtPath:path toPath:self.apiPath error:&error];
//    if (error) {
//        NSLog(@"copy Failed:%@",[error localizedDescription]);
//    }
//    
//    [fm removeItemAtPath:path error:&error];
//    if (error) {
//        NSLog(@"remove temp txt failed:%@",[error localizedDescription]);
//    }
//    [fh closeFile];
}

@end
