//
//  ViewController.m
//  CheckAPP
//
//  Created by uDoctor on 2021/1/4.
//

#import "ViewController.h"
#import "ReadMachOManager.h"
#import "Downloader.h"
#import "APIManager.h"

typedef enum : NSUInteger {
    MatchRuleEquel,
    MatchRuleContains
} MatchRule;


@interface ViewController()<ReadMachOManagerDelagate, NSTableViewDelegate, NSTableViewDataSource>
@property (weak) IBOutlet NSComboBox *comboBox;

@property (weak) IBOutlet NSButton *addBtn;
@property (weak) IBOutlet NSButton *downloadBtn;
@property (weak) IBOutlet NSButton *selectBtn;
//
@property (unsafe_unretained) IBOutlet NSTextView *addTextView;
@property (weak) IBOutlet NSProgressIndicator *progressbar;

@property (weak) IBOutlet NSTableView *apiTableView;
@property (weak) IBOutlet NSTableView *tableView;
@property (weak) IBOutlet NSTableView *permissionsTable;

@property (nonatomic, copy) NSDictionary *statementPermissionDict;
@property (nonatomic, strong) NSMutableArray *redPermissionsArray;
@property (nonatomic, strong) NSMutableArray *permissionsArray;

@property (nonatomic, strong) NSMutableArray *dataArray;
@property (nonatomic, strong) NSMutableArray *ocMethodsArray;
@property (nonatomic, strong) NSMutableArray *swiftMethodsArray;
@property (nonatomic, strong) NSMutableArray *sureArray;
@property (nonatomic, copy) NSArray *apiArray;

@property (nonatomic, assign) MatchRule rule;
@property (nonatomic, strong) APIManager *apiManager;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.dataArray = [NSMutableArray new];
    self.ocMethodsArray = [NSMutableArray new];
    self.sureArray = [NSMutableArray new];
    self.swiftMethodsArray = [NSMutableArray new];
    self.permissionsArray = [NSMutableArray new];
    self.redPermissionsArray = [NSMutableArray new];
    
    self.apiManager = [[APIManager alloc] init];
    [self setupViews];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showPrivateApis];
    });
    NSLog(@"apiCount=%ld",self.apiManager.apiCount);


}
#pragma mark ------- Click Event
- (void)addClick {
    if (self.addTextView.string.length > 0) {
        NSMutableArray *marr = [NSMutableArray arrayWithArray:self.apiArray];
        NSMutableArray *addMarr = [NSMutableArray new];
        if ([self.addTextView.string containsString:@","]) {
            NSArray *arr = [self.addTextView.string componentsSeparatedByString:@","];
            [arr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([(NSString*)obj length] > 0) {
                    [marr addObject:(NSString*)obj];
                    [addMarr addObject:(NSString*)obj];
                }
            }];
        } else {
            [marr addObject:[self.addTextView.string copy]];
        }
        self.apiArray = [marr copy];
        [self.apiManager addPrivateApis:[addMarr copy]];
        [self.apiTableView reloadData];
        self.addTextView.string = @"";

    }
}


- (void)selectFile {
    [self.dataArray removeAllObjects];
    [self.tableView reloadData];
    [self.redPermissionsArray removeAllObjects];
    [self.permissionsArray removeAllObjects];
    [self.permissionsTable reloadData];
    NSOpenPanel *panel = [[NSOpenPanel alloc] init];
    [panel setTitle:@"选择"];
    panel.canChooseFiles = YES;
    NSModalResponse reponse = [panel runModal];
    if (reponse == NSModalResponseOK) {
        for (NSString *path in [panel URLs]) {
            NSLog(@"%@",path);
            
        }
        NSError *error = nil;
        NSURL *url = [panel URLs].firstObject;
        if ([url.absoluteString hasSuffix:@".app"]) {
            
            [self readPermissionsWithPath:url.absoluteString];
            NSString *fileName = [url.absoluteString componentsSeparatedByString:@"/"].lastObject;
            NSString *appName = [fileName componentsSeparatedByString:@"."].firstObject;
            url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@",url.absoluteString,appName]];
        }
        NSFileHandle *fh = [NSFileHandle fileHandleForReadingFromURL:url error:&error];
        if (error) {
            NSLog(@"open file error: %@",error);
        }
        NSData *fileData = [fh readDataToEndOfFile];
        [self clearData];
        ReadMachOManager *read = [ReadMachOManager new];
        read.delagate = self;
        [read analysisMachoWithData:fileData];
        [self startProgress];
    }
}

