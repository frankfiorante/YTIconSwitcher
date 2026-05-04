#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#define PREF_ICON_KEY  @"selectedIcon"
#define ICONS_SUBDIR   @"YTIconSwitcher"
#define PREFS_FILENAME @"YTIconSwitcher.plist"

// ─── State ────────────────────────────────────────────────────────────────────

static NSString *sSelectedIcon = nil;
static UIImage  *sCachedImage  = nil;

static NSSet<NSString *> *iconAssetNames(void) {
    static NSSet *s;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        s = [NSSet setWithObjects:
             @"AppIcon", @"AppIcon60x60", @"AppIcon76x76",
             @"AppIcon83.5x83.5", @"AppIcon120x120", @"AppIcon152x152",
             @"AppIcon167x167", @"AppIcon180x180",
             @"YTLogo", @"UIApplicationIcon", nil];
    });
    return s;
}

// ─── Storage paths ────────────────────────────────────────────────────────────

// Icons live in Documents/YTIconSwitcher/ — reachable via Finder file sharing
// (cyan injects the IPA with -f, which sets UIFileSharingEnabled)
static NSString *iconsDirPath(void) {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject
            stringByAppendingPathComponent:ICONS_SUBDIR];
}

static NSString *prefsFilePath(void) {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject
            stringByAppendingPathComponent:PREFS_FILENAME];
}

// ─── Preferences ──────────────────────────────────────────────────────────────

static void reloadPrefs(void) {
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:prefsFilePath()] ?: @{};
    NSString *val = prefs[PREF_ICON_KEY] ?: @"default";
    if (![val isEqualToString:sSelectedIcon]) {
        sSelectedIcon = val;
        sCachedImage  = nil;
    }
}

static void saveSelection(NSString *name) {
    NSMutableDictionary *prefs =
        [([NSDictionary dictionaryWithContentsOfFile:prefsFilePath()] ?: @{}) mutableCopy];
    prefs[PREF_ICON_KEY] = name;
    [prefs writeToFile:prefsFilePath() atomically:YES];
    sSelectedIcon = name;
    sCachedImage  = nil;
}

// ─── Icon loading ─────────────────────────────────────────────────────────────

static NSArray<NSString *> *availableIcons(void) {
    NSMutableArray *result = [NSMutableArray array];
    for (NSString *file in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:iconsDirPath() error:nil]) {
        if ([file.pathExtension.lowercaseString isEqualToString:@"png"])
            [result addObject:file.stringByDeletingPathExtension];
    }
    return [result sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}

static UIImage *customIconImage(void) {
    if (sCachedImage) return sCachedImage;
    if (!sSelectedIcon || [sSelectedIcon isEqualToString:@"default"]) return nil;
    NSString *path = [[iconsDirPath() stringByAppendingPathComponent:sSelectedIcon]
                      stringByAppendingPathExtension:@"png"];
    UIImage *img = [UIImage imageWithContentsOfFile:path];
    if (img) sCachedImage = img;
    return img;
}

// ─── Icon picker UI ───────────────────────────────────────────────────────────

