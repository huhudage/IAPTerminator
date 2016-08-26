//
//  UserAccount.m
//  负责维护角色账号数据
//
//  Created by lijinhu on Aug/4/2016.
//
//

#import "UserAccount.h"

static UserAccount *_instanece = [UserAccount shareInstance];

@implementation UserAccount

@synthesize account;
@synthesize serverId;
@synthesize rid;
@synthesize name;
@synthesize level;

+ (UserAccount *)shareInstance
{
    static UserAccount *instance = nil;
    static dispatch_once_t predicate;
    
    dispatch_once(&predicate, ^{
        instance = [[UserAccount alloc] init];
    });
    
    return instance;
}

// 玩家登录游戏服务器
+ (void)onUserLogin:(NSDictionary *)dict
{
    [[UserAccount shareInstance] onUserLogin:dict];
}

// 玩家登录游戏服务器
- (void)onUserLogin:(NSDictionary *)dict
{
    self.account  = [dict objectForKey:@"account"];
    self.serverId = [dict objectForKey:@"serverId"];
    self.rid      = [dict objectForKey:@"rid"];
    self.name     = [dict objectForKey:@"name"];
    self.level    = [dict objectForKey:@"level"];
    
    NSLog(@"Login game success, account:%@, serverId:%@, rid:%@, name:%@, level:%@",
          self.account, self.serverId, self.rid, self.name, self.level);
    
    // 触发角色登录事件
    [[NSNotificationCenter defaultCenter] postNotificationName:@"event_user_login"
                                                        object:self
                                                      userInfo:nil];
}

@end
