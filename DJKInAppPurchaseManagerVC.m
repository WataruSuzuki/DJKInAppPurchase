//
//  DJKInAppPurchaseManagerVC.m
//  DataUsageCat
//
//  Created by 鈴木 航 on 2014/08/17.
//  Copyright (c) 2014年 鈴木 航. All rights reserved.
//

#import "DJKInAppPurchaseManagerVC.h"
#import "DJKValueManager.h"
//#import "DUC_UserDefaults.h"
//#import "AppDelegate.h"

@implementation DJKInAppPurchaseManagerVC

@synthesize labelGreeting;
@synthesize labelProductName;
@synthesize labelProductPrice;
@synthesize buttonPurchase;
@synthesize buttonRestore;
@synthesize textViewDicribeRestore;
@synthesize imageCat;
@synthesize itemName;

- (void)viewDidLoad
{
    [super viewDidLoad];
#if TARGET_OS_SIMULATOR
    UIBarButtonItem *testBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(tapTestBarButton)];
    self.navigationItem.rightBarButtonItem = testBarButton;
#endif//TARGET_OS_SIMULATOR
    
    labelGreeting.text = NSLocalizedString(@"welcome", @"");
    labelProductName.text = @"";
    labelProductPrice.text = @"";
    [buttonRestore setTitle:NSLocalizedString(@"restore", @"") forState:UIControlStateNormal];
    [buttonPurchase setTitle:NSLocalizedString(@"buy", @"") forState:UIControlStateNormal];
    textViewDicribeRestore.text = NSLocalizedString(@"about_restore", @"");
    
    [self showDJK_IndicatorView];
    
    NSArray *arrayProductId = @[itemName];
    [self validateProductIdentifiers:arrayProductId];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#if TARGET_OS_SIMULATOR
-(void)tapTestBarButton
{
    [self registStatusUnlockAd:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}
#endif//TARGET_OS_SIMULATOR

-(IBAction)cancel:(id)sender
{
#if TARGET_OS_SIMULATOR
    [self registStatusUnlockAd:NO];
#endif//TARGET_OS_SIMULATOR
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(IBAction)tapButtonRestore:(id)sender
{
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

-(IBAction)tapButtonPurchase:(id)sender
{
    [self addPaymentTransaction:myProductResponse];
}

- (BOOL)canMakePurchases
{
    if (![SKPaymentQueue canMakePayments]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"error", @"") message:NSLocalizedString(@"restrict_in_app_purchase", @"") delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alert show];
        return NO;
    }
    return YES;
}

- (void)validateProductIdentifiers:(NSArray *)productIdentifiers
{
    SKProductsRequest *productsRequest = [[SKProductsRequest alloc]
                                          initWithProductIdentifiers:[NSSet setWithArray:productIdentifiers]];
    productsRequest.delegate = self;
    [productsRequest start];
    
    //myProductRequest = productsRequest;
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    NSLog(@"request - didFailWithError: %@", [error userInfo][@"NSLocalizedDescription"]);
}

-(void)showDJK_IndicatorView
{
    if (nil == DJK_IndicatorView) {
        NSString *storyboardName = @"DJKInAppPurchase_iPhone";
        if (UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom]) {
            storyboardName = @"DJKInAppPurchase_iPad";
        }

        UIStoryboard* sb = [UIStoryboard storyboardWithName:storyboardName bundle:nil];
        UIViewController* controller = [sb instantiateViewControllerWithIdentifier:@"DJK_IndicatorView"];
        DJK_IndicatorView = controller.view;
    }
    
    [self.view addSubview:DJK_IndicatorView];
}

-(void)dismissDJK_IndicatorView
{
    [DJK_IndicatorView removeFromSuperview];
}

-(void)showCannotPayAlert:(SKPaymentTransaction *)transaction
{
    [self dismissDJK_IndicatorView];
    
    NSString *errorMsg = NSLocalizedString(@"cannot_pay", @"");
    if (SKErrorClientInvalid == transaction.error.code
        || SKErrorPaymentInvalid == transaction.error.code) {
        errorMsg = NSLocalizedString(@"fail_invalid", @"");
    } else if (SKErrorPaymentNotAllowed == transaction.error.code) {
        errorMsg = NSLocalizedString(@"not_available", @"");
    } else if (SKErrorStoreProductNotAvailable == transaction.error.code) {
        errorMsg = NSLocalizedString(@"restrict_in_app_purchase", @"");
    } else if (SKErrorPaymentCancelled == transaction.error.code) {
        //cancel. not show alert.
        return;
    }
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"error", @"") message:errorMsg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alert show];
}

