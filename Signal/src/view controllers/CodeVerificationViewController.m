//
//  CodeVerificationViewController.m
//  Signal
//
//  Created by Dylan Bourgeois on 13/11/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "CodeVerificationViewController.h"
#import "SignalsNavigationController.h"
#import "SignalsViewController.h"
#import <SignalServiceKit/OWSError.h>
#import <SignalServiceKit/TSAccountManager.h>
#import <SignalServiceKit/TSStorageManager+keyingMaterial.h>

NSString *const kCompletedRegistrationSegue = @"CompletedRegistration";

@interface CodeVerificationViewController ()

@end

@implementation CodeVerificationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initializeKeyboardHandlers];
    _headerLabel.text               = NSLocalizedString(@"VERIFICATION_HEADER", @"");
    _challengeTextField.placeholder = NSLocalizedString(@"VERIFICATION_CHALLENGE_DEFAULT_TEXT", @"");
    _challengeTextField.delegate    = self;
    [_challengeButton setTitle:NSLocalizedString(@"VERIFICATION_CHALLENGE_SUBMIT_CODE", @"")
                      forState:UIControlStateNormal];

    [_sendCodeViaSMSAgainButton setTitle:NSLocalizedString(@"VERIFICATION_CHALLENGE_SUBMIT_AGAIN", @"")
                                forState:UIControlStateNormal];
    [_sendCodeViaVoiceButton
        setTitle:[@"     " stringByAppendingString:NSLocalizedString(@"VERIFICATION_CHALLENGE_SEND_VIAVOICE", @"")]
        forState:UIControlStateNormal];
    [_changeNumberButton
        setTitle:[@"     " stringByAppendingString:NSLocalizedString(@"VERIFICATION_CHALLENGE_CHANGE_NUMBER", @"")]
        forState:UIControlStateNormal];
}

- (nullable NSError *)validateChallengeTextField
{
    if ([self validationCodeFromTextField].length == 0) {
        return OWSErrorWithCodeDescription(OWSErrorCodeUserError,
            NSLocalizedString(@"REGISTRATION_ERROR_BLANK_VERIFICATION_CODE", @"alert body during registration"));
    }
    return nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self enableServerActions:YES];
    [_phoneNumberEntered setText:
        [PhoneNumber bestEffortFormatPartialUserSpecifiedTextToLookLikeAPhoneNumber:[TSAccountManager localNumber]]];
    [self adjustScreenSizes];
}

- (void)startActivityIndicator
{
    [self.submitCodeSpinner startAnimating];
    [self enableServerActions:NO];
    [_challengeTextField resignFirstResponder];
}

- (void)stopActivityIndicator
{
    [self enableServerActions:YES];
    [self.submitCodeSpinner stopAnimating];
}

- (IBAction)verifyChallengeAction:(id)sender
{
    [self startActivityIndicator];

    NSError *validationError = [self validateChallengeTextField];
    if (validationError) {
        [self stopActivityIndicator];
        DDLogWarn(@"%@ Failed with validation error: %@", self.tag, validationError);
        [self presentAlertWithVerificationError:validationError];
        return;
    }

    [self.submitCodeSpinner startAnimating];
    [TSAccountManager verifyAccountWithCode:[self validationCodeFromTextField]
        success:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [self stopActivityIndicator];
                [self performSegueWithIdentifier:kCompletedRegistrationSegue sender:nil];
            });
        }
        failure:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self stopActivityIndicator];
                [self presentAlertWithVerificationError:error];

            });
            DDLogError(@"%@ error verifying challenge: %@", self.tag, error);
        }];
}

- (void)presentAlertWithVerificationError:(NSError *)error
{
    UIAlertController *alertController = [UIAlertController
        alertControllerWithTitle:NSLocalizedString(@"REGISTRATION_VERIFICATION_FAILED_TITLE", @"Alert view title")
                         message:error.localizedDescription
                  preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"DISMISS_BUTTON_TEXT", nil)
                                                            style:UIAlertActionStyleDefault
                                                          handler:nil];
    [alertController addAction:dismissAction];

    [self presentViewController:alertController animated:YES completion:nil];
}

- (NSString *)validationCodeFromTextField {
    return [_challengeTextField.text stringByReplacingOccurrencesOfString:@"-" withString:@""];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    DDLogInfo(@"%@ preparing for CompletedRegistrationSeque", self.tag);
    if ([segue.identifier isEqualToString:kCompletedRegistrationSegue]) {
        if (![segue.destinationViewController isKindOfClass:[SignalsNavigationController class]]) {
            DDLogError(@"%@ Unexpected destination view controller: %@", self.tag, segue.destinationViewController);
            return;
        }

        SignalsNavigationController *snc = (SignalsNavigationController *)segue.destinationViewController;
        if (![snc.topViewController isKindOfClass:[SignalsViewController class]]) {
            DDLogError(@"%@ Unexpected top view controller: %@", self.tag, snc.topViewController);
            return;
        }

        DDLogDebug(@"%@ notifying signals view controller of new user.", self.tag);
        SignalsViewController *signalsViewController = (SignalsViewController *)snc.topViewController;
        signalsViewController.newlyRegisteredUser = YES;
    }
}

