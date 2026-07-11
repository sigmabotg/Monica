#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
#pragma GCC diagnostic ignored "-Wobjc-method-access"

#import <UIKit/UIKit.h>

// ============================================================
// BIẾN LƯU TRẠNG THÁI
// ============================================================
static BOOL hasShownNotice = NO;

// ============================================================
// 1. HOOK MONICA - PRO UNLOCK
// ============================================================

// Hook NSUserDefaults - Bypass key pro/premium/trial
%hook NSUserDefaults

- (BOOL)boolForKey:(NSString *)key {
    NSArray *proKeys = @[
        @"isPro", @"hasPro", @"proUser", @"isProUser",
        @"isPremium", @"hasPremium", @"premiumUser",
        @"isVip", @"hasVip", @"vipUser",
        @"isSubscribed", @"hasSubscription",
        @"isTrial", @"inTrial", @"trialActive",
        @"isUnlocked", @"hasUnlocked"
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

%end

// ============================================================
// 2. HOOK MONICA PRO MANAGER
// ============================================================
%hook MonicaProManager

- (BOOL)isProUser {
    return YES;
}
- (BOOL)hasProFeatures {
    return YES;
}
- (BOOL)isPremiumUnlocked {
    return YES;
}
- (BOOL)isVipUser {
    return YES;
}
- (int)userLevel {
    return 999;
}
- (id)getProStatus {
    return @{
        @"pro": @YES,
        @"expiry": @"2099-12-31",
        @"status": @"active"
    };
}
%end

// ============================================================
// 3. HOOK TRIAL - KÉO DÀI VÔ HẠN
// ============================================================
%hook MonicaTrialManager

- (BOOL)isTrialActive {
    return YES;  // Luôn trong thời gian dùng thử
}
- (BOOL)isTrialExpired {
    return NO;   // Không bao giờ hết hạn
}
- (BOOL)hasTrialUsed {
    return NO;   // Chưa dùng thử bao giờ
}
- (int)trialDaysRemaining {
    return 3650; // 10 năm dùng thử
}
- (NSString *)trialExpiryDate {
    return @"2099-12-31"; // Ngày hết hạn xa vô tận
}
- (id)getTrialInfo {
    return @{
        @"status": @"active",
        @"days_remaining": @3650,
        @"expiry": @"2099-12-31",
        @"is_trial": @YES,
        @"trial_used": @NO,
        @"trial_expired": @NO
    };
}
%end

// ============================================================
// 4. HOOK SUBSCRIPTION - LUÔN ACTIVE
// ============================================================
%hook MonicaSubscriptionManager

- (BOOL)hasActiveSubscription {
    return YES;
}
- (BOOL)isSubscribed {
    return YES;
}
- (id)getSubscriptionInfo {
    return @{
        @"status": @"active",
        @"plan": @"pro",
        @"expiry": @"2099-12-31",
        @"is_trial": @NO,
        @"trial_used": @NO,
        @"trial_expired": @NO
    };
}
%end

// ============================================================
// 5. HOOK IAP - IN-APP PURCHASE
// ============================================================
%hook SKPaymentQueue

+ (BOOL)canMakePayments {
    return YES;
}

%end

// ============================================================
// 6. HOOK RECEIPT - BỎ QUA KIỂM TRA
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
// 7. HIỂN THỊ THÔNG BÁO UNLOCK
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
                    message:@"✅ Pro Features Unlocked!\n\n✅ Premium Access\n✅ Trial Extended Forever\n✅ All AI Features Unlocked\n\n🚀 Enjoy!" 
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
// 8. BYPASS JAILBREAK DETECTION
// ============================================================
%hook UIApplication

- (BOOL)canOpenURL:(NSURL *)url {
    if ([url.scheme containsString:@"cydia"] || [url.scheme containsString:@"sileo"]) {
        return NO;
    }
    return %orig;
}
%end

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
// 9. LOG KHỞI ĐỘNG
// ============================================================
%ctor {
    NSLog(@"=========================================");
    NSLog(@"🚀 Monica Pro Unlock Loaded!");
    NSLog(@"✅ Pro Features: YES");
    NSLog(@"✅ Trial: EXTENDED FOREVER");
    NSLog(@"✅ All AI Features: UNLOCKED");
    NSLog(@"=========================================");
}

%end
