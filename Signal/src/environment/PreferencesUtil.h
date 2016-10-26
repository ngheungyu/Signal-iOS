#import "PropertyListPreferences.h"

typedef NS_ENUM(NSUInteger, NotificationType) {
    NotificationNoNameNoPreview,
    NotificationNameNoPreview,
    NotificationNamePreview,
};

typedef NS_ENUM(NSUInteger, TSImageQuality) {
    TSImageQualityUncropped = 1,
    TSImageQualityHigh      = 2,
    TSImageQualityMedium    = 3,
    TSImageQualityLow       = 4
};

@class PhoneNumber;

@interface PropertyListPreferences (PropertyUtil)

- (NSTimeInterval)getCachedOrDefaultDesiredBufferDepth;
- (void)setCachedDesiredBufferDepth:(double)value;

- (BOOL)getHasSentAMessage;
- (void)setHasSentAMessage:(BOOL)enabled;

- (BOOL)getHasArchivedAMessage;
- (void)setHasArchivedAMessage:(BOOL)enabled;

- (BOOL)loggingIsEnabled;
- (void)setLoggingEnabled:(BOOL)flag;

- (BOOL)screenSecurityIsEnabled;
- (void)setScreenSecurity:(BOOL)flag;

- (NotificationType)notificationPreviewType;
- (void)setNotificationPreviewType:(NotificationType)type;
- (NSString *)nameForNotificationPreviewType:(NotificationType)notificationType;

- (BOOL)soundInForeground;
- (void)setSoundInForeground:(BOOL)enabled;

- (BOOL)hasRegisteredVOIPPush;
- (void)setHasRegisteredVOIPPush:(BOOL)enabled;

- (TSImageQuality)imageUploadQuality;

- (NSString *)lastRanVersion;
- (NSString *)setAndGetCurrentVersion;

#pragma mark - Push Tokens

- (void)setPushToken:(NSString *)value;
- (NSString *)getPushToken;

- (void)setVoipToken:(NSString *)value;
- (NSString *)getVoipToken;

@end
