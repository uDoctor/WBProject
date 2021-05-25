//
//  FileManager.h
//  CheckAPP
//
//  Created by uDoctor on 2021/5/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FileManager : NSObject

- (void)writeToFileWithData:(NSData *)data file:(NSString *)path;

- (void)openFileWithPath:(NSString *)path;
@end

NS_ASSUME_NONNULL_END
