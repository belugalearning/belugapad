//
//  ProblemAttempt.h
//  belugapad
//
//  Created by Nicholas Cartwright on 20/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

@class UserSession, Problem;

@interface ProblemAttempt: NSObject

@property (readonly) NSString* _id;

-(id)initAndStartForUserSession:(UserSession*)userSession
                        problem:(Problem*)problem //parentAttemptId:(NSString*)parentAttemptId
                  generatedPDef:(NSDictionary*)pdef
           loggingDirectoryPath:(NSString*)loggingDirectoryPath;

-(void)logEvent:(NSString*)eventType withAdditionalData:(NSObject*)additionalData;

@end
