//
//  LinkMapManager.m
//  CheckAPP
//
//  Created by uDoctor on 2021/5/20.
//


#import "LinkMapManager.h"

@interface LinkMapManager()

@property (nonatomic, strong) NSMutableArray *apiArray;
@property (nonatomic, strong) NSMutableArray *objectFileArray;

@end


@implementation LinkMapManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.objectFileArray = [NSMutableArray new];
        self.apiArray = [NSMutableArray new];
    }
    return self;
}


- (void)readLinkMapWithFile:(NSURL *)url {
    NSError *error = nil;
    NSFileHandle *fh = [NSFileHandle fileHandleForReadingFromURL:url error:&error];
    if (error) {
        NSLog(@"open file error: %@",error);
    }
    NSData *fileData = [fh readDataToEndOfFile];
    const char * cstr = [fileData bytes];
    NSUInteger index = 0;
    NSString *tempStr = nil;
    char carr[1024*16]; //防止扩容，定义一个较大的16k空间
    int carIndex = 0;
    
    BOOL isObjectFile = NO;
    BOOL isApi = NO;
    
    while (index < fileData.length) {
        @autoreleasepool {
            if (*(cstr+index) == '\n') {
                tempStr = [[NSString alloc] initWithBytes:carr length:carIndex encoding:NSUTF8StringEncoding];
                if (tempStr != nil) {
                    if ([tempStr containsString:@"# Object files:"]) {
                        isObjectFile = YES;
                    } else if ([tempStr containsString:@"# Sections:"]){
                        isObjectFile = NO;
                    } else if ([tempStr containsString:@"# Symbols:"]){
                        isApi = YES;
                    }
                    
                    if (isObjectFile) {
                        [self.objectFileArray addObject:tempStr];
                    }
                    if (isApi) {
                        [self.apiArray addObject:tempStr];
                    }
                }
                carIndex = 0;
            } else {
                carr[carIndex++] = *(cstr+index);
            }
            index ++;
        }
    }
    
}

- (void)checkApiObjectFileWithApi:(NSArray<NSString*> *)apis {
    NSMutableString *mstr = [[NSMutableString alloc]initWithString:@" "];
    for (NSString *api in apis) {
        [self.apiArray enumerateObjectsUsingBlock:^(NSString *str, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([str containsString:api]) {
                NSRange r1 = [str rangeOfString:@"\t["];
                NSRange r2 = [str rangeOfString:@"] "];
                NSRange r = NSMakeRange(r1.location + r1.length, r2.location-(r1.location + r1.length));
                NSString *subStr = [str substringWithRange:r];
                [mstr appendFormat:@"%@ : %@\n",api,self.objectFileArray[subStr.integerValue+1]];
            }
        }];
    }
    NSString *path = [NSString stringWithFormat:@"%@/%@",NSHomeDirectory(),@"Library/Caches/linkMap.txt"];

    [self writeToFileWithData:[mstr dataUsingEncoding:NSUTF8StringEncoding] file:path];
    [self openFileWithPath:path];
}

@end