-(void)showCompRestore:(NSString *)msgText
{
    [self dismissDJK_IndicatorView];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:msgText delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alert show];
}

-(BOOL)registPurchasedStatus:(SKPaymentTransaction *)transaction
{
    BOOL registStatus = NO;
    
    NSString *productID = transaction.payment.productIdentifier;
    NSString *originalProductID = transaction.originalTransaction.payment.productIdentifier;
    NSLog(@"transaction.payment.productIdentifier = %@", productID);
    NSLog(@"originalTransaction.payment.productIdentifier = %@", originalProductID);
    if ([productID isEqualToString:itemName]
        //|| [originalProductID isEqualToString:itemName]
        ) {
        [self registStatusUnlockAd:YES];
        registStatus = YES;
    }
    
    return registStatus;
}

-(void)registStatusUnlockAd:(BOOL)nextStatus
{
    DJKValueManager *valueMngr = [[DJKValueManager alloc] init];
    [valueMngr updateIAPValue:APP_DATA_USAGE_CAT withValueKey:KEY_UNLOCK_ALL_AD withBoolValue:nextStatus];
    //AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    //[delegate updateValueUnLockAd];
    [self.delegate updateStatusUnlockAd:nextStatus];
}

#pragma mark SKProductsRequestDelegate
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    // 無効なアイテムがないかチェック.
    if ([response.invalidProductIdentifiers count] > 0) {
        [self showCannotPayAlert:nil];
        return;
    }
    myProductResponse = response;
    
    for (SKProduct *product in response.products) {
        //各国毎の値段をチェックする.
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
        [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
        [numberFormatter setLocale:product.priceLocale];
        NSString *localizedPrice = [numberFormatter stringFromNumber:product.price];
        
        NSLog(@"price : %@", localizedPrice);
        labelProductPrice.text = localizedPrice;
        labelProductName.text = product.localizedTitle;
        break;
    }
    
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    [self dismissDJK_IndicatorView];
}

// 購入処理開始(「iTunes Storeにサインイン」ポップアップが表示)
-(void)addPaymentTransaction:(SKProductsResponse *)response
{
    for (SKProduct *product in response.products) {
        SKPayment *payment = [SKPayment paymentWithProduct:product];
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    }
}

// トランザクション処理
#pragma mark SKPaymentTransactionObserver
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchasing:
                // NSLog(@"SKPaymentTransactionStatePurchasing");
                [self showDJK_IndicatorView];
                break;
                
            case SKPaymentTransactionStatePurchased:
                // NSLog(@"SKPaymentTransactionStatePurchased");
                [self registPurchasedStatus:transaction];
                [queue finishTransaction:transaction];
                [self dismissDJK_IndicatorView];
                break;
            case SKPaymentTransactionStateFailed:
                NSLog(@"SKPaymentTransactionStateFailed: %@, %@", transaction.transactionIdentifier, transaction.error);
                [self showCannotPayAlert:transaction];
                [queue finishTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                // NSLog(@"SKPaymentTransactionStateRestored");
                [self registPurchasedStatus:transaction];
                [queue finishTransaction:transaction];
                break;
            default:
                [queue finishTransaction:transaction];
                break;
        }
    }
}

// リストア処理結果
- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
    NSLog(@"restoreCompletedTransactionsFailedWithError:%@", error);
    for (SKPaymentTransaction *transaction in queue.transactions) {
        [self showCannotPayAlert:transaction];
    }
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    // NSLog(@"paymentQueueRestoreCompletedTransactionsFinished");
    BOOL isFindTransaction = NO;
    
    for (SKPaymentTransaction *transaction in queue.transactions) {
        BOOL isRegist = [self registPurchasedStatus:transaction];
        if (isRegist) {
            isFindTransaction = YES;
        }
    }
    
    if (isFindTransaction) {
        [self showCompRestore:NSLocalizedString(@"comp_restore", @"")];
    } else {
        [self showCompRestore:NSLocalizedString(@"cannot_find_pay_history", @"")];
        [self registStatusUnlockAd:NO];
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray *)transactions
{
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

@end
