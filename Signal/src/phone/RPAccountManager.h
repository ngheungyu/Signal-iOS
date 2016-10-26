//
//  RPAccountManager.h
//  Signal
//
//  Created by Frederic Jacobs on 19/12/15.
//  Copyright © 2015 Open Whisper Systems. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@interface RPAccountManager : NSObject

+ (instancetype)sharedInstance;

- (void)registerWithTsToken:(NSString *)tsToken
                  pushToken:(NSString *)pushToken
                  voipToken:(NSString *)voipPushToken
                    success:(void (^)())success
                    failure:(void (^)(NSError *))failure;

@end

NS_ASSUME_NONNULL_END
