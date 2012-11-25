//
//  LogginService.h
//  belugapad
//
//  Created by Nicholas Cartwright on 23/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class LogPoller, TouchLogger;

@interface LoggingService : NSObject

typedef enum {
    BL_LOGGING_ENABLED,
    BL_LOGGING_DISABLED
} BL_LOGGING_SETTING;

typedef enum {
    BL_DEVICE_CONTEXT,
    BL_USER_CONTEXT,
    BL_EPISODE_CONTEXT,
    BL_PROBLEM_ATTEMPT_CONTEXT
} BL_LOGGING_CONTEXT;

typedef enum
{
    BL_SLS_REQUEST_FAIL,
    BL_SLS_INVALID_CHECKSUM,
    BL_SLS_SUCCESS
} BL_SEND_LOG_STATUS;

@property (readonly, retain) LogPoller *logPoller;
@property (readonly, retain) TouchLogger *touchLogger;
@property (readonly, retain) NSString *currentProblemAttemptID;
@property (readonly) NSString *currentBatchId;

-(id)initWithProblemAttemptLoggingSetting:(BL_LOGGING_SETTING)paLogSetting;

-(void)logEvent:(NSString*)eventType withAdditionalData:(NSObject*)additionalData;
  
-(void)sendData;

@end
