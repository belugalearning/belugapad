//
//  LogginService.h
//  belugapad
//
//  Created by Nicholas Cartwright on 23/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LoggingService : NSObject

typedef enum {
    BL_LOGGING_ENABLED,
    BL_LOGGING_DISABLED
} BL_LOGGING_SETTING;

typedef enum {
    BL_DEVICE_LOGGING_CONTEXT,
    BL_USER_SESSION_CONTEXT,
    BL_JOURNEY_MAP_CONTEXT,
    BL_PROBLEM_ATTEMPT_CONTEXT
} BL_LOGGING_CONTEXT;

typedef enum
{
    BL_SLS_REQUEST_FAIL,
    BL_SLS_INVALID_CHECKSUM,
    BL_SLS_SUCCESS
} BL_SEND_LOG_STATUS;

@property (readonly, retain) NSString *currentProblemAttemptID;

-(id)initWithProblemAttemptLoggingSetting:(BL_LOGGING_SETTING)paLogetting;

-(void)onUpdateObjectOfContext:(BL_LOGGING_CONTEXT)context;

-(void)logEvent:(NSString*)event withAdditionalData:(NSObject*)additionalData;
  
-(void)sendData;

@end
