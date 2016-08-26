//
// iphone上的一些辅助操作接口
// 

#import "QCToolkit.h"
#import <AdSupport/ASIdentifierManager.h>
#include <objc/runtime.h>
#include <ifaddrs.h>
#include <arpa/inet.h>
#include <sys/utsname.h>

@implementation QCToolkit

// 执行具体操作的对象
+ (QCToolkit*)instance
{
    static QCToolkit *instance = nil;
    static dispatch_once_t predicate;
    
    dispatch_once(&predicate, ^{
        instance = [[QCToolkit alloc] init];
    });
    
    return instance;
}

// 获取设备信息
+ (NSString *)getDeviceInfo
{
    NSDictionary *dict = [[QCToolkit instance] getDeviceInfo];
    return [QCToolkit parseToJson:dict];
}

// 系统版本
+ (float)systemVersion
{
    return [[[UIDevice currentDevice] systemVersion] floatValue];
}

// 设备类型
+ (NSString*)deviceModel
{
    UIDevice *device = [UIDevice currentDevice];
    return device.model;
}

// 硬件类型
+ (NSString*)machineName
{
    struct utsname systemInfo;
    uname(&systemInfo);
    return [NSString stringWithUTF8String:systemInfo.machine];
}
     
// 获取广告标志符
+ (NSString *)idfa
{
    NSString *adId = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
    return adId;
}

+ (UIViewController*)currController
{
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    UIViewController *rootVC = [window rootViewController];
    return rootVC;
}

// 获取网络类型
+ (NetworkStatus)getNetMode
{
    ReachabilityQC *reachability = [ReachabilityQC reachabilityForInternetConnection];
    [reachability startNotifier];
    
    NetworkStatus status = [reachability currentReachabilityStatus];
    return status;
}

+ (NSString*)UUID
{
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    CFStringRef uuidStr = CFUUIDCreateString(NULL, uuid);
    CFRelease(uuid);
    NSString *result = [NSString stringWithString:(NSString*)uuidStr];
    CFRelease(uuidStr);
    return result;
}

// 获取Document目录
+ (NSString *)documentsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = paths.firstObject;
    return basePath;
}

// 转化C类型字符串为NSString
+ (NSString*)createNSString:(const char*) string
{
    if (string) {
        return [NSString stringWithUTF8String:string];
    }
    else {
        return [NSString stringWithUTF8String: ""];
    }
}

+ (NSMutableDictionary*)parseToDictionary:(NSString *)json
{
    NSData *jsonData = [json dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    return [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&error];
}

+ (NSString*)parseToJson:(NSDictionary *)dic
{
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&error];
    return [[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] autorelease];
}

