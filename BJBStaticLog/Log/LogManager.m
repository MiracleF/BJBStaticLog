//
//  LogManager.m
//  LogFileDemo
//
//  Created by xgao on 17/3/9.
//  Copyright © 2017年 xgao. All rights reserved.
//

#import "LogManager.h"
#import "ZipArchive.h"
//#import "RealTimeLogManager.h"
//#import "XGNetworking.h"

// 日志保留最大天数
static const int LogMaxSaveDay = 7;
// 日志文件保存目录
static const NSString* LogFilePath = @"/Documents/OTKLog/";
// 日志压缩包文件名
static NSString* ZipFileName = @"OTKLog.zip";

@interface LogManager()

// 日期格式化
@property (nonatomic,retain) NSDateFormatter* dateFormatter;
// 时间格式化
@property (nonatomic,retain) NSDateFormatter* timeFormatter;



@end

void uncaughtExceptionHandler(NSException *exception)
{
    
    NSArray *stackArry = [exception callStackSymbols];
    
    NSString *reason = [exception reason];
    
    NSString *name = [exception name];
    
    NSString *exceptionInfo = [NSString stringWithFormat:@"Exception name:%@\nException reatoin:%@\nException stack :%@", name, reason, stackArry];
    
    //保存到本地沙盒中
    LLog(@"Crash!", exceptionInfo);
}

@implementation LogManager

/**
 *  获取单例实例
 *
 *  @return 单例实例
 */
+ (instancetype) sharedInstance
{
    
    static LogManager* instance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!instance) {
            instance = [[LogManager alloc]init];
        }
    });
    
    return instance;
}

// 获取当前时间
+ (NSDate*)getCurrDate
{
    
    NSDate *date = [NSDate date];
    NSTimeZone *zone = [NSTimeZone systemTimeZone];
    NSInteger interval = [zone secondsFromGMTForDate: date];
    NSDate *localeDate = [date dateByAddingTimeInterval: interval];
    
    return localeDate;
}

#pragma mark - Init

