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
- (NSArray *)getApiArray;

- (void)addPrivateApis:(NSArray *)apis;
/// 删除本地数据源中的api 谨慎使用
- (void)removeApiWithArray:(NSArray *)apis;
@end

NS_ASSUME_NONNULL_END
