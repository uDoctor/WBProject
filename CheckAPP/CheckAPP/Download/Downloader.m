//
//  Downloader.m
//  MachOCheck
//
//  Created by uDoctor on 2020/12/28.
//

#import "Downloader.h"

@implementation Downloader

//http://localhost:8080/TestWebPro/PrivateApi
- (void)dowmloadDataWith:(NSString *)urlString success:(void(^)(id response, NSArray *array))success fail:(void(^)(NSError *error))fail {
    
    if (urlString==nil || ![urlString hasPrefix:@"http"]) {
        return;
    }
//    NSURLSessionTaskDelegate
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
//    urlRequest
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionTask *task = [session dataTaskWithRequest:urlRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSString *reponseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"reponseString=[%@]",reponseString);
        if (error == nil) {
            NSArray *array = [reponseString componentsSeparatedByString:@","];
            success(reponseString, array);
        } else {
            fail(error);
        }
    }];
    [task resume];
}

@end
