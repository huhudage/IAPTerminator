//
//  IAPHelper.h
//  提供苹果内购支持，如：商品列表获取、发起商品购买、订单状态监听等
//
//  Created by lijh on Jun/24/2016
//

#import <Foundation/Foundation.h>
#import "StoreKit/StoreKit.h"

#define kRequestTimeoutPeriod              20  // 获取商品列表超时时间

@interface IAPHelper : NSObject<SKProductsRequestDelegate, SKPaymentTransactionObserver>
{
}

- (void)requestProducts:(NSArray *)pids;
- (void)buyProduct:(NSString *)productId;

@end
