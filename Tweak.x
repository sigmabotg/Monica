#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
#pragma GCC diagnostic ignored "-Wobjc-method-access"

#import <UIKit/UIKit.h>

static BOOL hasShownNotice = NO;

// ============================================================
// 1. HOOK REVENUECAT - QUẢN LÝ SUBSCRIPTION
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
// 2. HOOK FLUTTER PURCHASES
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
// 3. HOOK NSUSERDEFAULTS
// ============================================================
%hook NSUserDefaults

- (BOOL)boolForKey:(NSString *)key {
    NSArray *proKeys = @[@"pro", @"premium", @"vip", @"unlock", @"trial", @"isPro", @"hasPro"];
    for (NSString *k in proKeys) {
        if ([key.lowercaseString containsString:k]) {
            return YES;
        }
    }
    return %orig;
}
%end

// ============================================================
// 4. HIỂN THỊ THÔNG BÁO
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
                    message:@"✅ Pro Unlocked!\n✅ Trial Extended!" 
                    preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
                [window.rootViewController presentViewController:alert animated:YES completion:nil];
            }
        });
    }
    return result;
}
%end

%ctor {
    NSLog(@"🚀 Monica Pro Unlock Loaded!");
}
