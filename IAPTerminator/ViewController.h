//
//  ViewController.h
//  IAPTerminator
//
//  Created by lijinhu on 8/26/16.
//  Copyright © 2016 lijinhu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController
@property (retain, nonatomic) IBOutlet UIButton *buyBtn1;
@property (retain, nonatomic) IBOutlet UIButton *buyBtn2;
@property (retain, nonatomic) IBOutlet UIButton *buyBtn3;
@property (retain, nonatomic) IBOutlet UIButton *buyBtn4;
@property (retain, nonatomic) IBOutlet UIButton *buyBtn5;
@property (retain, nonatomic) IBOutlet UIButton *buyBtn6;
@property (retain, nonatomic) IBOutlet UIButton *restoreBtn;
@property (retain, nonatomic) IBOutlet UITextView *textView;

- (IBAction)buyBtn1Clicked:(id)sender;
- (IBAction)buyBtn2Clicked:(id)sender;
- (IBAction)buyBtn3Clicked:(id)sender;
- (IBAction)buyBtn4Clicked:(id)sender;
- (IBAction)buyBtn5Clicked:(id)sender;
- (IBAction)buyBtn6Clicked:(id)sender;
- (IBAction)restoreBtnClicked:(id)sender;

- (void)appendText:(NSString *)text;
@end

