//
//  TouchLogger.h
//  belugapad
//
//  Created by Nicholas Cartwright on 23/08/2012.
//
//

#import <Foundation/Foundation.h>

@interface TouchLogger : NSObject

@property (readonly) NSSet *allTouches;

-(void)logTouches:(NSSet*)touches;
-(void)reset;

@end
