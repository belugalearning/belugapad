//
//  LogPoller.h
//  belugapad
//
//  Created by Nicholas Cartwright on 21/08/2012.
//
//

#import <Foundation/Foundation.h>
@protocol LogPolling;

@interface LogPoller : NSObject

@property (readonly) NSArray* ticksDeltas;

-(void)resetAndStartPolling;
-(void)stopPolling;
-(void)resumePolling;
-(void)registerPollee:(id<LogPolling>)pollee;
-(void)unregisterPollee:(id<LogPolling>)pollee;

@end