- (instancetype)init{
    
    self = [super init];
    if (self) {
        
        // 创建日期格式化
        NSDateFormatter* dateFormatter = [[NSDateFormatter alloc]init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd"];
        // 设置时区，解决8小时
        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
        self.dateFormatter = dateFormatter;
        
        // 创建时间格式化
        NSDateFormatter* timeFormatter = [[NSDateFormatter alloc]init];
        [timeFormatter setDateFormat:@"HH:mm:ss"];
        [timeFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
        self.timeFormatter = timeFormatter;
        
        // 日志的目录路径
        self.basePath =
        //        @"/var/mobile/Media/MadridLog/";
        [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), LogFilePath];
        
        NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
        
//        [self checkLogNeedUpload];
    }
    return self;
}

#pragma mark - 日志操作

/**
 *  写入日志
 *
 *  @param module 模块名称
 *  @param logStr 日志信息,动态参数
 */
- (void)logInfo:(NSString*)module logStr:(NSString*)logStr, ...{
    
    NSMutableString* parmaStr = [NSMutableString string];
    // 声明一个参数指针
    va_list paramList;
    // 获取参数地址，将paramList指向logStr
    va_start(paramList, logStr);
    id arg = logStr;
    
    @try {
        // 遍历参数列表
        while (arg) {
            [parmaStr appendString:arg];
            // 指向下一个参数，后面是参数类似
            arg = va_arg(paramList, NSString*);
        }
        
    } @catch (NSException *exception) {
        
        [parmaStr appendString:@"【记录日志异常】"];
    } @finally {
        
        // 将参数列表指针置空
        va_end(paramList);
    }
    
    if ([module isEqualToString:@"Crash!"]) {
        
        // 崩溃时要同步执行
        dispatch_sync(dispatch_queue_create("writeLog", nil), ^{
            
            // 获取当前日期做为文件名
            NSString* fileName = [self.dateFormatter stringFromDate:[NSDate date]];
            NSString* filePath = [NSString stringWithFormat:@"%@%@",self.basePath,fileName];
            
            // [时间]-[模块]-日志内容
            NSString* timeStr = [self.timeFormatter stringFromDate:[LogManager getCurrDate]];
            NSString* writeStr = [NSString stringWithFormat:@"[%@]-[%@]-%@\n",timeStr,module,parmaStr];
            
            // 写入数据
            [self writeFile:filePath stringData:writeStr];
            
        });
        
    } else {
        // 异步执行
        dispatch_async(dispatch_queue_create("writeLog", nil), ^{
            
            // 获取当前日期做为文件名
            NSString* fileName = [self.dateFormatter stringFromDate:[NSDate date]];
            NSString* filePath = [NSString stringWithFormat:@"%@%@",self.basePath,fileName];
            
            // [时间]-[模块]-日志内容
            NSString* timeStr = [self.timeFormatter stringFromDate:[LogManager getCurrDate]];
            NSString* writeStr = [NSString stringWithFormat:@"[%@]-[%@]-%@\n",timeStr,module,parmaStr];
            
            // 写入数据
            [self writeFile:filePath stringData:writeStr];
            
        });
    }
}

/**
 *  清空过期的日志
 */
- (void)clearExpiredLog{
    
    // 获取日志目录下的所有文件
    NSArray* files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.basePath error:nil];
    for (NSString* file in files) {
        
        NSDate* date = [self.dateFormatter dateFromString:file];
        if (date) {
            NSTimeInterval oldTime = [date timeIntervalSince1970];
            NSTimeInterval currTime = [[LogManager getCurrDate] timeIntervalSince1970];
            
            NSTimeInterval second = currTime - oldTime;
            int day = (int)second / (24 * 3600);
            if (day >= LogMaxSaveDay) {
                // 删除该文件
                [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@",self.basePath,file] error:nil];
                NSLog(@"[%@]日志文件已被删除！",file);
            }
        }
    }
    
    
}


/**
 *  检测日志是否需要上传
 */
- (void)checkLogNeedUpload
{
    NSString* date = [self.dateFormatter stringFromDate:[NSDate date]];
    NSString* filePath = [NSString stringWithFormat:@"%@%@", self.basePath, date];
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if ([string containsString:@"Crash!"]) {
        //上传
        [self uploadLog:@{@"type" : @1,
                          @"dates" : @[date]
        }];
    }
}

#pragma mark - Private

/**
 *  处理是否需要上传日志
 *
 *  @param resultDic 包含获取日期的字典
 */
- (void)uploadLog:(NSDictionary*)resultDic{
    
    if (!resultDic) {
        return;
    }
    
    // 0不拉取，1拉取N天，2拉取全部
    int type = [resultDic[@"type"] intValue];
    // 压缩文件是否创建成功
    BOOL created = NO;
    if (type == 1) {
        // 拉取指定日期的
        
        // "dates": ["2017-03-01", "2017-03-11"]
        NSArray* dates = resultDic[@"dates"];
        
        // 压缩日志
        created = [self compressLog:dates];
    }else if(type == 2){
        // 拉取全部
        
        // 压缩日志
        created = [self compressLog:nil];
    }
    
    if (created) {
        // 上传
        [self uploadLogToServer:^(BOOL boolValue) {
            if (boolValue) {
                //                LOGINFO(@"日志上传成功---->>");
                // 删除日志压缩文件
                [self deleteZipFile];
            }else{
                //                LOGERROR(@"日志上传失败！！");
            }
        } errorBlock:^(NSError *errorInfo) {
            //            LOGERROR(([NSString stringWithFormat:@"日志上传失败！！Error:%@",errorInfo]));
        }];
    }
}

/**
 *  压缩日志
 *
 *  @param dates 日期时间段，空代表全部
 *
 *  @return 执行结果
 */
- (BOOL)compressLog:(NSArray*)dates{
    
    // 先清理几天前的日志
    [self clearExpiredLog];
    
    // 获取日志目录下的所有文件
    NSArray* files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.basePath error:nil];
    // 压缩包文件路径
    NSString * zipFile = [self.basePath stringByAppendingString:ZipFileName];
    
    ZipArchive* zip = [[ZipArchive alloc] init];
    // 创建一个zip包
    BOOL created = [zip CreateZipFile2:zipFile];
    if (!created) {
        // 关闭文件
        [zip CloseZipFile2];
        return NO;
    }
    
    if (dates) {
        // 拉取指定日期的
        for (NSString* fileName in files) {
            if ([dates containsObject:fileName]) {
                // 将要被压缩的文件
                NSString *file = [self.basePath stringByAppendingString:fileName];
                // 判断文件是否存在
                if ([[NSFileManager defaultManager] fileExistsAtPath:file]) {
                    // 将日志添加到zip包中
                    [zip addFileToZip:file newname:fileName];
                }
            }
        }
    }else{
        // 全部
        for (NSString* fileName in files) {
            // 将要被压缩的文件
            NSString *file = [self.basePath stringByAppendingString:fileName];
            // 判断文件是否存在
            if ([[NSFileManager defaultManager] fileExistsAtPath:file]) {
                // 将日志添加到zip包中
                [zip addFileToZip:file newname:fileName];
            }
        }
    }
    
    // 关闭文件
    [zip CloseZipFile2];
    
    for (NSString* fileName in files) {
        
        // 将要被压缩的文件
        NSString *file = [self.basePath stringByAppendingString:fileName];
        // 判断文件是否存在
        if ([[NSFileManager defaultManager] fileExistsAtPath:file]) {
            // 删除
            [[NSFileManager defaultManager] removeItemAtPath:file error:nil];
        }
        
    }
    
    return YES;
}

