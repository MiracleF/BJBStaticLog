//
//  RealTimeLogManager.h
//  LineCloud
//
//  Created by 李杰峰 on 2021/1/16.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#define TLog(type, module, ...) [[RealTimeLogManager shareInstance] logWithType:type andModule:module andLogStr:__VA_ARGS__,nil]

@interface RealTimeLogManager : NSObject

enum logType {
    kSuccess,
    kFail,
};


+ (instancetype)shareInstance;

- (void)logWithType:(enum logType)type andModule:(NSString *)module andLogStr:(NSString*)logStr, ...;

@end

NS_ASSUME_NONNULL_END
