#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#define PREF_DOMAIN @"com.frankfiorante.yticonswitcher"
#define ICONS_DIR @"/var/mobile/Library/Application Support/YTIconSwitcher/icons/"

static NSString *selectedIconName = nil;
static UIImage *cachedIcon = nil;

static NSSet<NSString *> *iconAssetNames() {
    static NSSet *names;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        names = [NSSet setWithObjects:
            @"AppIcon",
            @"AppIcon60x60",
            @"AppIcon76x76",
            @"AppIcon83.5x83.5",
            @"AppIcon120x120",
            @"AppIcon152x152",
            @"AppIcon167x167",
            @"AppIcon180x180",
            @"YTLogo",
            @"UIApplicationIcon",
            nil];
    });
    return names;
}

static void reloadPreferences() {
    NSDictionary *prefs = [[NSDictionary alloc] initWithContentsOfFile:
        [@"/var/mobile/Library/Preferences/" stringByAppendingPathComponent:
            [PREF_DOMAIN stringByAppendingPathExtension:@"plist"]]];
    NSString *newName = prefs[@"selectedIcon"] ?: @"default";
    if (![newName isEqualToString:selectedIconName]) {
        selectedIconName = newName;
        cachedIcon = nil;
    }
}

static UIImage *customIcon() {
    if (cachedIcon) return cachedIcon;
    NSString *path = [ICONS_DIR stringByAppendingPathComponent:
        [selectedIconName stringByAppendingPathExtension:@"png"]];
    UIImage *img = [UIImage imageWithContentsOfFile:path];
    if (img) cachedIcon = img;
    return img;
}

%hook UIImage

+ (UIImage *)imageNamed:(NSString *)name {
    if ([iconAssetNames() containsObject:name]) {
        UIImage *custom = customIcon();
        if (custom) return custom;
    }
    return %orig(name);
}

+ (UIImage *)imageNamed:(NSString *)name inBundle:(NSBundle *)bundle compatibleWithTraitCollection:(UITraitCollection *)traitCollection {
    if ([iconAssetNames() containsObject:name]) {
        UIImage *custom = customIcon();
        if (custom) return custom;
    }
    return %orig(name, bundle, traitCollection);
}

%end

%hook NSBundle

- (NSString *)pathForResource:(NSString *)name ofType:(NSString *)ext {
    if (name && [iconAssetNames() containsObject:name] &&
        (ext == nil || [ext isEqualToString:@"png"])) {
        NSString *customPath = [ICONS_DIR stringByAppendingPathComponent:
            [selectedIconName stringByAppendingPathExtension:@"png"]];
        if ([[NSFileManager defaultManager] fileExistsAtPath:customPath]) {
            return customPath;
        }
    }
    return %orig(name, ext);
}

%end

%ctor {
    reloadPreferences();
    CFNotificationCenterAddObserver(
        CFNotificationCenterGetDarwinNotifyCenter(),
        NULL,
        (CFNotificationCallback)^(CFNotificationCenterRef center, void *observer,
                                   CFStringRef name, const void *object,
                                   CFDictionaryRef userInfo) {
            selectedIconName = nil;
            cachedIcon = nil;
            reloadPreferences();
        },
        CFSTR("com.frankfiorante.yticonswitcher/prefsChanged"),
        NULL,
        CFNotificationSuspensionBehaviorDeliverImmediately
    );
}
