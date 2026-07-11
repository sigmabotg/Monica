#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
#pragma GCC diagnostic ignored "-Wobjc-method-access"

#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>   // <--- THÊM DÒNG NÀY ĐỂ FIX LỖI

static BOOL hasShownNotice = NO;

// ============================================================
// 1. HOOK NSUSERDEFAULTS - BYPASS PRO/TRIAL
// ============================================================
%hook NSUserDefaults

- (BOOL)boolForKey:(NSString *)key {
    NSArray *proKeys = @[
        @"pro", @"premium", @"vip", @"unlock", @"trial",
        @"isPro", @"hasPro", @"isPremium", @"hasPremium",
        @"isVip", @"hasVip", @"isSubscribed", @"hasSubscription",
        @"subscribed", @"purchased", @"isTrial", @"hasTrial",
        @"isProUser", @"hasProAccess", @"premiumUser"
    ];
    for (NSString *k in proKeys) {
        if ([key.lowercaseString containsString:k]) {
            return YES;
        }
    }
    return %orig;
}

- (id)objectForKey:(NSString *)key {
    if ([key containsString:@"subscription"] || 
        [key containsString:@"purchase"] || 
        [key containsString:@"receipt"] ||
        [key containsString:@"pro"] ||
        [key containsString:@"premium"] ||
        [key containsString:@"trial"]) {
        return @{
            @"status": @"active",
            @"expiry": @"2099-12-31",
            @"plan": @"pro",
            @"is_trial": @NO,
            @"is_pro": @YES,
            @"is_premium": @YES
        };
    }
    return %orig;
}

- (void)setBool:(BOOL)value forKey:(NSString *)key {
    NSArray *forceKeys = @[@"pro", @"premium", @"vip", @"unlock", @"trial", @"subscribed"];
    for (NSString *k in forceKeys) {
        if ([key.lowercaseString containsString:k]) {
            %orig(YES, key);
            return;
        }
    }
    %orig;
}

- (void)setObject:(id)value forKey:(NSString *)key {
    NSArray *blockKeys = @[@"subscription", @"trial", @"expired", @"purchase"];
    for (NSString *k in blockKeys) {
        if ([key.lowercaseString containsString:k]) {
            return;
        }
    }
    %orig;
}
%end

// ============================================================
// 2. HOOK REVENUECAT - BYPASS SUBSCRIPTION
// ============================================================
%hook RCPurchases

- (BOOL)isProUser {
    return YES;
}
- (BOOL)hasActiveSubscription {
    return YES;
}
- (BOOL)isTrial {
    return YES;
}
- (BOOL)isExpired {
    return NO;
}
- (id)getSubscriptionInfo {
    return @{
        @"status": @"active",
        @"expiry": @"2099-12-31",
        @"plan": @"pro"
    };
}
%end

// ============================================================
// 3. HOOK PURCHASES_FLUTTER
// ============================================================
%hook PurchasesHybridCommon

- (BOOL)isPro {
    return YES;
}
- (BOOL)hasPremium {
    return YES;
}
- (id)getProStatus {
    return @{
        @"status": @"active",
        @"plan": @"pro"
    };
}
%end

// ============================================================
// 4. HOOK NSBundle - BYPASS RECEIPT
// ============================================================
%hook NSBundle

- (id)objectForInfoDictionaryKey:(NSString *)key {
    if ([key containsString:@"Receipt"] || [key containsString:@"receipt"]) {
        return @"valid";
    }
    return %orig;
}
%end

// ============================================================
// 5. HOOK UIApplication - BYPASS JAILBREAK
// ============================================================
%hook UIApplication

- (BOOL)canOpenURL:(NSURL *)url {
    if ([url.scheme containsString:@"cydia"] || [url.scheme containsString:@"sileo"]) {
        return NO;
    }
    return %orig;
}
%end

// ============================================================
// 6. HOOK APPDELEGATE - HIỂN THỊ THÔNG BÁO
// ============================================================
%hook AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    BOOL result = %orig;
    
    if (!hasShownNotice) {
        hasShownNotice = YES;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            UIWindow *window = [UIApplication sharedApplication].windows.firstObject;
            if (window) {
                UIAlertController *alert = [UIAlertController 
                    alertControllerWithTitle:@"Monica Pro" 
                    message:@"✅ Pro Unlocked!\n\n✅ All Models Available\n✅ No Subscription Required\n\n🚀 Enjoy!" 
                    preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
                [window.rootViewController presentViewController:alert animated:YES completion:nil];
            }
        });
    }
    
    return result;
}
%end

// ============================================================
// 7. HOOK NSFILEMANAGER
// ============================================================
%hook NSFileManager

- (BOOL)fileExistsAtPath:(NSString *)path {
    NSArray *jailbreakPaths = @[@"/Applications/Cydia.app", @"/Applications/Sileo.app"];
    for (NSString *jp in jailbreakPaths) {
        if ([path isEqualToString:jp]) return NO;
    }
    return %orig;
}
%end

// ============================================================
// 8. LOG
// ============================================================
%ctor {
    NSLog(@"=========================================");
    NSLog(@"🚀 Monica Pro Unlock Loaded!");
    NSLog(@"✅ Pro Features: UNLOCKED");
    NSLog(@"✅ RevenueCat: BYPASSED");
    NSLog(@"✅ Subscription: ACTIVE");
    NSLog(@"=========================================");
}
