//
//  CordovaPushPlugin.m
//  PushLibrary
//
//  Created by Marcus Koehler on 27.01.14.
//  Copyright (c) 2014 M-Way Solutions GmbH. All rights reserved.
//

#import "MCapPushPlugin.h"
#import <PushLibrary/MCapPushLibrary.h>

@interface MCapPushPlugin (private) <MCapPushDelegate>
@end

@implementation MCapPushPlugin
@synthesize notificationMessage;
@synthesize isInline;
@synthesize callbackId;
@synthesize notificationCallbackId;
@synthesize callback;


#pragma mark -
#pragma mark Memory Management

- (void) dealloc
{
    [notificationMessage release];
    [notificationCallbackId release];
    [callback release];
    [super dealloc];
}

#pragma mark -
#pragma mark Register

- (void)register:(CDVInvokedUrlCommand*)command;
{
    self.callbackId = command.callbackId;
    
    // Check command.arguments here.
    [self.commandDelegate runInBackground:^{
        NSMutableDictionary* options = [command.arguments objectAtIndex:0];
        
        [[MCapPushLibrary sharedInstance] initializeWithDelegate:self];
        UIRemoteNotificationType notificationTypes = UIRemoteNotificationTypeNone;
        
        id badgeArg = [options objectForKey:@"badge"];
        id soundArg = [options objectForKey:@"sound"];
        id alertArg = [options objectForKey:@"alert"];
        id apiKey = [options objectForKey:@"apiKey"];
        id baseURL = [options objectForKey:@"baseURL"];
        
        if ([badgeArg isKindOfClass:[NSString class]])
        {
            if ([badgeArg isEqualToString:@"true"])
                notificationTypes |= UIRemoteNotificationTypeBadge;
        }
        else if ([badgeArg boolValue])
            notificationTypes |= UIRemoteNotificationTypeBadge;
        
        if ([soundArg isKindOfClass:[NSString class]])
        {
            if ([soundArg isEqualToString:@"true"])
                notificationTypes |= UIRemoteNotificationTypeSound;
        }
        else if ([soundArg boolValue])
            notificationTypes |= UIRemoteNotificationTypeSound;
        
        if ([alertArg isKindOfClass:[NSString class]])
        {
            if ([alertArg isEqualToString:@"true"])
                notificationTypes |= UIRemoteNotificationTypeAlert;
        }
        else if ([alertArg boolValue])
            notificationTypes |= UIRemoteNotificationTypeAlert;
        
        if (notificationTypes == UIRemoteNotificationTypeNone)
            NSLog(@"PushPlugin.register: Push notification type is set to none");
        
        [MCapPushLibrary sharedInstance].remoteNotificationTypes = notificationTypes;
        
        
        if (apiKey != nil && [apiKey isKindOfClass:[NSString class]])
        {
            [MCapPushLibrary sharedInstance].apiKey = apiKey;
        }
        
        if (baseURL != nil && [baseURL isKindOfClass:[NSString class]])
        {
            [MCapPushLibrary sharedInstance].baseURL = baseURL;
        }
        
        self.callback = [options objectForKey:@"ecb"];
        isInline = NO;
        
        [[MCapPushLibrary sharedInstance] registerForRemoteNotifications];
    }];
}

#pragma mark -
#pragma mark Unregister

- (void)unregister:(CDVInvokedUrlCommand*)command;
{
    self.callbackId = command.callbackId;

    [[MCapPushLibrary sharedInstance] unregister];
}

#pragma mark -
#pragma mark Push Delegate

- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    [[MCapPushLibrary sharedInstance] registerDeviceToken:deviceToken];
}

- (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
	[self failWithMessage:[error localizedDescription]];
}

#pragma mark -
#pragma mark MCapPushDelegate

- (void) deviceTokenRegisterDidFailWithError: (NSString*)error errorCode: (MCapPushError) mCapPushError
{
    [self failWithMessage: error];

}

