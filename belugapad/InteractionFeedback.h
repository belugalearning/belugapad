//
//  InteractionFeedback.h
//  belugapad
//
//  Created by Gareth Jenkins on 12/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CCAction;

@interface InteractionFeedback : NSObject

+(CCAction*)shakeAction;
+(CCAction*)enlargeTo1xAction;
+(CCAction*)reduceTo1xAction;
+(CCAction*)reduceTo0xAndHide;

@end
