//
//  IAPHelper.m
//  提供苹果内购支持，如：商品列表获取、发起商品购买、订单状态监听等
//
//  Created by lijh on Jun/24/2016
//

#import "IAPHelper.h"
#import "Reachability.h"
#import "QCToolkit.h"
#import "UserAccount.h"
#import "ViewController.h"

// 定义私有属性和方法
@interface IAPHelper ()
{
}

@property (nonatomic, retain) SKProductsRequest *request;
@property (nonatomic, retain) NSMutableDictionary *pid2Products;
@property (nonatomic, retain) NSMutableSet *pendingTransactions;
@property (nonatomic, retain) NSString *buyingProductId;
@property (nonatomic, retain) NSString *verifyUrl;

- (void)requestTimeOut:(id)arg;
- (void)doBuy:(NSString *)productId;
- (void)completeTransaction:(SKPaymentTransaction *)transaction;
- (void)didPurchaseFailed:(NSString *)productId;
- (void)sendLocalizedPrice;
- (bool)isNetworkOk;
- (NSString *)getCurrencyCode:(NSLocale *)locale;

@end

@implementation IAPHelper

@synthesize request;
@synthesize pid2Products;
@synthesize buyingProductId;
@synthesize verifyUrl;

- (id)init
{
    if (self = [super init])
    {
        // 商品ID - 商品 映射
        self.pid2Products = [NSMutableDictionary dictionary];
        
        // 由于商品列表还未取回，而无法进行验证的订单
        self.pendingTransactions = [NSMutableSet set];
        
        // 从plist中读取支付账单验证地址
        NSDictionary *dict = [[NSBundle mainBundle] infoDictionary];
        NSString *url = [dict objectForKey:@"IAPNotifyUrl"];
        self.verifyUrl = url;
    }
    return self;
}

// 查询商品价格信息
- (void)requestProducts:(NSArray *)pids
{
    ViewController *controller = (ViewController *)[QCToolkit currController];
    [controller appendText:@"开始获取商品信息..."];
    
    if (! [self isNetworkOk])
    {
        NSLog(@"获取商品列表失败：网络连接异常。");
        return;
    }
    
    if (self.request)
    {
        NSLog(@"获取商品列表失败：正在获取商品列表.");
        return;
    }
    
    NSMutableSet *newPids = [NSMutableSet set];
    for (NSString *pid in pids)
    {
        if ([self.pid2Products objectForKey:pid] == nil)
            [newPids addObject:pid];
    }
    
    // 商品都已经查询过了，无须再次查询
    if (newPids.count == 0)
    {
        // 向游戏客户端发送本地化价格
        [self sendLocalizedPrice];
    
        return;
    }
    
    self.request = [[[SKProductsRequest alloc] initWithProductIdentifiers:newPids] autorelease];
    self.request.delegate = self;
    [self.request start];
    
    // 超时自检
    [self performSelector:@selector(requestTimeOut:) withObject:nil afterDelay:kRequestTimeoutPeriod];
}

// 购买商品
- (void)buyProduct:(NSString *)productId
{
    if (! [SKPaymentQueue canMakePayments])
    {
        NSLog(@"购买失败，用户禁止应用内付费购买.");

        [self didPurchaseFailed:productId];
        return;
    }

    if (self.request)
    {
        NSLog(@"购买失败，正在获取商品列表.");

        [self didPurchaseFailed:productId];
        return;
    }

    if (self.buyingProductId != nil)
    {
        NSLog(@"购买失败，当前正在购买商品 %@。", self.buyingProductId);

        [self didPurchaseFailed:productId];
        return;
    }

    // 记录正在购买的商品ID
    self.buyingProductId = productId;

    // 当前商品列表为空，无法购买
    if (self.pid2Products.count == 0)
        return;

    // 执行购买
    [self doBuy:productId];
}

#pragma mark - SKProductsRequestDelegate Methods

