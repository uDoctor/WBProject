//
//  APIManager.h
//  CheckAPP
//
//  Created by uDoctor on 2021/3/29.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface APIManager : NSObject

@property (nonatomic,assign) NSUInteger apiCount;

- (BOOL)checkSurePrivateApi:(NSString *)api;
- (BOOL)checkPrivateApiWithApi:(NSString *)api;
- (BOOL)checkPrivateFrameworkWithPath:(NSString *)path;
- (NSArray *)getPrivateApiArray;

- (void)addPrivateApis:(NSArray *)apis;

@end

NS_ASSUME_NONNULL_END
