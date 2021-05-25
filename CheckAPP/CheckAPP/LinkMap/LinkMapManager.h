//
//  LinkMapManager.h
//  CheckAPP
//
//  Created by uDoctor on 2021/5/20.
//

#import <Foundation/Foundation.h>
#import "FileManager.h"
NS_ASSUME_NONNULL_BEGIN

@interface LinkMapManager : FileManager

- (void)readLinkMapWithFile:(NSURL *)url;

- (void)checkApiObjectFileWithApi:(NSArray<NSString*> *)apis;
@end

NS_ASSUME_NONNULL_END