- (void) deviceTokenRegisterDidSuccess: (NSString*) deviceToken
{
    NSMutableDictionary *results = [NSMutableDictionary dictionary];
    [results setValue:deviceToken forKey:@"deviceToken"];
    
#if !TARGET_IPHONE_SIMULATOR
    // Get Bundle Info for Remote Registration (handy if you have more than one app)
    [results setValue:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"] forKey:@"appName"];
    [results setValue:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"] forKey:@"appVersion"];
    
    // Check what Notifications the user has turned on.  We registered for all three, but they may have manually disabled some or all of them.
    NSUInteger rntypes = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
    
    // Set the defaults to disabled unless we find otherwise...
    NSString *pushBadge = @"disabled";
    NSString *pushAlert = @"disabled";
    NSString *pushSound = @"disabled";
    
    // Check what Registered Types are turned on. This is a bit tricky since if two are enabled, and one is off, it will return a number 2... not telling you which
    // one is actually disabled. So we are literally checking to see if rnTypes matches what is turned on, instead of by number. The "tricky" part is that the
    // single notification types will only match if they are the ONLY one enabled.  Likewise, when we are checking for a pair of notifications, it will only be
    // true if those two notifications are on.  This is why the code is written this way
    if(rntypes & UIRemoteNotificationTypeBadge){
        pushBadge = @"enabled";
    }
    if(rntypes & UIRemoteNotificationTypeAlert) {
        pushAlert = @"enabled";
    }
    if(rntypes & UIRemoteNotificationTypeSound) {
        pushSound = @"enabled";
    }
    
    [results setValue:pushBadge forKey:@"pushBadge"];
    [results setValue:pushAlert forKey:@"pushAlert"];
    [results setValue:pushSound forKey:@"pushSound"];
    
    // Get the users Device Model, Display Name, Token & Version Number
    UIDevice *dev = [UIDevice currentDevice];
    [results setValue:dev.name forKey:@"deviceName"];
    [results setValue:dev.model forKey:@"deviceModel"];
    [results setValue:dev.systemVersion forKey:@"deviceSystemVersion"];
    
    [self successWithMessage:[NSString stringWithFormat:@"%@", deviceToken]];
#endif

}

- (void) unregisterDidFailWithError: (NSString*)error errorCode: (MCapPushError) mCapPushError
{
    [self failWithMessage:error];
}

- (void) unregisterDidSuccess
{
    [self successWithMessage:@"Unregister successful"];
}

#pragma mark -
#pragma mark Webview

-(void)successWithMessage:(NSString *)message
{
    CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:message];
    [self.commandDelegate sendPluginResult:commandResult callbackId:self.callbackId];
}

-(void)failWithMessage:(NSString *)message
{
    CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:message];
    [self.commandDelegate sendPluginResult:commandResult callbackId:self.callbackId];
}

#pragma mark -

- (void)notificationReceived {
    NSLog(@"Notification received");
    
    if (notificationMessage && self.callback)
    {
        NSMutableString *jsonStr = [NSMutableString stringWithString:@"{"];
        
        [self parseDictionary:notificationMessage intoJSON:jsonStr];
        
        if (isInline)
        {
            [jsonStr appendFormat:@"foreground:\"%d\"", 1];
            isInline = NO;
        }
		else
            [jsonStr appendFormat:@"foreground:\"%d\"", 0];
        
        [jsonStr appendString:@"}"];
        
        NSLog(@"Msg: %@", jsonStr);
        
        NSString * jsCallBack = [NSString stringWithFormat:@"%@(%@);", self.callback, jsonStr];
        [self.webView stringByEvaluatingJavaScriptFromString:jsCallBack];
        
        self.notificationMessage = nil;
    }
}

-(void)parseDictionary:(NSDictionary *)inDictionary intoJSON:(NSMutableString *)jsonString
{
    NSArray         *keys = [inDictionary allKeys];
    NSString        *key;
    
    for (key in keys)
    {
        id thisObject = [inDictionary objectForKey:key];
        
        if ([thisObject isKindOfClass:[NSDictionary class]])
            [self parseDictionary:thisObject intoJSON:jsonString];
        else if ([thisObject isKindOfClass:[NSString class]])
            [jsonString appendFormat:@"\"%@\":\"%@\",",
             key,
             [[[[inDictionary objectForKey:key]
                stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"]
               stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""]
              stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"]];
        else {
            [jsonString appendFormat:@"\"%@\":\"%@\",", key, [inDictionary objectForKey:key]];
        }
    }
}

@end