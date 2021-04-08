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

@property (nonatomic, strong) NSMutableArray *dataArray;
@property (nonatomic, strong) NSMutableArray *ocMethodsArray;
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
    
    self.apiManager = [[APIManager alloc] init];
    
    NSLog(@"apiCount=%ld",self.apiManager.apiCount);
    [self setupViews];
 

}
#pragma mark ------- Click Event
- (void)addClick {
    if (self.addTextView.string.length > 0) {
        NSMutableArray *marr = [NSMutableArray arrayWithArray:self.apiArray];
        if ([self.addTextView.string containsString:@","]) {
            NSArray *arr = [self.addTextView.string componentsSeparatedByString:@","];
            [arr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([(NSString*)obj length] > 0) {
                    [marr addObject:(NSString*)obj];
                }
            }];
        } else {
            [marr addObject:[self.addTextView.string copy]];
        }
        self.apiArray = [marr copy];
        [self.apiTableView reloadData];
        self.addTextView.string = @"";

    }
}


- (void)selectFile {
    if (self.apiArray.count == 0) {
        [self downloadClick];
    }
    // contains
    if (self.comboBox.indexOfSelectedItem == 1) {
        self.rule = MatchRuleContains;
    } else { //equel
        self.rule = MatchRuleEquel;
    }
    [self.dataArray removeAllObjects];
    [self.tableView reloadData];
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

- (void)downloadClick {
    self.apiArray = [self.apiManager getApiArray];
    [self.apiTableView reloadData];
}

- (void)clearData {
    [self.dataArray removeAllObjects];
    [self.ocMethodsArray removeAllObjects];
    [self.sureArray removeAllObjects];
}

#pragma mark ------- ReadMachOManagerDelagate
- (void)manager:(ReadMachOManager *)manager field:(NSString *)field type:(FieldType)type {
    if (field.length > 3) {
        switch (type) {
            case FieldTypeDylib:
                if ([self.apiManager checkPrivateFrameworkWithPath:field]) {
                    [self.dataArray addObject:field];
                }
                break;
            case FieldTypeCString:
                if ([self.apiManager checkSurePrivateApi:field]) {
                    [self.sureArray addObject:field];
                } else if ([self.apiManager checkPrivateFrameworkWithPath:field]) {
                    [self.sureArray addObject:field];
                } else if ([self.apiManager checkPrivateApiWithApi:field]) {
                    [self.dataArray addObject:field];
                }
                break;
            case FieldTypeOCMethod:
                if ([self.apiManager checkSurePrivateApi:field]) {
                    [self.sureArray addObject:field];
                } else if ([self.apiManager checkPrivateApiWithApi:field]) {
                    [self.ocMethodsArray addObject:field];
                }
                break;
            default:
//                if ([self.apiManager checkPrivateApiWithApi:field]) {
//                    [self.dataArray addObject:field];
//                }
                break;
        }
    }
}

- (void)readFinished:(ReadMachOManager *)manager {
    if (self.dataArray.count == 0 &&  self.ocMethodsArray.count == 0) {
        [self.dataArray addObject:@"no private API"];
    }
    
    for (NSString *method in [self.ocMethodsArray mutableCopy]) {
        if ([manager.clsMethodDict valueForKey:method]) {
            [self.ocMethodsArray removeObject:method];
        }
    }
    NSMutableArray *temp = [NSMutableArray new];
    
    [temp addObjectsFromArray:self.sureArray];
    [temp addObjectsFromArray:self.ocMethodsArray];
    [temp addObjectsFromArray:self.dataArray];
    self.dataArray = temp;
//    self.dataArray = self.ocMethodsArray;
    [self.tableView reloadData];
    [self stopProgress];
//    if (self.dataArray.count > 0) {
//        [self.apiManager removeApiWithArray:self.dataArray];
//    }
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    if (tableView == self.apiTableView) {
        return  self.apiArray.count;
    }
    return  self.dataArray.count;
}


- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (tableView == self.apiTableView) {
        return [NSString stringWithFormat:@"%ld：%@",(long)row,self.apiArray[row]];
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
    
    [self.downloadBtn setAction:@selector(downloadClick)];
    [self.downloadBtn setTarget:self];
    
    [self.selectBtn setAction:@selector(selectFile)];
    [self.selectBtn setTarget:self];

    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.apiTableView.delegate = self;
    self.apiTableView.dataSource = self;
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
}

@end

