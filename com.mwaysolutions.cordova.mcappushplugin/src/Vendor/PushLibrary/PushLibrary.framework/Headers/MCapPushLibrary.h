//
//  MCapPushLibrary.h
//  PushLibrary
//
//  Created by Marcus Koehler on 07.11.13.
//  Copyright (c) 2013 M-Way Solutions GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    MCapPushError_ServerNotReachable=1,
	MCapPushError_NoInternetConnection=2,
    MCapPushError_NoApiKey=3,
    MCapPushError_Unknown=4
} MCapPushError;

@protocol MCapPushDelegate
- (void) deviceTokenRegisterDidFailWithError: (NSString*)error errorCode: (MCapPushError) mCapPushError;
- (void) deviceTokenRegisterDidSuccess: (NSString*) deviceToken;

- (void) unregisterDidFailWithError: (NSString*)error errorCode: (MCapPushError) mCapPushError;
- (void) unregisterDidSuccess;

- (void) updateDeviceDidFailWithError: (NSString*)error errorCode: (MCapPushError) mCapPushError;
- (void) updateDeviceDidSuccess;
@end

@interface MCapPushLibrary : NSObject
{
    bool showLibVersion;
    NSString *apiKey;
    
    NSString *user;
    
    UIRemoteNotificationType remoteNotificationTypes;
    
    NSMutableDictionary *attributes;
    NSMutableArray *tags;
    
    NSString *language;
    NSString *country;
    
    int badgeCount;
    
    id <MCapPushDelegate> delegate;
    
    NSString* apnToken;
    NSString* deviceUuid;
    NSString *baseURL;
    NSString *type;
    
    NSOperationQueue *operationQueue;
}

/* ############# PROPERTIES ############# */

//Default: standard set, Please set the baseURL
@property (nonatomic,copy)     NSString *baseURL;

//Default: Not set, Please set the apiKey
@property (nonatomic,copy)     NSString *apiKey;

//Default: Not set, Please set a user name
@property (nonatomic,copy)     NSString *user;

//Default: YES
@property (nonatomic, assign)   bool showLibVersion;

//Default: UIRemoteNotificationTypeSound, UIRemoteNotificationTypeAlert, UIRemoteNotificationTypeBadge
@property (nonatomic, assign)   UIRemoteNotificationType remoteNotificationTypes;

//Default: nil, set a Dictionary with attributes
@property (nonatomic, retain)    NSDictionary *attributes;

- (void) setAttribute: (NSString*) attribute forKey: (NSString*) key;
- (void) removeAttributeForKey: (NSString*) key;

//Default: nil, set a Array with tags
@property (nonatomic, retain)    NSArray *tags;

- (void) addTag: (NSString*) tag;
- (void) removeTag: (NSString*) tag;

//Default: current language of the device
@property (nonatomic, copy) NSString *language;

//Default: current language of the device
@property (nonatomic, copy) NSString *country;

//Default: 0, the count of the red badge
@property (nonatomic, assign)   int badgeCount;

+ (MCapPushLibrary*)sharedInstance;

- (void)initializeWithDelegate: (id<MCapPushDelegate>) _delegate;

- (void) registerForRemoteNotifications;
- (void) registerDeviceToken: (NSData*) deviceToken;
- (void) unregister;
- (void) updateDevice;
- (void) sendPushWithMessage: (NSString*) message ignoreLocalApnToken: (bool) ignore;

@property (nonatomic,readonly) NSString* libraryVersion;
@property (nonatomic,readonly) NSString* libraryBuildDate;
@property (nonatomic, readonly)	NSString* apnToken;
@property (nonatomic, readonly)	NSString* deviceUuid;

@end
