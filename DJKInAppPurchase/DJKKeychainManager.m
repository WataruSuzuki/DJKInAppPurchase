//
//  DJKKeychainManager.m
//  DJKInAppPurchase
//
//  Created by WataruSuzuki on 2017/01/10.
//  Copyright © 2017年 WataruSuzuki. All rights reserved.
//

#import "DJKKeychainManager.h"

@implementation DJKKeychainManager


- (void)updatePurchaseValue:(NSString *)appName
          withValueKey:(NSString *)keyName
         withValueData:(NSString *)valueData
{
    NSMutableDictionary* attributes = nil;
    NSMutableDictionary* query = [NSMutableDictionary dictionary];
    NSData* passwordData = [valueData dataUsingEncoding:NSUTF8StringEncoding];
    NSString *appKey = [NSString stringWithFormat:@"%@%@", appName, keyName];
    
    query[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
    query[(__bridge id)kSecAttrAccount] = (id)appKey;
    //[query setObject:appName forKey:(__bridge id)kSecAttrService];
    //[query setObject:[keyName dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecAttrGeneric];
    
    OSStatus err = SecItemCopyMatching((__bridge CFDictionaryRef)query, NULL);
    
    if (err == noErr) {
        // update item
        NSLog(@"SecItemCopyMatching: noErr");
        
        attributes = [NSMutableDictionary dictionary];
        attributes[(__bridge id)kSecValueData] = passwordData;
        attributes[(__bridge id)kSecAttrModificationDate] = [NSDate date];
        
        err = SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)attributes);
        if (err == noErr) {
            NSLog(@"SecItemUpdate: noErr");
        } else {
            NSLog(@"SecItemUpdate: error(%d)", (int)err);
        }
        
    } else if (err == errSecItemNotFound) {
        // add new item
        NSLog(@"SecItemCopyMatching: errSecItemNotFound");
        
        attributes = [NSMutableDictionary dictionary];
        attributes[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
        attributes[(__bridge id)kSecAttrAccount] = (id)appKey;
        attributes[(__bridge id)kSecValueData] = passwordData;
        
        err = SecItemAdd((__bridge CFDictionaryRef)attributes, NULL);
        if (err == noErr) {
            NSLog(@"SecItemAdd: noErr");
        } else {
            NSLog(@"SecItemAdd: error(%d)", (int)err);
            [self deletePurchaseValue:appName withValueKey:keyName];
        }
        
    } else {
        NSLog(@"SecItemCopyMatching: error(%d)", (int)err);
    }
}

- (void)deletePurchaseValue:(NSString *)appName
          withValueKey:(NSString *)keyName
{
    NSString *appKey = [NSString stringWithFormat:@"%@%@", appName, keyName];
    
    NSMutableDictionary* query = [NSMutableDictionary dictionary];
    query[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
    query[(__bridge id)kSecAttrAccount] = (id)appKey;
    
    OSStatus err = SecItemDelete((__bridge CFDictionaryRef)query);
    
    if (err == noErr) {
        NSLog(@"SecItemDelete: noErr");
    } else {
        NSLog(@"SecItemDelete: error(%d)", (int)err);
    }
}

- (NSString *)loadPurchaseValue:(NSString *)appName
                withValueKey:(NSString *)keyName
{
    NSString *appKey = [NSString stringWithFormat:@"%@%@", appName, keyName];
    NSString *passwordStr = nil;
    
    NSMutableDictionary* query = [NSMutableDictionary dictionary];
    query[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
    query[(__bridge id)kSecAttrAccount] = (id)appKey;
    query[(__bridge id)kSecReturnData] = (id)kCFBooleanTrue;
    
    CFTypeRef cfValue = NULL;
    OSStatus err = SecItemCopyMatching((__bridge CFDictionaryRef)query,&cfValue);
    NSData* passwordData = (__bridge id)cfValue;;
    
    if (err == noErr) {
        NSLog(@"SecItemCopyMatching: noErr");
        passwordStr = [[NSString alloc] initWithData:passwordData encoding:NSUTF8StringEncoding];
    } else if(err == errSecItemNotFound) {
        NSLog(@"SecItemCopyMatching: errSecItemNotFound");
    } else {
        NSLog(@"SecItemCopyMatching: error(%d)", (int)err);
    }
    
    return passwordStr;
}

- (void)dumpAllPurchaseValue:(id)sender
{
    NSMutableDictionary* query = [NSMutableDictionary dictionary];
    
    query[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
    query[(__bridge id)kSecReturnAttributes] = (id)kCFBooleanTrue;
    query[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitAll;
    
    CFArrayRef result = nil;
    OSStatus err = SecItemCopyMatching((__bridge CFDictionaryRef)query,(CFTypeRef*)&result);
    
    if (err == noErr) {
        NSLog(@"SecItemCopyMatching: noErr");
        NSLog(@"%@", result);
    } else if(err == errSecItemNotFound) {
        NSLog(@"SecItemCopyMatching: errSecItemNotFound");
    } else {
        NSLog(@"SecItemCopyMatching: error(%d)", (int)err);
    }
}

- (void)updatePurchased:(NSString *)appName
                withKey:(NSString *)keyName
              withValue:(BOOL)boolValue
{
    [self updatePurchaseValue:appName withValueKey:keyName withValueData:(boolValue ? @"true" :@"false")];
}

- (BOOL)isPurchased:(NSString *)appName
       withValueKey:(NSString *)keyName
{
    BOOL ret = NO;
    NSString *pw = [self loadPurchaseValue:appName withValueKey:keyName];
    if ([@"true" isEqualToString:pw]) {
        ret = YES;
    }
    
    return ret;
}

@end