- (void)showPrivateApis {
    self.apiArray = [self.apiManager getPrivateApiArray];
    [self.apiTableView reloadData];
}

- (void)clearData {
    [self.dataArray removeAllObjects];
    [self.ocMethodsArray removeAllObjects];
    [self.sureArray removeAllObjects];
}

- (void)readPermissionsWithPath:(NSString *)path {
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/info.plist",path]];
    NSError *error= nil;
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithContentsOfURL:url error:&error];
    if (error) {
        NSLog(@"error：%@",error);
    }
    self.statementPermissionDict = [dict copy];
    
    NSDictionary *permissionDict = [self.apiManager getPermissionDict];
    [permissionDict.allKeys enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([dict valueForKey:key]) {
            [self.permissionsArray addObject:[NSString stringWithFormat:@"%@-%@",key,dict[key]]];
        }
    }];
//    [self.permissionsTable reloadData];
    
}

#pragma mark ------- ReadMachOManagerDelagate
- (void)manager:(ReadMachOManager *)manager field:(NSString *)field type:(FieldType)type {
    if (field.length > 3) {
        switch (type) {
            case FieldTypeDylib:
                if ([self.apiManager checkPrivateFrameworkWithPath:field]) {
                    [self.dataArray addObject:[NSString stringWithFormat:@"[Dylib] %@",field]];
                }
                break;
            case FieldTypeCString:
                if ([self.apiManager checkSurePrivateApi:field]) {
                    [self.sureArray addObject:[NSString stringWithFormat:@"[String] %@",field]];
                } else if ([self.apiManager checkPrivateFrameworkWithPath:field]) {
                    [self.sureArray addObject:[NSString stringWithFormat:@"[String] %@",field]];
                } else if ([self.apiManager checkPrivateApiWithApi:field]) {
                    [self.dataArray addObject:[NSString stringWithFormat:@"[String] %@",field]];
                }
                break;
            case FieldTypeOCMethod:
                if ([self.apiManager checkSurePrivateApi:field]) {
                    [self.sureArray addObject:[NSString stringWithFormat:@"[OCMethod] %@",field]];
                } else if ([self.apiManager checkPrivateApiWithApi:field]) {
                    [self.ocMethodsArray addObject:[NSString stringWithFormat:@"[OCMethod] %@",field]];
                }
                break;
                
            case FieldTypeSwiftMethod:
                if ([self.apiManager checkSurePrivateApi:field]) {
                    [self.sureArray addObject:[NSString stringWithFormat:@"[SwiftMethod] %@",field]];
                } else if ([self.apiManager checkPrivateApiWithApi:field]) {
                    [self.swiftMethodsArray addObject:[NSString stringWithFormat:@"[SwiftMethod] %@",field]];
                }
                break;
            default:
                if ([self.apiManager checkPrivateApiWithApi:field]) {
                    [self.dataArray addObject:field];
                }
                
                break;
        }
    }
}