// 查询商品列表的回调函数
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    NSLog(@"查询到 %lu 件商品", (unsigned long)response.products.count);

    // 缓存商品列表
    for (SKProduct *product in response.products)
    {
        [self.pid2Products setObject:product forKey:product.productIdentifier];
    }

    // 清空请求
    self.request = nil;

    if (self.pid2Products.count > 0)
    {
        // 向游戏客户端发送本地化价格
        [self sendLocalizedPrice];

        // 如果当前有购买请求，则执行购买
        if (self.buyingProductId != nil)
        {
            [self doBuy:self.buyingProductId];
        }
    }

    // 处理尚未 finish 的订单
    [self processPendingTransactions];
    
    ViewController *controller = (ViewController *)[QCToolkit currController];
    [controller appendText:@"获取商品信息成功"];
}

#pragma mark - SKPaymentTransactionObserver Methods

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction *transaction in transactions)
    {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchasing:
                break;
            case SKPaymentTransactionStatePurchased:
                [self tryVerifyTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                [self restoreTransaction:transaction];
            default:
                break;
        }
    }
}

#pragma mark -

// 处理尚未 finish 的订单，主要是为了处理以下情况：
// 客户端有一个尚未 finish 的订单，登录后会马上尝试完成此订单，但是此时商品列表很可能还未拉取回来，
// 此时需要将这些订单缓存起来，等到商品列表取回来之后再向服务器发起验证
- (void)processPendingTransactions
{
    for (SKPaymentTransaction *transaction in self.pendingTransactions)
    {
        [self verifyTransaction:transaction];
    }

    [self.pendingTransactions removeAllObjects];
}

// 充值成功后，向服务器验证订单
- (void)verifyTransaction:(SKPaymentTransaction *)transaction
{
    NSString *productId = transaction.payment.productIdentifier;

    SKProduct *product = [pid2Products objectForKey:productId];
    if (product == nil)
        return;

    NSString *currencyCode = [self getCurrencyCode:product.priceLocale];

    // 交易数据（注：这里必须进行base64编码，否则服务器会认为数据格式错误）
    NSString *receipt = [transaction.transactionReceipt base64EncodedStringWithOptions:0];

    // 创建post请求
    NSString *bodyStr =[NSString stringWithFormat: @"receipt=%@&account=%@&server=%@&currency=%@&price=%@",
                         receipt, [UserAccount shareInstance].account, [UserAccount shareInstance].serverId, currencyCode, product.price];

    NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.verifyUrl]];
    [postRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [postRequest setHTTPMethod:@"POST"];
    [postRequest setHTTPBody:[bodyStr dataUsingEncoding:NSUTF8StringEncoding]];

    // 通过 URLSession 发起异步请求进行验证
    // 注意：不要使用 NSURLRequest 发送同步请求，会让客户端卡住，影响体验
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:postRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error != nil)
        {
            NSLog(@"Verify receipt with error:\n%@", error);

            [self didPurchaseFailed:productId];
        }
        else
        {
            NSString *ret = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
            NSLog(@"Verify receipt with ret:\n%@", ret);

            // 检查验证结果
            // 1. status 为苹果订单验证结果，0表示成功
            // 2. saveResult 为订单插入数据库结果，true 表示成功
            NSDictionary *retDict = [QCToolkit parseToDictionary:ret];
            if (retDict == nil ||
                [[retDict objectForKey:@"status"] intValue] != 0 ||
                [[retDict objectForKey:@"saveResult"] boolValue] != YES)
            {
                [self didPurchaseFailed:productId];
                return;
            }

            // 订单验证通过，且已经写入数据库成功，此时可以把订单 finish 掉了
            [self completeTransaction:transaction];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *message = [NSString stringWithFormat:@"订单验证成功，获得商品 %@", product.localizedTitle];
                ViewController *controller = (ViewController *)[QCToolkit currController];
                [controller appendText:message];
            });
        }
    }];
    [task resume];
}

// 尝试验证订单
- (void)tryVerifyTransaction:(SKPaymentTransaction *)transaction
{
    NSString *productId = transaction.payment.productIdentifier;
    
    NSString *message = [NSString stringWithFormat:@"开始验证订单 %@ ...", transaction.transactionIdentifier];
    ViewController *controller = (ViewController *)[QCToolkit currController];
    [controller appendText:message];

    // 商品列表还未取回，先将订单缓存起来，稍后再做验证
    if ([pid2Products objectForKey:transaction.payment.productIdentifier] == nil)
    {
        if (! [self.pendingTransactions containsObject:transaction])
        {
            [self.pendingTransactions addObject:transaction];
            return;
        }
    }

    [self verifyTransaction:transaction];
    
    // 通知游戏客户端购买完成
    //[LuaObjectCBridge callLuaGlobalFunctionWithString:@"onRechargeOk" forFunctionArgs:productId];
}

