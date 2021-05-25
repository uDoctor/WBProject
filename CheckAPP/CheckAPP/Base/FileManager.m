//
//  FileManager.m
//  CheckAPP
//
//  Created by uDoctor on 2021/5/24.
//

#import "FileManager.h"

@implementation FileManager

- (void)writeToFileWithData:(NSData *)data file:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:path]) {
        NSError *error = nil;
        BOOL isSuccess = [fileManager createFileAtPath:path contents:nil attributes:nil];
        NSLog(@"error = %@",error);
        NSLog(@"isSiccess = %d",isSuccess);
    }
    
    NSError *error = nil;
    NSFileHandle *fh = [NSFileHandle fileHandleForWritingToURL:[NSURL fileURLWithPath:path] error:&error];
    if (error) {
        NSLog(@"open file error: %@",error);
    }

    [fh truncateFileAtOffset:0];
    [fh writeData:data error:&error];
    if (error) {
        NSLog(@"write file error: %@",error);
    }
    [fh closeFile];
}


- (void)openFileWithPath:(NSString *)path {
    NSTask *openTask = [[NSTask alloc] init];
    [openTask setLaunchPath:@"/bin/sh"];
    [openTask setArguments:[NSArray arrayWithObjects:@"-c",[NSString stringWithFormat:@"%@", [NSString stringWithFormat:@"open %@",path]], nil]];
    [openTask launch];
    NSLog(@"文件地址：%@",path);
}
@end
