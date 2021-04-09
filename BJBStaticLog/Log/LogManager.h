//
//  LogManager.h
//  LogFileDemo
//
//  Created by xgao on 17/3/9.
//  Copyright © 2017年 xgao. All rights reserved.
//

#import <Foundation/Foundation.h>
#define LLog(module,...) [[LogManager sharedInstance] logInfo:module logStr:__VA_ARGS__,nil]
#define strFormat(a) [NSString stringWithFormat:@"%@", a, nil]

@interface LogManager : NSObject

// 日志的目录路径
@property (nonatomic,copy) NSString* basePath;

/**
 *  获取单例实例
 *
 *  @return 单例实例
 */
+ (instancetype) sharedInstance;

#pragma mark - Method

/**
 *  写入日志
 *
 *  @param module 模块名称
 *  @param logStr 日志信息,动态参数
 */
- (void)logInfo:(NSString*)module logStr:(NSString*)logStr, ...;

/**
 *  清空过期的日志
 */
- (void)clearExpiredLog;

/**
 *  检测日志是否需要上传
 */
- (void)checkLogNeedUpload;



void uncaughtExceptionHandler(NSException *exception);

@end
