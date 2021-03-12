//
//  ViewController.m
//  CheckAPP
//
//  Created by uDoctor on 2021/1/4.
//

#import "ViewController.h"
#import "ReadMachOManager.h"
#import "Downloader.h"

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
@property (nonatomic, copy) NSArray *apiArray;
@property (nonatomic, assign) MatchRule rule;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.dataArray = [NSMutableArray new];
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
        ReadMachOManager *read = [ReadMachOManager new];
        read.delagate = self;
        [read analysisMachoWithData:fileData];
        [self startProgress];
    }
}

- (void)downloadClick {
    
    
    self.apiArray = @[@"JSPatch",
                     @"LSApplicationWorkspace",
                     @"zcm_im_false_message_click",
                     @"defaultWorkspace",
                     @"openSensitiveURL:withOptions:",
                     @"ToSwift",
                     @"OBSwiftTClass2",
                     @"obTestSwiftMethod",
                     @"_privateMethod",
                     @"发送的消息被服务器端处理为静默消息(MsgSilenceError)"];
    [self.apiTableView reloadData];
    return;
    Downloader * loader = [[Downloader alloc] init];
    NSString *urlstr = @"http://localhost:8080/TestWebPro/PrivateApi";
    [loader dowmloadDataWith:urlstr success:^(id  _Nonnull response, NSArray * _Nonnull array) {
        self.apiArray = array;
    } fail:^(NSError * _Nonnull error) {
        //dispatch_semaphore_signal(_semaPhore);
    }];
}

#pragma mark ------- ReadMachOManagerDelagate
- (void)manager:(ReadMachOManager *)manager field:(NSString *)field {
    if (field.length > 3) {
        [self.apiArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            // contains
            if (self.rule == MatchRuleContains) {
                if ([field containsString:(NSString*)obj] ) {
                    [self.dataArray addObject:field];
                }
            } else {
                //equel
                if ([field isEqualToString:(NSString*)obj]) {
                    [self.dataArray addObject:field];
                }
            }
            
            
        }];
    }
}

