//
//  Downloader.h
//  MachOCheck
//
//  Created by uDoctor on 2020/12/28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Downloader : NSObject

- (void)dowmloadDataWith:(NSString *)urlString success:(void(^)(id response, NSArray *array))success fail:(void(^)(NSError *error))fail;

@end

NS_ASSUME_NONNULL_END
