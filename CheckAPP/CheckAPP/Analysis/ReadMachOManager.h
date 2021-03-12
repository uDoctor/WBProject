//
//  MachOManager.h
//  CheckAPP
//
//  Created by uDoctor on 2021/1/5.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class ReadMachOManager;
@protocol ReadMachOManagerDelagate <NSObject>

- (void)manager:(ReadMachOManager *)manager field:(NSString *)field;
- (void)readFinished;


@end

@interface ReadMachOManager : NSObject

@property (nonatomic, weak) id<ReadMachOManagerDelagate> delagate;

- (void)analysisMachoWithData:(NSData *)fileData;



@end

NS_ASSUME_NONNULL_END
