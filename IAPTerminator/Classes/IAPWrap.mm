//
//  IAPWrap.mm
//  提供了对苹果内购(IAP)的支持
//
//  Created by chengb on 15/12/1.
//  
//

#import "IAPWrap.h"

static IAPWrap *_instanece = [IAPWrap shareInstance];

@implementation IAPWrap

@synthesize iapHelper;

+ (IAPWrap *)shareInstance
{
    static IAPWrap *instance = nil;
    static dispatch_once_t predicate;
    
    dispatch_once(&predicate, ^{
        instance = [[IAPWrap alloc] init];
    });
    
    return instance;
}

#pragma mark - Methods for lua invoke

// 购买商品
+ (void)buyPurchaseInApp:(NSDictionary *)dict
{
    // 获取商品库存标识
    NSString *sku = [dict valueForKey:@"sku"];
    
    [[IAPWrap shareInstance].iapHelper buyProduct:sku];
}

// 服务器充值到账
+ (void)onServerRechargeOk:(NSDictionary *)dict
{
    // do nothing
}

#pragma mark -

- (id) init
{
    if (self = [super init])
    {
        // 创建 IAPHelper 实例
        self.iapHelper = [[[IAPHelper alloc] init] autorelease];
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self.iapHelper];

        // 注册批量查询商品价格事件
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onBatchQuerySkuPrice:)
                                                     name:@"event_batch_query_products"
                                                   object:nil];
    }
    return self;
}

// 批量查询商品价格
- (void)onBatchQuerySkuPrice:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    NSArray *productIds = [userInfo objectForKey:@"productIds"];
    
    [self.iapHelper requestProducts:productIds];
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self.iapHelper];
    
    self.iapHelper = nil;
    [super dealloc];
}


@end

