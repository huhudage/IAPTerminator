//
//  ViewController.m
//  IAPTerminator
//
//  Created by lijinhu on 8/26/16.
//  Copyright © 2016 lijinhu. All rights reserved.
//

#import "ViewController.h"
#import "IAPWrap.h"
#import "UserAccount.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //SKPaymentQueue *queue = [SKPaymentQueue defaultQueue];
    //[self appendText:[NSString stringWithFormat:@"发现 %ld 条未完成订单", queue.transactions.count]];
    
    UserAccount *userAccount = [UserAccount shareInstance];
    userAccount.account = @"fuckyou";
    userAccount.serverId = @"999";
    
    // 抛出批量查询商品价格事件
    NSArray *productIds = [NSArray arrayWithObjects:
                           @"com.qcplay.slimegogogo.bagofgems",
                           @"com.qcplay.slimegogogo.sackofgems",
                           @"com.qcplay.slimegogogo.chestofgems",
                           @"com.qcplay.slimegogogo.signboard",
                           @"com.qcplay.slimegogogo.crateofgems",
                           @"com.qcplay.slimegogogo.treasureofgods",
                           nil];
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    [userInfo setValue:productIds  forKey:@"productIds"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"event_batch_query_products"
                                                        object:self
                                                      userInfo:userInfo];
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [_buyBtn1 release];
    [_buyBtn2 release];
    [_buyBtn3 release];
    [_buyBtn4 release];
    [_buyBtn5 release];
    [_buyBtn6 release];
    [_restoreBtn release];
    [_textView release];
    [super dealloc];
}

- (IBAction)buyBtn1Clicked:(id)sender {
    NSDictionary *dict = @{ @"sku": @"com.qcplay.slimegogogo.bagofgems" };
    [IAPWrap buyPurchaseInApp:dict];
}

- (IBAction)buyBtn2Clicked:(id)sender {
    NSDictionary *dict = @{ @"sku": @"com.qcplay.slimegogogo.sackofgems" };
    [IAPWrap buyPurchaseInApp:dict];
}

- (IBAction)buyBtn3Clicked:(id)sender {
    NSDictionary *dict = @{ @"sku": @"com.qcplay.slimegogogo.chestofgems" };
    [IAPWrap buyPurchaseInApp:dict];
}

- (IBAction)buyBtn4Clicked:(id)sender {
    NSDictionary *dict = @{ @"sku": @"com.qcplay.slimegogogo.signboard" };
    [IAPWrap buyPurchaseInApp:dict];
}

- (IBAction)buyBtn5Clicked:(id)sender {
    NSDictionary *dict = @{ @"sku": @"com.qcplay.slimegogogo.crateofgems" };
    [IAPWrap buyPurchaseInApp:dict];
}

- (IBAction)buyBtn6Clicked:(id)sender {
    NSDictionary *dict = @{ @"sku": @"com.qcplay.slimegogogo.treasureofgods" };
    [IAPWrap buyPurchaseInApp:dict];
}

- (IBAction)restoreBtnClicked:(id)sender {
    
}

- (void)appendText:(NSString *)text
{
    [_textView setText:[NSString stringWithFormat:@"%@\n%@", [_textView text], text]];
}

@end