- (void)readFinished:(ReadMachOManager *)manager {
    if (self.dataArray.count == 0 &&  self.ocMethodsArray.count == 0&  self.sureArray.count == 0) {
        [self.dataArray addObject:@"no private API"];
    }
    NSLog(@"clsMethodDict%@",manager.clsMethodDict);
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        //去除自定义的oc方法
        for (NSString *method in [self.ocMethodsArray mutableCopy]) {
            NSString *name = [method componentsSeparatedByString:@" "].lastObject;
            
            [manager.clsMethodDict.allKeys enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL * _Nonnull stop) {
                NSArray *arr = [manager.clsMethodDict valueForKey:key];
                for (NSString *field in arr) {
                    if ([field isEqualToString:name]) {
                        [self.ocMethodsArray removeObject:method];
                    }
                }
            }];
        }
        //去除自定义的swift方法
        for (NSString *method in [self.swiftMethodsArray mutableCopy]) {
            NSString *name = [method componentsSeparatedByString:@" "].lastObject;
            
            [manager.clsMethodDict.allKeys enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL * _Nonnull stop) {
                NSArray *arr = [manager.clsMethodDict valueForKey:key];
                for (NSString *field in arr) {
                    if ([field isEqualToString:name]) {
                        [self.swiftMethodsArray removeObject:method];
                    }
                }
            }];
        }
        
        NSMutableArray *temp = [NSMutableArray new];
        [temp addObjectsFromArray:self.sureArray];
        [temp addObjectsFromArray:self.ocMethodsArray];
        [temp addObjectsFromArray:self.swiftMethodsArray];
        [temp addObjectsFromArray:self.dataArray];
        
        self.dataArray = [temp mutableCopy];
        
        [temp enumerateObjectsUsingBlock:^( NSString *str, NSUInteger index, BOOL * _Nonnull stop) {
            NSString *field = [str componentsSeparatedByString:@" "].lastObject;
            NSMutableString * replace = [NSMutableString stringWithString:str];
            [manager.clsMethodDict.allKeys enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL * _Nonnull stop) {
                NSHashTable *table = [manager.clsMethodDict valueForKey:key];
                if ([table containsObject:field]) {
                    [replace appendFormat:@" %@", key];
                }
            }];
            
            NSString *foot = [replace componentsSeparatedByString:str].lastObject;
            if (foot.length > 0) {
                NSString * obj = [NSString stringWithFormat:@"%@ [in classlist: %@]",str,foot];
                [self.dataArray replaceObjectAtIndex:index withObject:obj];
            } else {
                [self.dataArray replaceObjectAtIndex:index withObject:replace];
            }
        }];
        
        
        //检测权限
        NSDictionary *dict = [self.apiManager getPermissionDict];
        [dict.allKeys enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL * _Nonnull stop) {
            NSArray *cls_list = [dict[key] valueForKey:@"clsNames"];
            [cls_list enumerateObjectsUsingBlock:^(NSString *clsName, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([manager.allClass containsObject:clsName]) {
                    if (![self.statementPermissionDict valueForKey:key]) {
                        [self.redPermissionsArray addObject:[NSString stringWithFormat:@"%@-%@",key,[dict[key] valueForKey:@"des"]]];
                    }
                }
            }];
        }];
        
        
        NSMutableArray *temp1 = [NSMutableArray new];
        [temp1 addObjectsFromArray:self.redPermissionsArray];
        [temp1 addObjectsFromArray:self.permissionsArray];
        self.permissionsArray = [temp1 mutableCopy];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
            [self.permissionsTable reloadData];
            [self stopProgress];
            NSLog(@"%@",self.dataArray );
        });
    });
    
    
    


}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    if (tableView == self.apiTableView) {
        return  self.apiArray.count;
    } else if (tableView == self.permissionsTable) {
        return self.permissionsArray.count;
    }
    return  self.dataArray.count;
}


- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (tableView == self.apiTableView) {
        return [NSString stringWithFormat:@"%ld：%@",(long)row,self.apiArray[row]];
    } else if (tableView == self.permissionsTable) {
        return [NSString stringWithFormat:@"%ld：%@",(long)row,self.permissionsArray[row]];
    }
    return [NSString stringWithFormat:@"%ld：%@",(long)row,self.dataArray[row]];
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row {
    if (tableView == self.tableView) {
        NSTextFieldCell * _cell = cell;
        if (row < self.sureArray.count) {
           _cell.textColor = [NSColor redColor];
        } else if (row < self.sureArray.count + self.ocMethodsArray.count){
            _cell.textColor = [NSColor colorWithSRGBRed:243/255.f green:181/255.f blue:65/255.f alpha:1];
        } else {
            _cell.textColor = [NSColor blackColor];
        }
    } else if (tableView == self.permissionsTable){
        NSTextFieldCell * _cell = cell;
        if (row < self.redPermissionsArray.count) {
           _cell.textColor = [NSColor redColor];
        } else {
            _cell.textColor = [NSColor blackColor];
        }
    }
}

-(CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row{
    return 30;
}


dispatch_source_t timer;
- (void)startProgress {
    self.progressbar.hidden = NO;
    self.progressbar.indeterminate = NO;
    self.progressbar.style = NSProgressIndicatorStyleBar;
    
    timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC, 1 * NSEC_PER_SEC);
    dispatch_source_set_event_handler(timer, ^{
        self.progressbar.doubleValue += 10;
        if (self.progressbar.doubleValue >=100) {
            self.progressbar.doubleValue  = 0;
        }
    });
    dispatch_resume(timer);
}

- (void)stopProgress {
    
    self.progressbar.hidden = YES;
    self.progressbar.doubleValue = 100;
    dispatch_source_cancel(timer);
    timer = NULL;
}

- (void)setupViews {
   
    self.progressbar.hidden = YES;
    [self.addBtn setAction:@selector(addClick)];
    [self.addBtn setTarget:self];
    
    [self.selectBtn setAction:@selector(selectFile)];
    [self.selectBtn setTarget:self];

    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.apiTableView.delegate = self;
    self.apiTableView.dataSource = self;
    
    self.permissionsTable.delegate = self;
    self.permissionsTable.dataSource = self;
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
}

@end

