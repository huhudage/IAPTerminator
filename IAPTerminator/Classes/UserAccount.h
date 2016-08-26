//
//  UserAccount.h
//  负责维护角色账号数据
//
//  Created by lijinhu on Aug/4/2016.
//
//

#import <Foundation/Foundation.h>

@interface UserAccount : NSObject
{
    NSString *account;
    NSString *serverId;
    NSString *rid;
    NSString *name;
    NSString *level;
}

@property (nonatomic, retain) NSString *account;
@property (nonatomic, retain) NSString *serverId;
@property (nonatomic, retain) NSString *rid;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *level;

+ (UserAccount *)shareInstance;
+ (void)onUserLogin:(NSDictionary *)dict;
- (void)onUserLogin:(NSDictionary *)dict;

@end