+ (NSString *)HTTPBodyWithParameters:(NSDictionary *)parameters encoding:(BOOL)encoding
{
    NSMutableArray *parametersArray = [[[NSMutableArray alloc] init] autorelease];
    if (encoding)
    {
        for (NSString *key in [parameters allKeys]) {
            id value = [parameters objectForKey:key];
            if ([value isKindOfClass:[NSString class]]) {
                [parametersArray addObject:[NSString stringWithFormat:@"%@=%@",key,
                                            [value stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
            }
        }
    }
    else
    {
        for (NSString *key in [parameters allKeys]) {
            id value = [parameters objectForKey:key];
            if ([value isKindOfClass:[NSString class]]) {
                [parametersArray addObject:[NSString stringWithFormat:@"%@=%@",key,value]];
            }
        }
    }
    return [parametersArray componentsJoinedByString:@"&"];
}

+ (NSString *)toWebService:(NSString*)url post:(BOOL)post params:(NSDictionary *)params
{
    NSMutableURLRequest *urlRequest = nil;
    NSString *httpBodyString = [QCToolkit HTTPBodyWithParameters:params encoding:! post];
    if (post)
    {
        urlRequest = [[[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]
                                                   cachePolicy:NSURLRequestReloadIgnoringCacheData
                                               timeoutInterval:30.0] autorelease];
        [urlRequest setHTTPBody:[httpBodyString dataUsingEncoding:NSUTF8StringEncoding]];
        [urlRequest setHTTPMethod:@"POST"];
    }
    else
    {
        NSString *urlfellowString = [NSString stringWithFormat:@"%@?%@",
                                     [NSURL URLWithString:url].absoluteString,
                                     httpBodyString];
        urlRequest = [[[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlfellowString]] autorelease];
        [urlRequest setHTTPMethod:@"GET"];
    }
    
    NSData *received = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:nil error:nil];
    return [[[NSString alloc] initWithData:received encoding:NSUTF8StringEncoding] autorelease];
}

// 向某个地址url发送json格式的数据
// 此接口发送的是同步请求，会使客户端卡住一段时间，请谨慎使用！
+ (NSString *)postJsonToUrl:(NSString*)url params:(NSDictionary*)params
{
    NSString *httpBodyString = [QCToolkit parseToJson:params];
    
    NSMutableURLRequest *urlRequest = [[[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]
                                                                    cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                                timeoutInterval:30.0] autorelease];
    [urlRequest setHTTPBody:[httpBodyString dataUsingEncoding:NSUTF8StringEncoding]];
    [urlRequest setHTTPMethod:@"POST"];
    
    NSData *received = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:nil error:nil];
    return [[[NSString alloc] initWithData:received encoding:NSUTF8StringEncoding] autorelease];
}

// 获取设备信息
- (NSDictionary *)getDeviceInfo
{
    UIDevice *device = [UIDevice currentDevice];
    
    NetworkStatus netMode = [QCToolkit getNetMode];
    NSString *ip;
    NSDictionary *ipaddrs = [self getIPAddresses];
    if (netMode == ReachableViaWiFi)
        ip = [ipaddrs objectForKey:@"wireless"];
    else
        ip = [ipaddrs objectForKey:@"cell"];
    
    NSDictionary *dict = @{@"mac" : @"",
                           @"ip" : ip,
                           @"IMEI" : @"",
                           @"equdid" : [QCToolkit idfa],
                           @"app_version" : [self getBundleVersionCode],
                           @"os_version" : [device systemVersion],
                           @"mobile_model" : [QCToolkit machineName],
                           @"screen_x" : @"",
                           @"screen_y" : @"",
                           @"soft_version" : @"",
                           @"net_mode" : [NSString stringWithFormat:@"%d", (int) netMode] };
    return dict;
}

// 获取 ip 地址
- (NSDictionary *)getIPAddresses
{
    NSString *WIFI_IF = @"en0";
    NSArray *KNOWN_CELL_IFS = @[@"pdp_ip0",@"pdp_ip1",@"pdp_ip2",@"pdp_ip3"];
    
    const NSString *UNKNOWN_IP_ADDRESS = @"127.0.0.1";
    
    NSMutableDictionary *addresses = [NSMutableDictionary dictionaryWithDictionary:@{@"wireless":UNKNOWN_IP_ADDRESS,
                                                                                     @"cell":UNKNOWN_IP_ADDRESS}];
    
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0)
    {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL)
        {
            if (temp_addr->ifa_addr == NULL)
            {
                continue;
            }
            
            if(temp_addr->ifa_addr->sa_family == AF_INET)
            {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:WIFI_IF])
                {
                    // Get NSString from C String
                    [addresses setObject:[NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)] forKey:@"wireless"];
                }

                // Check if interface is a cellular connection
                if([KNOWN_CELL_IFS containsObject:[NSString stringWithUTF8String:temp_addr->ifa_name]])
                {
                    [addresses setObject:[NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)] forKey:@"cell"];
                }
            }
            
            temp_addr = temp_addr->ifa_next;
        }
    }
    
    // Free memory
    freeifaddrs(interfaces);
    
    return addresses;
}

// 获取Info.plist的信息
- (id)findPlistValue:(NSString*)key
{
    NSDictionary* infoDict = [[NSBundle mainBundle]infoDictionary];
    return [infoDict objectForKey:key];
}

- (NSString*)getBundleIdentifier
{
    return [self findPlistValue:@"CFBundleIdentifier"];
}

- (NSString*)getBundleVersion
{
    return [self findPlistValue:@"CFBundleVersion"];
}

- (NSString*)getBundleVersionCode
{
     return [self findPlistValue:@"CFBundleShortVersionString"];
}

// 获取格式化后的当前时间
- (NSString *)getCurrentTimeWithFormat:(NSString *)format
{
    NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
    [formatter setDateFormat:format];
    return [formatter stringFromDate:[NSDate date]];
}
@end