static void presentIconPicker(UIViewController *from) {
    NSArray<NSString *> *icons = availableIcons();
    NSString *currentLabel = (sSelectedIcon && ![sSelectedIcon isEqualToString:@"default"])
        ? sSelectedIcon : @"Default";
    NSString *msg = icons.count
        ? [NSString stringWithFormat:@"Current: %@", currentLabel]
        : @"No icons found.\n\nAdd 180×180 PNG files to:\nDocuments/YTIconSwitcher/\n(via Finder file sharing)";

    UIAlertController *sheet = [UIAlertController
        alertControllerWithTitle:@"Icon Theme"
        message:msg
        preferredStyle:UIAlertControllerStyleActionSheet];

    if (icons.count) {
        NSString *defTitle = [sSelectedIcon isEqualToString:@"default"] ? @"Default ✓" : @"Default";
        [sheet addAction:[UIAlertAction actionWithTitle:defTitle
            style:UIAlertActionStyleDefault
            handler:^(UIAlertAction *a) { saveSelection(@"default"); }]];
        for (NSString *name in icons) {
            NSString *title = [name isEqualToString:sSelectedIcon]
                ? [NSString stringWithFormat:@"%@ ✓", name] : name;
            [sheet addAction:[UIAlertAction actionWithTitle:title
                style:UIAlertActionStyleDefault
                handler:^(UIAlertAction *a) { saveSelection(name); }]];
        }
    }

    [sheet addAction:[UIAlertAction actionWithTitle:@"Cancel"
        style:UIAlertActionStyleCancel handler:nil]];

    UIPopoverPresentationController *pop = sheet.popoverPresentationController;
    pop.sourceView = from.view;
    pop.sourceRect = CGRectMake(CGRectGetMidX(from.view.bounds),
                                CGRectGetMidY(from.view.bounds), 1, 1);
    pop.permittedArrowDirections = 0;

    [from presentViewController:sheet animated:YES completion:nil];
}

// ─── Core hooks ───────────────────────────────────────────────────────────────

%hook UIImage

+ (UIImage *)imageNamed:(NSString *)name {
    if (name && [iconAssetNames() containsObject:name]) {
        UIImage *img = customIconImage();
        if (img) return img;
    }
    return %orig;
}

+ (UIImage *)imageNamed:(NSString *)name
               inBundle:(NSBundle *)bundle
compatibleWithTraitCollection:(UITraitCollection *)tc {
    if (name && [iconAssetNames() containsObject:name]) {
        UIImage *img = customIconImage();
        if (img) return img;
    }
    return %orig;
}

%end

%hook NSBundle

- (NSString *)pathForResource:(NSString *)name ofType:(NSString *)ext {
    if (name && [iconAssetNames() containsObject:name] &&
        (!ext || [ext.lowercaseString isEqualToString:@"png"])) {
        NSString *path = [[iconsDirPath() stringByAppendingPathComponent:sSelectedIcon]
                          stringByAppendingPathExtension:@"png"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:path])
            return path;
    }
    return %orig;
}

%end

// ─── Settings button in YouTube's navigation bar ──────────────────────────────
// Follows the same pattern as iSponsorBlock (JustSettings group).

%hook YTRightNavigationButtons
%property (retain, nonatomic) YTQTMButton *ytisButton;

- (NSMutableArray *)buttons {
    NSMutableArray *retVal = %orig.mutableCopy;
    [self.ytisButton removeFromSuperview];
    [self addSubview:self.ytisButton];

    UIImage *img = [[UIImage systemImageNamed:@"swatchpalette.fill"]
                    imageWithTintColor:UIColor.labelColor
                    renderingMode:UIImageRenderingModeAlwaysOriginal];

    if (!self.ytisButton) {
        self.ytisButton = [%c(YTQTMButton) iconButton];
        [self.ytisButton enableNewTouchFeedback];
        self.ytisButton.frame = CGRectMake(0, 0, 40, 40);
        [self.ytisButton addTarget:self action:@selector(ytis_showPicker:)
                  forControlEvents:UIControlEventTouchUpInside];
        [retVal insertObject:self.ytisButton atIndex:0];
    }
    [self.ytisButton setImage:img forState:UIControlStateNormal];
    return retVal;
}

- (NSMutableArray *)visibleButtons {
    NSMutableArray *retVal = %orig.mutableCopy;
    [self setLeadingPadding:-10];
    if (self.ytisButton) {
        [self.ytisButton removeFromSuperview];
        [self addSubview:self.ytisButton];
        [retVal insertObject:self.ytisButton atIndex:0];
    }
    return retVal;
}

%new
- (void)ytis_showPicker:(UIButton *)sender {
    UIViewController *root = [UIApplication sharedApplication].delegate.window.rootViewController;
    while (root.presentedViewController) root = root.presentedViewController;
    presentIconPicker(root);
}

%end

// ─── Init ─────────────────────────────────────────────────────────────────────

%ctor {
    reloadPrefs();
    %init;
}
