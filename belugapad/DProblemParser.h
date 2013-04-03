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
    
    NSMutableDictionary *dStrings;
    NSMutableDictionary *retainedStrings;
    
    NSMutableDictionary *randomKeyCaches;
}


-(void)startNewProblemWithPDef:(NSDictionary*)pdef;
-(NSString*)parseStringFromString:(NSString*)input;
-(int)parseIntFromString:(NSString*)input;
-(float)parseFloatFromString:(NSString*)input;

-(NSNumber*)simpleDvarLookupForKey:(NSString*)key;

-(NSString *)parseStringFromValueWithKey: (NSString*)key inDef:(NSDictionary*)pdef;
-(int)parseIntFromValueWithKey: (NSString *)key inDef:(NSDictionary*) pdef;
-(float)parseFloatFromValueWithKey: (NSString *)key inDef:(NSDictionary*) pdef;

-(NSMutableDictionary*) createStaticPdefFromPdef:(NSDictionary*)dpdef;

-(void)setVarBoundsForKey:(NSString *)key withMin:(float)min andMax:(float)max;
-(void)setVarValueForKey:(NSString*)key toValue:(float)val;

@end