// finish 一个订单
- (void)completeTransaction:(SKPaymentTransaction *)transaction
{
    // 移除正在购买的标记
    self.buyingProductId = nil;

    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];

    // 触发内购成功事件
    SKProduct *product = [self.pid2Products objectForKey:transaction.payment.productIdentifier];
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    [userInfo setValue:product forKey:@"product"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"event_iap_purchase"
                                                        object:self
                                                      userInfo:userInfo];
}

// 购买恢复的回调（这种情形一般是由于异常导致上一次购买没有完成，当玩家重新登录时恢复购买）
- (void)restoreTransaction:(SKPaymentTransaction *)transaction
{
    NSLog(@"restoreTransaction...");

    [self tryVerifyTransaction:transaction];
}

// 购买失败的回调
- (void)failedTransaction:(SKPaymentTransaction *)transaction {

    if (transaction.error.code != SKErrorPaymentCancelled)
    {
        NSLog(@"Transaction error: %@", transaction.error.localizedDescription);
    }

    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];

    // 移除正在购买的标记
    self.buyingProductId = nil;

    NSString *productId = transaction.payment.productIdentifier;
    //[LuaObjectCBridge callLuaGlobalFunctionWithString:@"onRechargeFail" forFunctionArgs:productId];
}

#pragma mark - Private Methods

// 获取商品列表超时回调
- (void)requestTimeOut:(id)arg
{
    if (self.request)
    {
        NSLog(@"请求商品列表超时");

        self.request = nil;
    }
}

// 真正执行购买操作
- (void)doBuy:(NSString *)productId
{
    SKProduct *product = [self.pid2Products objectForKey:productId];
    if (product == nil)
    {
        NSLog(@"购买失败，商品 %@ 不存在", productId);

        [self didPurchaseFailed:productId];
        return;
    }

    SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

// 购买失败
- (void)didPurchaseFailed:(NSString *)productId
{
    //[LuaObjectCBridge callLuaGlobalFunctionWithString:@"onRechargeFail" forFunctionArgs:productId];
}

// 向游戏客户端发送本地化价格
- (void)sendLocalizedPrice
{
    if (self.pid2Products.count == 0)
        return;

    NSMutableArray *mutableArray = [NSMutableArray arrayWithCapacity:self.pid2Products.count];

    for (NSString *productId in self.pid2Products)
    {
        SKProduct *product = [self.pid2Products objectForKey:productId];
        NSNumberFormatter *numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
        [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
        [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
        [numberFormatter setLocale:product.priceLocale];
        NSString *formattedPrice = [numberFormatter stringFromNumber:product.price];

        // 将sku和格式化后的价格用'&'拼接起来
        NSString *item = [NSString stringWithFormat:@"%@&%@", product.productIdentifier, formattedPrice];

        [mutableArray addObject:item];
        NSLog(@"product info: %@", item);
    }

    // 将所有项拼接起来
    NSString *finalStr = [mutableArray componentsJoinedByString:@"|"];
    [mutableArray removeAllObjects];

    //[LuaObjectCBridge callLuaGlobalFunctionWithString:@"onSendLocPrice" forFunctionArgs:(finalStr)];
}

// 检测网络是否正常
- (bool)isNetworkOk
{
    ReachabilityQC *reach = [ReachabilityQC reachabilityForInternetConnection];
    NetworkStatus netStatus = [reach currentReachabilityStatus];
    return netStatus != NotReachable;
}

// 获取货币码
- (NSString *)getCurrencyCode:(NSLocale *)locale
{
    NSNumberFormatter *numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
    [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [numberFormatter setLocale:locale];

    NSString *currencyCode = [numberFormatter currencyCode];
    return currencyCode;
}

@end