//- (TOCFuture *)pushRegistration {
//    TOCFutureSource *pushAndRegisterFuture = [[TOCFutureSource alloc] init];
//
//    [[PushManager sharedManager] validateUserNotificationSettings];
//    [[PushManager sharedManager] requestPushTokenWithSuccess:^(NSString *pushToken, NSString *voipToken) {
//      NSMutableArray *pushTokens = [NSMutableArray arrayWithObject:pushToken];
//
//      if (voipToken) {
//          [pushTokens addObject:voipToken];
//      }
//
//      [pushAndRegisterFuture trySetResult:pushTokens];
//    }
//        failure:^(NSError *error) {
//          [pushAndRegisterFuture trySetFailure:error];
//        }];
//
//    return pushAndRegisterFuture.future;
//}

//- (TOCFuture *)getRPRegistrationToken {
//    TOCFutureSource *redPhoneTokenFuture = [[TOCFutureSource alloc] init];
//
//    [TSAccountManager obtainRPRegistrationToken:^(NSString *rpRegistrationToken) {
//      [redPhoneTokenFuture trySetResult:rpRegistrationToken];
//    }
//        failure:^(NSError *error) {
//          [redPhoneTokenFuture trySetFailure:error];
//        }];
//
//    return redPhoneTokenFuture.future;
//}
//
//- (TOCFuture *)redphoneRegistrationWithTSToken:(NSString *)tsToken
//                                     pushToken:(NSString *)pushToken
//                                     voipToken:(NSString *)voipToken {
//    TOCFutureSource *rpRegistration = [[TOCFutureSource alloc] init];
//
//    [RPAccountManager registrationWithTsToken:tsToken
//        pushToken:pushToken
//        voipToken:voipToken
//        success:^{
//          [rpRegistration trySetResult:@YES];
//        }
//        failure:^(NSError *error) {
//          [rpRegistration trySetFailure:error];
//        }];
//
//    return rpRegistration.future;
//}

#pragma mark - Send codes again
- (IBAction)sendCodeSMSAction:(id)sender {
    [self enableServerActions:NO];

    [_requestCodeAgainSpinner startAnimating];
    [TSAccountManager rerequestSMSWithSuccess:^{
        DDLogInfo(@"%@ Successfully requested SMS code", self.tag);
        [self enableServerActions:YES];
        [_requestCodeAgainSpinner stopAnimating];
    }
        failure:^(NSError *error) {
            DDLogError(@"%@ Failed to request SMS code with error: %@", self.tag, error);
            [self showRegistrationErrorMessage:error];
            [self enableServerActions:YES];
            [_requestCodeAgainSpinner stopAnimating];
        }];
}

- (IBAction)sendCodeVoiceAction:(id)sender {
    [self enableServerActions:NO];

    [_requestCallSpinner startAnimating];
    [TSAccountManager rerequestVoiceWithSuccess:^{
        DDLogInfo(@"%@ Successfully requested voice code", self.tag);

        [self enableServerActions:YES];
        [_requestCallSpinner stopAnimating];
    }
        failure:^(NSError *error) {
            DDLogError(@"%@ Failed to request voice code with error: %@", self.tag, error);
            [self showRegistrationErrorMessage:error];
            [self enableServerActions:YES];
            [_requestCallSpinner stopAnimating];
        }];
}

- (void)showRegistrationErrorMessage:(NSError *)registrationError {
    UIAlertView *registrationErrorAV = [[UIAlertView alloc] initWithTitle:registrationError.localizedDescription
                                                                  message:registrationError.localizedRecoverySuggestion
                                                                 delegate:nil
                                                        cancelButtonTitle:NSLocalizedString(@"OK", @"")
                                                        otherButtonTitles:nil, nil];

    [registrationErrorAV show];
}

- (void)enableServerActions:(BOOL)enabled {
    [_challengeButton setEnabled:enabled];
    [_sendCodeViaSMSAgainButton setEnabled:enabled];
    [_sendCodeViaVoiceButton setEnabled:enabled];
}


#pragma mark - Keyboard notifications

- (void)initializeKeyboardHandlers {
    UITapGestureRecognizer *outsideTabRecognizer =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboardFromAppropriateSubView)];
    [self.view addGestureRecognizer:outsideTabRecognizer];
}

- (void)dismissKeyboardFromAppropriateSubView {
    [self.view endEditing:NO];
}

- (BOOL)textField:(UITextField *)textField
    shouldChangeCharactersInRange:(NSRange)range
                replacementString:(NSString *)string {
    if (range.location == 7) {
        return NO;
    }

    if (range.length == 0 &&
        ![[NSCharacterSet decimalDigitCharacterSet] characterIsMember:[string characterAtIndex:0]]) {
        return NO;
    }

    if (range.length == 0 && range.location == 2) {
        textField.text = [NSString stringWithFormat:@"%@%@-", textField.text, string];
        return NO;
    }

    if (range.length == 1 && range.location == 3) {
        range.location--;
        range.length   = 2;
        textField.text = [textField.text stringByReplacingCharactersInRange:range withString:@""];
        return NO;
    }

    return YES;
}

- (void)adjustScreenSizes {
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    CGFloat blueHeaderHeight;

    if (screenHeight < 667) {
        self.signalLogo.hidden = YES;
        blueHeaderHeight       = screenHeight - 400;
    } else {
        blueHeaderHeight = screenHeight - 410;
    }

    _headerConstraint.constant = blueHeaderHeight;
}

#pragma mark - Logging

+ (NSString *)tag
{
    return [NSString stringWithFormat:@"[%@]", self.class];
}

- (NSString *)tag
{
    return self.class.tag;
}

@end
