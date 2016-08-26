//
//  IAPWrap.h
//  提供了对苹果内购(IAP)的支持
//
//  Created by chengb on 15/12/1.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "IAPHelper.h"

@interface IAPWrap : NSObject
{
    IAPHelper *iapHelper;
}

@property (nonatomic, retain) IAPHelper *iapHelper;

+ (IAPWrap *)shareInstance;
+ (void)buyPurchaseInApp:(NSDictionary *)dict;
+ (void)onServerRechargeOk:(NSDictionary *)dict;

- (id)init;
- (void)dealloc;

@end

