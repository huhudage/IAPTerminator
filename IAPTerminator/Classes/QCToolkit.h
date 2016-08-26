#pragma once

#import <UIKit/UIKit.h>
#import "Reachability.h"

// 游戏常用功能拓展
@interface QCToolkit : NSObject
{
    
}

+ (QCToolkit *)instance;
+ (NSString *)getDeviceInfo;
+ (float)systemVersion;
+ (NSString*)deviceModel;
+ (NSString*)machineName;
+ (NSString *)idfa;
+ (UIViewController *)currController;
+ (NetworkStatus)getNetMode;
+ (NSString *)createNSString:(const char *) string;
+ (NSDictionary *)parseToDictionary:(NSString *)json;
+ (NSString *)parseToJson:(NSDictionary *)dic;
+ (NSString *)toWebService:(NSString*)url post:(BOOL)post params:(NSDictionary *)params;
+ (NSString *)postJsonToUrl:(NSString *)url params:(NSDictionary *)params;
+ (NSString *)UUID;
+ (NSString *)documentsDirectory;


- (NSDictionary *)getDeviceInfo;
- (id)findPlistValue:(NSString *)key;
- (NSString *)getBundleIdentifier;
- (NSString *)getBundleVersion;
- (NSString *)getBundleVersionCode;
- (NSString *)getCurrentTimeWithFormat:(NSString *)format;

@end
