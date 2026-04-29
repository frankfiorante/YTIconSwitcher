#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <UIKit/UIKit.h>
#include <spawn.h>

#define PREF_DOMAIN @"com.frankfiorante.yticonswitcher"
#define NOTIF_KEY @"com.frankfiorante.yticonswitcher/prefsChanged"

@interface YTIconSwitcherRootListController : PSListController
@end

@implementation YTIconSwitcherRootListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    }
    return _specifiers;
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    NSString *key = specifier.properties[@"key"];
    CFPreferencesSetAppValue((__bridge CFStringRef)key,
                             (__bridge CFPropertyListRef)value,
                             (__bridge CFStringRef)PREF_DOMAIN);
    CFPreferencesSynchronize((__bridge CFStringRef)PREF_DOMAIN,
                             kCFPreferencesCurrentUser,
                             kCFPreferencesAnyHost);
    CFNotificationCenterPostNotification(
        CFNotificationCenterGetDarwinNotifyCenter(),
        (CFStringRef)NOTIF_KEY, NULL, NULL, YES);
}

- (id)readPreferenceValue:(PSSpecifier *)specifier {
    NSString *key = specifier.properties[@"key"];
    CFPropertyListRef val = CFPreferencesCopyAppValue((__bridge CFStringRef)key,
                                                      (__bridge CFStringRef)PREF_DOMAIN);
    return val ? CFBridgingRelease(val) : specifier.properties[@"default"];
}

- (void)respringTapped {
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"Respring"
        message:@"Respring to apply icon change to the home screen?"
        preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Respring" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        pid_t pid;
        const char *args[] = {"killall", "-9", "SpringBoard", NULL};
        posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char *const *)args, NULL);
    }]];
    [self.navigationController presentViewController:alert animated:YES completion:nil];
}

- (void)refreshIconCache {
    pid_t pid;
    const char *args[] = {"uicache", "-p", "/Applications/YouTube.app", NULL};
    posix_spawn(&pid, "/usr/bin/uicache", NULL, NULL, (char *const *)args, NULL);
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"Done"
        message:@"Icon cache refreshed. You may need to respring."
        preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self.navigationController presentViewController:alert animated:YES completion:nil];
}

@end