- (void)readFinished {
    if (self.dataArray.count == 0) {
        [self.dataArray addObject:@"no private API"];
    }
    [self.tableView reloadData];
    [self stopProgress];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    if (tableView == self.apiTableView) {
        return  self.apiArray.count;
    }
    return  self.dataArray.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (tableView == self.apiTableView) {
        return  self.apiArray[row];
    }
    return self.dataArray[row];
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
















////
////  ViewController.m
////  CheckAPP
////
////  Created by uDoctor on 2021/1/4.
////
//
//#import "ViewController.h"
//#import "ReadMachOManager.h"
//#import "Downloader.h"
//#import "CheckViewController.h"
//
//@interface ViewController()<ReadMachOManagerDelagate, NSTableViewDelegate, NSTableViewDataSource>
//@property (nonatomic, strong) NSButton *downloadBtn;
//@property (nonatomic, strong) NSButton *selectBtn;
//@property (nonatomic, strong) NSButton *addBtn;
//@property (nonatomic, strong) NSMutableArray *dataArray;
//@property (nonatomic, strong) NSTableView *tableVeiw;
//@property (nonatomic, strong) NSScrollView * scrollView;
//
//@property (nonatomic, copy) NSArray *apiArray;
//@property (nonatomic, strong) NSTableView *apiTableVeiw;
//@property (nonatomic, strong) NSScrollView * apiScrollView;
//@end
//
//@implementation ViewController
//
//- (void)viewDidLoad {
//    [super viewDidLoad];
//    self.dataArray = [NSMutableArray new];
//    [self setupViews];
//
//}
//
//- (void)selectFile {
////    CheckViewController *vc = [[CheckViewController alloc] init];
////    [self presentViewController:vc animator:nil];
//    NSOpenPanel *panel = [[NSOpenPanel alloc] init];
//    [panel setTitle:@"选择"];
//    panel.canChooseFiles = YES;
//    NSModalResponse reponse = [panel runModal];
//    if (reponse == NSModalResponseOK) {
//        for (NSString *path in [panel URLs]) {
//            NSLog(@"%@",path);
//
//        }
//        NSError *error = nil;
//        NSURL *url = [panel URLs].firstObject;
//        NSFileHandle *fh = [NSFileHandle fileHandleForReadingFromURL:url error:&error];
//        if (error) {
//            NSLog(@"open file error: %@",error);
//        }
//        NSData *fileData = [fh readDataToEndOfFile];
//        ReadMachOManager *read = [ReadMachOManager new];
//        read.delagate = self;
//        [read analysisMachoWithData:fileData];
//    }
//}
//
//- (void)downloadClick {
//
//
//    self.apiArray = @[@"https://",
//                     @"setBindUserIdQueue",
//                     @"zcm_im_false_message_click",
//                     @"scene:willConnectToSession:options:",
//                     @"OCclick",
//                     @"ToSwift",
//                     @"OBSwiftTClass2",
//                     @"obTestSwiftMethod",
//                     @"_privateMethod",
//                     @"发送的消息被服务器端处理为静默消息(MsgSilenceError)"];
//    [self.apiTableVeiw reloadData];
//    return;
//    Downloader * loader = [[Downloader alloc] init];
//    NSString *urlstr = @"http://localhost:8080/TestWebPro/PrivateApi";
//    [loader dowmloadDataWith:urlstr success:^(id  _Nonnull response, NSArray * _Nonnull array) {
//        self.apiArray = array;
//    } fail:^(NSError * _Nonnull error) {
//        //dispatch_semaphore_signal(_semaPhore);
//    }];
//}
//
//#pragma mark ------- ReadMachOManagerDelagate
//- (void)manager:(ReadMachOManager *)manager field:(NSString *)field {
//    if (field.length > 3) {
//        [self.apiArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//            // [(NSString*)obj containsString:field]
//            if ([field containsString:(NSString*)obj] ) {
//                [self.dataArray addObject:field];
//            }
//        }];
//    }
//}
//
//- (void)readFinished {
//    [self.tableVeiw reloadData];
//}
//
//- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
//    if (tableView == self.apiTableVeiw) {
//        return  self.apiArray.count;
//    }
//
//    return  self.dataArray.count;
//}
//
//- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
//    if (tableView == self.apiTableVeiw) {
//        return  self.apiArray[row];
//    }
//
//    return self.dataArray[row];
//}
//-(CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row{
//    return 30;
//}
//
////- (NSCell *)tableView:(NSTableView *)tableView dataCellForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
////    if (tableColumn == nil) {
////        NSCell * cell = [[NSCell alloc] init];
////        [cell setTitle:@"qwertyuiuytrewq"];
////        return cell;
////    }
////    return nil;
////
////}
//
//- (void)viewDidLayout {
//    NSLog(@"viewDidLayout:%@",NSStringFromRect(self.view.bounds));
//}
//- (void)viewWillLayout {
//    NSLog(@"viewWillLayout:%@",NSStringFromRect(self.view.bounds));
//
////    CGFloat by = CGRectGetMaxY(apis_r) + 20;
//    NSRect tv_r = self.view.bounds;
//    tv_r.origin.x = 200;
//    tv_r.origin.y = 10;
//    tv_r.size.width -= (200+10);
//    tv_r.size.height = (tv_r.size.height/2.f -10);
//    self.scrollView.frame = tv_r;
//
//    CGFloat apiy = CGRectGetMaxY(tv_r) + 20;
//    NSRect apis_r = self.view.bounds;
//    apis_r.origin.x = tv_r.origin.x;
//    apis_r.origin.y = apiy;
//    apis_r.size.width = tv_r.size.width;
//    apis_r.size.height = (tv_r.size.height - 10);
//    self.apiScrollView.frame = apis_r;
//
//    CGFloat selectbtn_y = (CGRectGetMaxY(self.scrollView.frame) + CGRectGetMinY(self.scrollView.frame))/2;
//    NSRect selectbtn_r = self.selectBtn.frame;
//    selectbtn_r.origin.y = selectbtn_y;
//    self.selectBtn.frame = selectbtn_r;
//
//    CGFloat dlbtn_y = (CGRectGetMaxY(self.apiScrollView.frame) + CGRectGetMinY(self.apiScrollView.frame))/2;
//    NSRect dlbtn_r = self.downloadBtn.frame;
//    dlbtn_r.origin.y = dlbtn_y;
//    self.downloadBtn.frame = dlbtn_r;
//
//}
//
//- (void)setupViews {
//
//    self.downloadBtn = [[NSButton alloc] initWithFrame:CGRectMake(30, 0, 100, 50)];
//    [self.downloadBtn setTitle:@"下载文件"];
//    [self.downloadBtn setAction:@selector(downloadClick)];
//    [self.downloadBtn setTarget:self];
//    [self.view addSubview:self.downloadBtn];
//
//    self.downloadBtn = [[NSButton alloc] initWithFrame:CGRectMake(30, 0, 100, 50)];
//    [self.downloadBtn setTitle:@"下载文件"];
//    [self.downloadBtn setAction:@selector(downloadClick)];
//    [self.downloadBtn setTarget:self];
//    [self.view addSubview:self.downloadBtn];
//
//    self.selectBtn = [[NSButton alloc] initWithFrame:CGRectMake(30, 0, 100, 50)];
//    [self.selectBtn setTitle:@"选择文件"];
//    [self.selectBtn setAction:@selector(selectFile)];
//    [self.selectBtn setTarget:self];
//    [self.view addSubview:self.selectBtn];
//
//    self.scrollView = [[NSScrollView alloc] init];
//    self.scrollView.hasVerticalScroller  = YES;
//    [self.view addSubview:self.scrollView];
//
//    self.tableVeiw = [[NSTableView alloc] initWithFrame:self.scrollView.bounds];
//    self.tableVeiw.delegate = self;
//    self.tableVeiw.dataSource = self;
//    NSTableColumn *cell = [[NSTableColumn alloc] initWithIdentifier:@"cell"];
//    [self.tableVeiw addTableColumn:cell];
//    [cell setWidth:self.scrollView.bounds.size.width];
//    [self.scrollView setDocumentView:self.tableVeiw];
//
//
//    self.apiScrollView = [[NSScrollView alloc] init];
//    self.apiScrollView.hasVerticalScroller  = YES;
//    self.apiScrollView.backgroundColor = [NSColor cyanColor];
//    [self.view addSubview:self.apiScrollView];
//
//    self.apiTableVeiw = [[NSTableView alloc] initWithFrame:self.apiScrollView.bounds];
//    self.apiTableVeiw.delegate = self;
//    self.apiTableVeiw.dataSource = self;
//    NSTableColumn *apicell = [[NSTableColumn alloc] initWithIdentifier:@"apicell"];
//    [self.apiTableVeiw addTableColumn:apicell];
//    [apicell setWidth:self.apiScrollView.bounds.size.width];
//    [self.apiScrollView setDocumentView:self.apiTableVeiw];
//
//
//
//
//}
//
//
//- (void)setRepresentedObject:(id)representedObject {
//    [super setRepresentedObject:representedObject];
//
//    // Update the view, if already loaded.
//}
//
//
//
//
////BOOL checkPrivateAPI(NSString *api) {
////    if (api== nil || api.length == 0) {
////        return NO;
////    }
////    NSArray *arr = @[@"https://",
////                     @"setBindUserIdQueue",
////                     @"zcm_im_false_message_click",
////                     @"scene:willConnectToSession:options:",
////                     @"OCclick",
////                     @"ToSwift",
////                     @"OBSwiftTClass2",
////                     @"obTestSwiftMethod",
////                     @"_privateMethod",
////                     @"发送的消息被服务器端处理为静默消息(MsgSilenceError)"];
////    if (_apiArray == nil||_apiArray.count == 0) {
////        printf("private api is nil !!!");
////        _apiArray = arr;
//////        exit(-1);
////    }
////    __block BOOL flag = NO;
////    [_apiArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
////        NSString *str = obj;
////        if ([str isEqualToString:api]) {
////            flag = YES;
////            *stop = YES;
////        }
////    }];
////    return flag;
////}
//
//
//@end
