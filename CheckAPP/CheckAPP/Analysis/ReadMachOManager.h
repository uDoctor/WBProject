//
//  MachOManager.h
//  CheckAPP
//
//  Created by uDoctor on 2021/1/5.
//

#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    FieldTypeDylib,
    FieldTypeOCClass,
    FieldTypeOCMethod,
    FieldTypeSwiftClass,
    FieldTypeSwiftMethod,
    FieldTypeSwiftProperty,
    FieldTypeCString,
    FieldTypeOther
} FieldType;

@class ReadMachOManager;
@protocol ReadMachOManagerDelagate <NSObject>

- (void)manager:(ReadMachOManager *)manager field:(NSString *)field type:(FieldType)type;
- (void)readFinished:(ReadMachOManager *)manager;


@end

@interface ReadMachOManager : NSObject

@property (nonatomic, weak) id<ReadMachOManagerDelagate> delagate;
@property (nonatomic, strong) NSMutableDictionary *clsMethodDict;
@property (nonatomic, strong) NSHashTable *allClass;

- (void)analysisMachoWithData:(NSData *)fileData;



@end

NS_ASSUME_NONNULL_END
