//
//  DJKInAppPurchaseManagerVC.h
//  DataUsageCat
//
//  Created by 鈴木 航 on 2014/08/17.
//  Copyright (c) 2014年 鈴木 航. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>

@class DJKInAppPurchaseManagerVC;

@protocol DJKInAppPurchaseManagerVCDelegate
- (void)updateStatusUnlockAd:(BOOL)status;
@end

@interface DJKInAppPurchaseManagerVC : UIViewController <
UIAlertViewDelegate,
SKProductsRequestDelegate,SKPaymentTransactionObserver>
{
    SKProductsResponse *myProductResponse;
    SKProductsRequest *myProductRequest;
    
    UIView *DJK_IndicatorView;
}
@property (weak, nonatomic) IBOutlet UILabel *labelGreeting;
@property (weak, nonatomic) IBOutlet UILabel *labelProductName;
@property (weak, nonatomic) IBOutlet UILabel *labelProductPrice;
@property (weak, nonatomic) IBOutlet UIButton *buttonRestore;
@property (weak, nonatomic) IBOutlet UIButton *buttonPurchase;
@property (weak, nonatomic) IBOutlet UITextView *textViewDicribeRestore;
@property (weak, nonatomic) IBOutlet UIImageView *imageCat;

@property (weak, nonatomic) id <DJKInAppPurchaseManagerVCDelegate> delegate;
@property (weak, nonatomic) NSString* itemName;

//public method
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL canMakePurchases;

@end
