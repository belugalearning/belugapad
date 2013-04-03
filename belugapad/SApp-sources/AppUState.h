//
//  AppUState.h
//  belugapad
//
//  Created by gareth on 03/04/2013.
//
//

#import <Foundation/Foundation.h>

@interface AppUState : NSObject

-(void) setLogMax:(int)logmax;
-(void) saveCategorisedProgress:(NSDictionary*)categoryValues withPass:(BOOL)pass;
-(void)purgePreviousState;

@end
