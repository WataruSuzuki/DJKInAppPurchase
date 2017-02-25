//
//  DJKInAppPurchaseImpl.m
//  DJKInAppPurchase
//
//  Created by WataruSuzuki on 2017/01/10.
//  Copyright © 2017年 WataruSuzuki. All rights reserved.
//

#import "DJKInAppPurchaseImpl.h"
#import "DJKKeychainManager.h"

@interface DJKInAppPurchaseImpl()

@property (weak, nonatomic) UIViewController* clientViewController;
@property (weak, nonatomic) NSString* appName;
@property (weak, nonatomic) UIView* purchaseIndicator;

@property (copy, nonatomic) NSArray* itemArray;
@property (strong, nonatomic) SKProductsResponse *myProductResponse;
@property (strong, nonatomic) SKProductsRequest *myProductRequest;

@end

@implementation DJKInAppPurchaseImpl

- (instancetype)initWithViewController:(UIViewController *)controller
                               withApp:(NSString *)clientAppName
                               withKey:(NSArray *)clientItemArray
{
    self = [super init];
    
    if (self) {
        self.clientViewController = controller;
        self.appName = clientAppName;
        self.itemArray = clientItemArray;
    }

    return self;
}

- (NSString *)getBundleString:(NSString *)key
{
    NSBundle *bundle = [NSBundle bundleForClass:[DJKInAppPurchaseImpl self]];
    NSString *languageBundlePath = [bundle pathForResource:NSLocaleLanguageCode ofType:@"lproj"];
    if (languageBundlePath) {
        NSBundle *localizationBundle = [NSBundle bundleWithPath:languageBundlePath];
        return NSLocalizedStringFromTableInBundle(key, nil, localizationBundle, @"");
    }
    return NSLocalizedString(key, @"");
}

- (void)validateProduct
{
    if ([SKPaymentQueue canMakePayments]) {
        [self validateProductWithIdentifiers:self.itemArray];
    } else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:[self getBundleString:@"error"] message:[self getBundleString:@"error"] preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alert addAction:action];
        [self.clientViewController presentViewController:alert animated:YES completion:nil];
    }
}

- (void)validateProductWithIdentifiers:(NSArray *)productIdentifiers
{
    SKProductsRequest *productsRequest = [[SKProductsRequest alloc]
                                          initWithProductIdentifiers:[NSSet setWithArray:productIdentifiers]];
    productsRequest.delegate = self;
    [productsRequest start];
    
    self.myProductRequest = productsRequest;
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    NSLog(@"request - didFailWithError: %@", [error userInfo][@"NSLocalizedDescription"]);
}

- (void)showPurchaseIndicator
{
    if (nil == self.purchaseIndicator) {
        NSBundle *bundle = [NSBundle bundleForClass:self.class];
        UIStoryboard* sb = [UIStoryboard storyboardWithName:@"DJKInAppPurchase" bundle:bundle];
        UIViewController* controller = [sb instantiateViewControllerWithIdentifier:@"PurchaseIndicator"];
        self.purchaseIndicator = controller.view;
    }
    
    [self.clientViewController.view addSubview:self.purchaseIndicator];
}

- (void)dismissPurchaseIndicator
{
    [self.purchaseIndicator removeFromSuperview];
}

- (void)showCannotPayAlert:(SKPaymentTransaction *)transaction
{
    [self dismissPurchaseIndicator];
    
    NSString *errorMsg = [self getBundleString:@"cannot_pay"];
    if (SKErrorClientInvalid == transaction.error.code
        || SKErrorPaymentInvalid == transaction.error.code) {
        errorMsg = [self getBundleString:@"fail_validation"];
    } else if (SKErrorPaymentNotAllowed == transaction.error.code) {
        errorMsg = [self getBundleString:@"not_available"];
    } else if (SKErrorStoreProductNotAvailable == transaction.error.code) {
        errorMsg = [self getBundleString:@"restrict_in_app_purchase"];
    } else if (SKErrorPaymentCancelled == transaction.error.code) {
        //cancel. not show alert.
        return;
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"error", @"") message:errorMsg preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:action];
    [self.clientViewController presentViewController:alert animated:YES completion:nil];
}

- (void)showCompRestore:(NSString *)msgText
{
    [self dismissPurchaseIndicator];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:msgText preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:action];
    [self.clientViewController presentViewController:alert animated:YES completion:nil];
}

- (void)updatePurchasedValue:(BOOL)nextStatus withID:(NSString *)productID
{
    DJKKeychainManager *valueMngr = [[DJKKeychainManager alloc] init];
    [valueMngr updatePurchased:self.appName withKey:productID withValue:nextStatus];
    [self.delegate updatePurchasedStatus:nextStatus withID:productID];
}

-(BOOL)registPurchasedStatus:(SKPaymentTransaction *)transaction
{
    BOOL registStatus = NO;
    
    NSString *productID = transaction.payment.productIdentifier;
    NSString *originalProductID = transaction.originalTransaction.payment.productIdentifier;
    NSLog(@"transaction.payment.productIdentifier = %@", productID);
    NSLog(@"originalTransaction.payment.productIdentifier = %@", originalProductID);
    for (NSString *itemName in self.itemArray) {
        if ([productID isEqualToString:itemName]
            //|| [originalProductID isEqualToString:itemName]
            ) {
            [self updatePurchasedValue:YES withID:productID];
            registStatus = YES;
        }
    }
    
    return registStatus;
}

#pragma mark SKProductsRequestDelegate
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    // 無効なアイテムがないかチェック.
    if ([response.invalidProductIdentifiers count] > 0) {
        [self showCannotPayAlert:nil];
        return;
    }
    self.myProductResponse = response;
    
    for (SKProduct *product in response.products) {
        //各国毎の値段をチェックする.
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
        [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
        [numberFormatter setLocale:product.priceLocale];
        NSString *localizedPrice = [numberFormatter stringFromNumber:product.price];
        
        NSLog(@"price : %@", localizedPrice);
//        labelProductPrice.text = localizedPrice;
//        labelProductName.text = product.localizedTitle;
        break;
    }
    
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    [self dismissPurchaseIndicator];
}

// 購入処理開始(「iTunes Storeにサインイン」ポップアップが表示)
- (void)addPaymentTransaction
{
    [self addPaymentTransactionWithResponse:self.myProductResponse];
}

- (void)addPaymentTransactionWithResponse:(SKProductsResponse *)response
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
                [self showPurchaseIndicator];
                break;
                
            case SKPaymentTransactionStatePurchased:
                // NSLog(@"SKPaymentTransactionStatePurchased");
                [self registPurchasedStatus:transaction];
                [queue finishTransaction:transaction];
                [self dismissPurchaseIndicator];
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
        } else {
            NSString *productID = transaction.payment.productIdentifier;
            [self updatePurchasedValue:NO withID:productID];
        }
    }
    
    if (isFindTransaction) {
        [self showCompRestore:[self getBundleString:@"comp_restore"]];
    } else {
        [self showCompRestore:[self getBundleString:@"cannot_find_pay_history"]];
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray *)transactions
{
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

@end
