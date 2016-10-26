//  Created by Michael Kirk on 10/25/16.
//  Copyright © 2016 Open Whisper Systems. All rights reserved.

import Foundation

let TAG = "[PushTokenSyncer]"

@objc(OWSPushTokensSyncJob)
class PushTokensSyncJob : NSObject {

    let pushManager: PushManager
    let tokenStorage: PropertyListPreferences
    let textSecureAccountManager: TSAccountManager
    let redPhoneAccountManager: RPAccountManager

    required init(pushManager:PushManager, tokenStorage:PropertyListPreferences, textSecureAccountManager:TSAccountManager, redPhoneAccountManager:RPAccountManager) {
        self.pushManager = pushManager
        self.tokenStorage = tokenStorage
        self.textSecureAccountManager = textSecureAccountManager
        self.redPhoneAccountManager = redPhoneAccountManager
    }

    class func run(pushManager:PushManager, tokenStorage:PropertyListPreferences, textSecureAccountManager:TSAccountManager, redPhoneAccountManager:RPAccountManager) {
        let job = self.init(pushManager:pushManager, tokenStorage:tokenStorage, textSecureAccountManager:textSecureAccountManager, redPhoneAccountManager:redPhoneAccountManager)
        job.run()
    }

    func run() {
        Logger.debug("\(TAG) Starting.")
        self.pushManager.validateUserNotificationSettings()
        self.pushManager.requestPushToken(
            success: { (pushToken: String, voipToken: String) in
                self.updatePushToken(pushToken, voipToken:voipToken)
            },
            failure: { (error: Error) in
                Logger.error("\(TAG) failed to update push tokens with error:\(error)")
        });
    }

    func updatePushToken(_ pushToken: String, voipToken: String) {
        if (tokenStorage.getPushToken() == pushToken && tokenStorage.getVoipToken() == voipToken) {
            Logger.debug("\(TAG) Push tokens are already in sync.")
            return;
        }

        Logger.info("\(TAG) Push tokens have changed.")
        self.textSecureAccountManager.registerForPushNotifications(
            withPushToken: pushToken,
            voipToken: voipToken,
            success: {
                Logger.info("\(TAG) updated text-secure service push tokens.")
            },
            failure: { (error: Error?) in
                Logger.error("\(TAG) failed to updated text-secure service push tokens with error:\(error)")
        })

        // TODO if already registered, just update with the /apn endpoint, but does it accept voiptokens?
        self.textSecureAccountManager.obtainRPRegistrationToken(
            success: { (rpRegistrationToken: String) in                
                self.redPhoneAccountManager.register(
                    withTsToken:rpRegistrationToken,
                    pushToken:pushToken,
                    voipToken:voipToken,
                    success: {
                        Logger.info("\(TAG) updated redphone service push tokens.")
                    },
                    failure: { (error: Error?) in
                        Logger.error("\(TAG) failed to updated redphone service push tokens with error:\(error)")
                })
            },
            failure: { (error: Error?) in
                Logger.error("\(TAG) failed to get redphone registration token with error:\(error)")
        })
    }
}
