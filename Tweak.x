#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
#pragma GCC diagnostic ignored "-Wobjc-method-access"

#import <UIKit/UIKit.h>

static BOOL hasShownNotice = NO;

// ============================================================
// 1. CHỈ HOOK NSUSERDEFAULTS (AN TOÀN NHẤT)
// ============================================================
%hook NSUserDefaults

- (BOOL)boolForKey:(NSString *)key {
    NSArray *proKeys = @[
        @"pro", @"premium", @"vip", @"unlock", 
        @"trial", @"subscribed", @"isPro", @"hasPro"
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
        [key containsString:@"pro"] ||
        [key containsString:@"trial"]) {
        return @{
            @"status": @"active",
            @"expiry": @"2099-12-31",
            @"plan": @"pro"
        };
    }
    return %orig;
}

%end

// ============================================================
// 2. HIỂN THỊ THÔNG BÁO
// ============================================================
%hook AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    BOOL result = %orig;
    
    if (!hasShownNotice) {
        hasShownNotice = YES;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            UIWindow *window = [UIApplication sharedApplication].windows.firstObject;
            if (window) {
                UIAlertController *alert = [UIAlertController 
                    alertControllerWithTitle:@"Monica" 
                    message:@"✅ Tweak loaded!" 
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
// 3. LOG
// ============================================================
%ctor {
    NSLog(@"🚀 Monica Tweak Loaded (Safe Mode)");
}
