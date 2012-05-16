//
//  DProblemParser.h
//  belugapad
//
//  Created by Gareth Jenkins on 13/05/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DProblemParser : NSObject
{
    NSMutableDictionary *dVars;
    NSMutableDictionary *retainedVars;
}


-(void)startNewProblemWithPDef:(NSDictionary*)pdef;
-(NSString*)parseStringFromString:(NSString*)input;
-(int)parseIntFromString:(NSString*)input;
-(float)parseFloatFromString:(NSString*)input;

-(NSString *)parseStringFromValueWithKey: (NSString*)key inDef:(NSDictionary*)pdef;
-(int)parseIntFromValueWithKey: (NSString *)key inDef:(NSDictionary*) pdef;
-(float)parseFloatFromValueWithKey: (NSString *)key inDef:(NSDictionary*) pdef;

@end
