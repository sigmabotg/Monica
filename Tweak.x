#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
#pragma GCC diagnostic ignored "-Wobjc-method-access"

#import <UIKit/UIKit.h>

static BOOL hasShownNotice = NO;

// ============================================================
// 1. BYPASS NSUSERDEFAULTS
// ============================================================
%hook NSUserDefaults

- (BOOL)boolForKey:(NSString *)key {
    NSArray *trialKeys = @[
        @"isTrial", @"hasTrial", @"trialActive", @"isTrialUser",
        @"inTrial", @"inTrialPeriod", @"trialPeriod", @"trialMode",
        @"trialExpired", @"isTrialExpired", @"trialUsed", @"isTrialUsed",
        @"trialDays", @"trialRemaining", @"trialLeft",
        @"isPro", @"hasPro", @"proUser", @"isProUser",
        @"isPremium", @"hasPremium", @"premiumUser",
        @"isVip", @"hasVip", @"vipUser",
        @"isSubscribed", @"hasSubscription", @"subscriptionActive",
        @"isUnlocked", @"hasUnlocked"
    ];
    for (NSString *k in trialKeys) {
        if ([key.lowercaseString containsString:k]) {
            return YES;
        }
    }
    return %orig;
}

- (id)objectForKey:(NSString *)key {
    if ([key containsString:@"trial"] || 
        [key containsString:@"subscription"] || 
        [key containsString:@"purchase"] || 
        [key containsString:@"receipt"] ||
        [key containsString:@"pro"] ||
        [key containsString:@"premium"]) {
        return @{
            @"status": @"active",
            @"expiry": @"2099-12-31",
            @"plan": @"pro",
            @"is_trial": @YES,
            @"trial_used": @NO,
            @"trial_expired": @NO,
            @"trial_days": @3650,
            @"trial_remaining": @3650,
            @"is_pro": @YES,
            @"is_premium": @YES
        };
    }
    return %orig;
}

- (void)setBool:(BOOL)value forKey:(NSString *)key {
    NSArray *forceKeys = @[@"trial", @"pro", @"premium", @"vip", @"unlock", @"subscribed"];
    for (NSString *k in forceKeys) {
        if ([key.lowercaseString containsString:k]) {
            %orig(YES, key);
            return;
        }
    }
    %orig;
}

- (void)setObject:(id)value forKey:(NSString *)key {
    NSArray *blockKeys = @[@"trial", @"expired", @"subscription_status", @"trial_end"];
    for (NSString *k in blockKeys) {
        if ([key.lowercaseString containsString:k]) {
            return;
        }
    }
    %orig;
}
%end  // <--- 1

// ============================================================
// 2. HOOK TRIAL MANAGER
// ============================================================
%hook MonicaTrialManager

- (BOOL)isTrialActive { return YES; }
- (BOOL)isTrialExpired { return NO; }
- (BOOL)hasTrialUsed { return NO; }
- (BOOL)inTrialPeriod { return YES; }
- (BOOL)isTrialUser { return YES; }
- (int)trialDaysRemaining { return 3650; }
- (int)trialTotalDays { return 3650; }
- (int)trialDaysUsed { return 0; }
- (NSString *)trialExpiryDate { return @"2099-12-31"; }
- (NSString *)trialStartDate { return @"2024-01-01"; }
- (id)getTrialInfo {
    return @{
        @"status": @"active",
        @"days_remaining": @3650,
        @"days_total": @3650,
        @"days_used": @0,
        @"expiry": @"2099-12-31",
        @"is_trial": @YES,
        @"trial_used": @NO,
        @"trial_expired": @NO,
        @"trial_active": @YES
    };
}
%end  // <--- 2

// ============================================================
// 3. HOOK SUBSCRIPTION
// ============================================================
%hook MonicaSubscriptionManager

- (BOOL)hasActiveSubscription { return YES; }
- (BOOL)isSubscribed { return YES; }
- (id)getSubscriptionInfo {
    return @{
        @"status": @"active",
        @"plan": @"pro",
        @"expiry": @"2099-12-31",
        @"is_trial": @YES,
        @"trial_used": @NO,
        @"trial_expired": @NO
    };
}
%end  // <--- 3

// ============================================================
// 4. HOOK PRO MANAGER
// ============================================================
%hook MonicaProManager

- (BOOL)isProUser { return YES; }
- (BOOL)hasProFeatures { return YES; }
- (BOOL)isPremiumUnlocked { return YES; }
- (int)userLevel { return 999; }
- (id)getProStatus {
    return @{
        @"pro": @YES,
        @"expiry": @"2099-12-31",
        @"status": @"active"
    };
}
%end  // <--- 4

// ============================================================
// 5. HOOK IAP
// ============================================================
%hook SKPaymentQueue

+ (BOOL)canMakePayments { return YES; }
%end  // <--- 5

// ============================================================
// 6. HOOK RECEIPT
// ============================================================
%hook NSBundle

- (id)objectForInfoDictionaryKey:(NSString *)key {
    if ([key containsString:@"Receipt"] || [key containsString:@"receipt"]) {
        return @"valid";
    }
    return %orig;
}
%end  // <--- 6

// ============================================================
// 7. HOOK APPSDELEGATE
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
                    message:@"✅ Trial Extended Forever!\n\n✅ 3650 Days Remaining\n✅ All Features Unlocked\n✅ Pro Access Granted\n\n🚀 Enjoy!" 
                    preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
                [window.rootViewController presentViewController:alert animated:YES completion:nil];
            }
        });
    }
    
    return result;
}
%end  // <--- 7

// ============================================================
// 8. HOOK UIAPPLICATION
// ============================================================
%hook UIApplication

- (BOOL)canOpenURL:(NSURL *)url {
    if ([url.scheme containsString:@"cydia"] || [url.scheme containsString:@"sileo"]) {
        return NO;
    }
    return %orig;
}
%end  // <--- 8

// ============================================================
// 9. HOOK NSFILEMANAGER
// ============================================================
%hook NSFileManager

- (BOOL)fileExistsAtPath:(NSString *)path {
    NSArray *jailbreakPaths = @[@"/Applications/Cydia.app", @"/Applications/Sileo.app"];
    for (NSString *jp in jailbreakPaths) {
        if ([path isEqualToString:jp]) return NO;
    }
    return %orig;
}
%end  // <--- 9

// ============================================================
// 10. KHỞI TẠO (KHÔNG CÓ %END)
// ============================================================
%ctor {
    NSLog(@"=========================================");
    NSLog(@"🚀 Monica Trial Extender Loaded!");
    NSLog(@"✅ Bundle ID: im.monica.app.monica");
    NSLog(@"✅ Trial Status: ACTIVE");
    NSLog(@"✅ Trial Days: 3650");
    NSLog(@"✅ Trial Expiry: 2099-12-31");
    NSLog(@"✅ Pro Features: UNLOCKED");
    NSLog(@"=========================================");
}
// <--- KHÔNG CÓ %END Ở ĐÂY
