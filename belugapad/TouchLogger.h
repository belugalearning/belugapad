//
//  TouchLogger.h
//  belugapad
//
//  Created by Nicholas Cartwright on 23/08/2012.
//
//

#import <Foundation/Foundation.h>

@interface TouchLogger : NSObject

-(NSSet*)flush;
-(void)logTouches:(NSSet*)touches;

@end