/**
 *  上传日志到服务器
 *
 *  @param returnBlock 成功回调
 *  @param errorBlock  失败回调
 */
- (void)uploadLogToServer:(void(^)(BOOL))returnBlock errorBlock:(void(^)(NSError *error))errorBlock{
    
    __block NSError* error = nil;
    // 获取实体字典
    __block NSDictionary* resultDic;
    
    // 访问URL
    NSString* urlString = [NSString stringWithFormat:@""];
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    [request setHTTPMethod:@"POST"];
    
    NSString * zipFile = [self.basePath stringByAppendingString:ZipFileName];
    NSData *data = [NSData dataWithContentsOfFile:zipFile];
    NSString *base64 = [data base64EncodedStringWithOptions:0];
    
    NSString * charaters = @"?!@#$^&%*+,:;='\"`<>()[]{}/\\| ";
    NSCharacterSet * set = [[NSCharacterSet characterSetWithCharactersInString:charaters] invertedSet];
    
    NSString * encodeStr = [base64 stringByAddingPercentEncodingWithAllowedCharacters:set];
    
    NSString *paramsString = [NSString stringWithFormat:@"device=iphone&info=%@", encodeStr];
    NSData *params = [paramsString dataUsingEncoding:NSUTF8StringEncoding];
    [request setHTTPBody:params];
    
    NSURLSessionConfiguration *conf = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    conf.connectionProxyDictionary = @{};
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:conf];
    
    NSURLSessionTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if (!error && ((NSHTTPURLResponse *)response).statusCode == 200) {
            returnBlock(YES);
        } else {
            errorBlock(error);
        }
    }];
    
    [task resume];
    
    //    // 发起请求，这里是上传日志到服务器,后台功能需要自己做
    //    [[XGNetworking sharedInstance] upload:url fileData:nil fileName:ZipFileName mimeType:@"application/zip" parameters:nil success:^(NSString *jsonData) {
    //
    //        // 获取实体字典
    //        resultDic = [Utilities getDataString:jsonData error:&error];
    //
    //        // 完成后的处理
    //        if (error == nil) {
    //            // 回调返回数据
    //            returnBlock([resultDic[@"state"] boolValue]);
    //        }else{
    //
    //            if (errorBlock){
    //                errorBlock(error.domain);
    //            }
    //        }
    //
    //    } faild:^(NSString *errorInfo) {
    //
    //        returnBlock(errorInfo);
    //    }];
    
}

/**
 *  删除日志压缩文件
 */
- (void)deleteZipFile
{
    
    NSString* zipFilePath = [self.basePath stringByAppendingString:ZipFileName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:zipFilePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:zipFilePath error:nil];
    }
}

/**
 *  写入字符串到指定文件，默认追加内容
 *
 *  @param filePath   文件路径
 *  @param stringData 待写入的字符串
 */
- (void)writeFile:(NSString*)filePath stringData:(NSString*)stringData{
    
    NSLog(@"%@", stringData);
    
    // 待写入的数据
    NSData* writeData = [stringData dataUsingEncoding:NSUTF8StringEncoding];
    
    // NSFileManager 用于处理文件
    BOOL createPathOk = YES;
    if (![[NSFileManager defaultManager] fileExistsAtPath:[filePath stringByDeletingLastPathComponent] isDirectory:&createPathOk]) {
        // 目录不存先创建
        [[NSFileManager defaultManager] createDirectoryAtPath:[filePath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
    }
    if(![[NSFileManager defaultManager] fileExistsAtPath:filePath]){
        // 文件不存在，直接创建文件并写入
        [writeData writeToFile:filePath atomically:NO];
    }else{
        
        // NSFileHandle 用于处理文件内容
        // 读取文件到上下文，并且是更新模式
        NSFileHandle* fileHandler = [NSFileHandle fileHandleForUpdatingAtPath:filePath];
        
        // 跳到文件末尾
        [fileHandler seekToEndOfFile];
        
        // 追加数据
        [fileHandler writeData:writeData];
        
        // 关闭文件
        [fileHandler closeFile];
    }
}


@end
