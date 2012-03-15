//
//  BAVariable.h
//  Beluga
//
//  Created by Cathy Shive on 1/25/11.
//  Copyright 2011 Heritage World Press. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BAExpression.h"

@interface BAVariable : BAExpression 
{
	NSString *			mName;
	NSInteger			mMultiplierIntValue; // deprecated
}
@property (nonatomic, readwrite, copy) NSString * name;
@property (nonatomic, readwrite, assign) NSInteger multiplierIntValue;

+(BAVariable*)variableWithName:(NSString*)theName;
@end

@interface BAVariable(BADeprecated) 
// deprecated, use `variableWithName:` instead
+(BAVariable*)variableWithName:(NSString*)theName multiplierIntValue:(NSInteger)theMultiplierInt; 
@end
