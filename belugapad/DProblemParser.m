//
//  DProblemParser.m
//  belugapad
//
//  Created by Gareth Jenkins on 13/05/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DProblemParser.h"

@implementation DProblemParser


-(id)init
{
    dVars=[[NSMutableDictionary alloc] init];
    dStrings=[[NSMutableDictionary alloc] init];
    retainedVars=[[NSMutableDictionary alloc] init];
    retainedStrings=[[NSMutableDictionary alloc] init];
    
    return self;
}

-(void)startNewProblemWithPDef:(NSDictionary*)pdef
{
    //clear any problem variables
    [dVars removeAllObjects];
    [dStrings removeAllObjects];
    
    //parse the dvars from the new pdef
    NSDictionary *dvdef=[pdef objectForKey:@"DVARS"];
    if(dvdef) [self parseDVars:dvdef];
    
    //parse the dstrings from the new pdef
    NSDictionary *dsdef=[pdef objectForKey:@"DSTRINGS"];
    if(dsdef) [self  parseDStrings:dsdef];
}

-(void)parseDStrings:(NSDictionary*)dstringsdef
{
    for (int i=0; i<[[dstringsdef allKeys] count]; i++) {
        NSString *key=[[dstringsdef allKeys] objectAtIndex:i];
        NSDictionary *def=[dstringsdef objectForKey:key];
        NSString *mode=[def objectForKey:@"MODE"];
        NSArray *data=[def objectForKey:@"DATA"];
        NSString *val=nil;
        BOOL setString;
        
        if([def objectForKey:@"RECALL"] && [retainedStrings objectForKey:key])
        {
            NSLog(@"parsing RECALL'd DSTRING %@", key);
            
            //recall this value from retained vars
            [dStrings setObject:[retainedStrings objectForKey:key] forKey:key];
        }
        else {
            //not recalled, so look at modes for selection
            if([mode isEqualToString:@"RANDOM"])
            {
                NSLog(@"parsing dstring random %@", key);
                
                //pick random string from data
                int r=(arc4random() % [data count]);
                val=(NSString *)[data objectAtIndex:r];
                setString=YES;
            }
            if([mode isEqualToString:@"ITERATE"])
            {
                //step over the data list
            }
            
            if(setString)
            {
                [dStrings setObject:val forKey:key];
                
                NSNumber *retain=[def objectForKey:@"RETAIN"];
                if(retain)
                {
                    if([retain intValue]==0)
                    {
                        //clear any existing value and do not retain
                        [retainedStrings removeObjectForKey:key];
                        
                        NSLog(@"cleared any retained dstring for %@", key);
                    }
                    else {
                        //retain the value, overwriting any current value
                        [retainedStrings setObject:val forKey:key];
                        
                        NSLog(@"retained value of %@", key);
                    }
                }
            }
        }
        
    }
}

-(void)parseDVars:(NSDictionary*)dvarsdef
{
    for (int i=0; i<[[dvarsdef allKeys] count]; i++) {
        NSString *namebase=[[dvarsdef allKeys] objectAtIndex:i];
        
        NSLog(@"parsing %@", namebase);
        
        //the dictionary for this dvar's settings & properties
        NSDictionary *dv=[[dvarsdef allValues] objectAtIndex:i];
        
        if([namebase length]<2)
        {
            NSLog(@"string not long enough %@", namebase);
            continue;
        }
        
        NSString *name=[namebase substringFromIndex:1];
        NSString *casttype=[namebase substringToIndex:1];
        
        if(!([casttype isEqualToString:@"$"] || [casttype isEqualToString:@"%%"] || [casttype isEqualToString:@"&"]))
        {
            NSLog(@"cast type char not in $, %%, &");
            continue;
        }
        
        //output value
        NSNumber *outputvalue=[NSNumber numberWithInt:0];
        
        //raw string expressions
        NSString *valexpr=[dv objectForKey:@"VALUE"];
        NSString *recallexpr=[dv objectForKey:@"RECALL"];
        
        if(valexpr)
        {
            //create this variable by evaluating a value
            NSString *parsedval=[self parseStringFromString:valexpr];
            
            outputvalue=[self numberFromString:parsedval withCastType:casttype];
        }
        else if(recallexpr)
        {
            //create by evaluating a value, recalling retained vars where applicable
            NSString *parsedval=[self parseStringFromString:recallexpr withRecall:YES];
            outputvalue=[self numberFromString:parsedval withCastType:casttype];
        }
        else {
            //create this vairable by creating a random number
            //note: this is actually using a string output of the random NSNumber and then casting back using casttype
            outputvalue=[self numberFromString:[[self randomNumberWithParams:dv] stringValue] withCastType:casttype];
        }
        
        //add this variable to the problem dvars
        [dVars setObject:outputvalue forKey:name];
        
        NSLog(@"setting %@ to %@", namebase, [outputvalue stringValue]);
        
        //should we retain this variable?
        NSNumber *retain=[dvarsdef objectForKey:@"RETAIN"];
        if(retain)
        {
            if([retain intValue]==0)
            {
                //clear any existing value and do not retain
                [retainedVars removeObjectForKey:namebase];
                
                NSLog(@"cleared any retained value for %@", namebase);
            }
            else {
                //retain the value, overwriting any current value
                [retainedVars setObject:outputvalue forKey:namebase];
                
                NSLog(@"retained value of %@", namebase);
            }
        }
    }
    
}

-(NSNumber *)randomNumberWithParams:(NSDictionary*)params
{
    int min=[[params objectForKey:@"MIN"] floatValue];
    int max=[[params objectForKey:@"MAX"] floatValue];
    
    int interval=max-min;
    
    int fbase=arc4random() % (int)interval;
    
    int ret=fbase+min;
    
    return [NSNumber numberWithInt:ret];
}

-(NSNumber *)numberFromString:(NSString*)input withCastType:(NSString*)casttype
{
    NSNumber *outputvalue=[NSNumber numberWithInt:0];
    
    //cast that as per cast type pref on variable declation itself
    if ([casttype isEqualToString:@"$"]) {
        //return an int (there's an explicit integer cast here)
        float interf=[input floatValue];
        outputvalue=[NSNumber numberWithInt:(int)interf];
    }
    if([casttype isEqualToString:@"%%"]) {
        //return a rounded int
        float interf=[input floatValue] + (interf>0 ? 0.5 : -0.5);
        outputvalue=[NSNumber numberWithInt:(int)interf];
    }
    if([casttype isEqualToString:@"&"]) {
        //return a float
        outputvalue=[NSNumber numberWithFloat:[input floatValue]];
    }
    
    return outputvalue;
}

-(NSNumber*)numberFromVarLiteralString:(NSString*)input withLkpSource:(NSDictionary*)lkpSource
{
    //trim string
    NSString *parse=[input stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    if([parse length]==0)
    {
        NSLog(@"empty string after trim");
        return nil;
    }
    
    //is this a var (does it have a cast type at the start)
    NSString *casttype=[parse substringToIndex:1];
    if (!([casttype isEqualToString:@"$"] || [casttype isEqualToString:@"%%"] || [casttype isEqualToString:@"&"])) {
        //not a var -- no cast type
        if ([parse rangeOfString:@"."].location!=NSNotFound) {
            //presume decimal, return as float
            return [NSNumber numberWithFloat:[parse floatValue]];
        }
        else {
            //presume int, return as int
            return [NSNumber numberWithInt:[parse intValue]];
        }
    }
    else {
        //this is cast, lookup number using substring from 1
        NSString *varname=[parse substringFromIndex:1];
        NSNumber *varval=[lkpSource objectForKey:varname];
        return [self numberFromString:[varval stringValue] withCastType:casttype];
    }
    
    return nil;
}

-(NSString*)castFloat:(float)fin AsStringFromOptionsInVarLiteral: (NSString *) i1 andVarLiteral:(NSString *)i2
{
    //trim string
    NSString *parse1=[i1 stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString *parse2=[i1 stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    if([parse1 length]==0 || [parse2 length]==0)
    {
        NSLog(@"empty string after trim");
        return nil;
    }
    
    //is this a var (does it have a cast type at the start)
    NSString *ct1=[parse1 substringToIndex:1];
    NSString *ct2=[parse2 substringToIndex:1];
    
    
    if([ct1 isEqualToString:@"&"] || [ct2 isEqualToString:@"&"])
    {
        return [NSString stringWithFormat:@"%f", fin];
    }
    else if([ct1 isEqualToString:@"%%"] && [ct2 isEqualToString:@"%%"])
    {
        return [NSString stringWithFormat:@"%d", (int)(fin+0.5f)];
    }
    else {
        return [NSString stringWithFormat:@"%d", (int)fin];
    }
    
    return nil;
}

-(NSString*)parseStringFromString:(NSString *)input withRecall:(BOOL)recall
{
    if(!input)
    {
        NSLog(@"no input");
        return @"";
    }
    
    if(![input isKindOfClass:[NSString class]])
    {
        NSLog(@"input is not string");
        return @"";
    }
    
    NSMutableDictionary *lkpVars=[dVars copy];
    NSString *parse=[input copy];
    
    //if we're recalling, write into this recalled values
    if(recall)
    {
        for (int i=0; i<[[retainedVars allKeys] count]; i++) {
            //write each key/value from retaining into the lkp -- will overwrite if required
            [lkpVars setObject:[[retainedVars allValues] objectAtIndex:i] forKey:[[retainedVars allKeys] objectAtIndex:i]];
            
            NSLog(@"recalling a retained value: %@ for key %@", [[[retainedVars allValues] objectAtIndex:i] stringValue], [[[retainedVars allKeys] objectAtIndex:i] stringValue]);
        }
    }
    
    if([parse isEqualToString:@""])
    {
        NSLog(@"no string to parse");
        return parse;
    }
    
    //parse the string, looking for {...} pairs and substituting them
    //subs is replacing vars with literals from lkpvars and doing operations
    NSRange r=[parse rangeOfString:@"{"];
    while (r.location!=NSNotFound) {
        //string from {+1 to end
        NSString *rstring=[parse substringFromIndex:r.location+1];
        
        //position of closing }
        NSRange rend=[rstring rangeOfString:@"}"];
        
        //output mid string between { and }
        NSString *mid=rstring;
        if(rend.location!=NSNotFound) mid=[rstring substringToIndex:rend.location];
        
        //parse & operate on expression
        
        //get op pos
        NSRange rop=[mid rangeOfString:@"+"];
        if(rop.location==NSNotFound) rop=[mid rangeOfString:@"-"];
        if(rop.location==NSNotFound) rop=[mid rangeOfString:@"*"];
        if(rop.location==NSNotFound) rop=[mid rangeOfString:@"/"];
        if(rop.location==NSNotFound) rop=[mid rangeOfString:@"^"];
        
        NSRange replacerange={r.location, rend.location+2};
        
        if(rop.location==NSNotFound)
        {
            NSLog(@"replacing range |%@| in string |%@| with string |%@|",
                  NSStringFromRange(replacerange),
                  parse,
                  [self numberFromVarLiteralString:mid withLkpSource:lkpVars]);
            
            //presume one variable, get as literal replacement
            parse=[parse stringByReplacingCharactersInRange:replacerange withString:[[self numberFromVarLiteralString:mid withLkpSource:lkpVars] stringValue]];
            
        }
        else {
            //we have operators, get vars and operate
            NSString *lstring=[mid substringToIndex:rop.location];
            NSString *rstring=[mid substringFromIndex:rop.location+1];
            
            NSNumber *l = [self numberFromVarLiteralString:lstring withLkpSource:lkpVars];
            NSNumber *r = [self numberFromVarLiteralString:rstring withLkpSource:lkpVars];
            NSString *op = [mid substringWithRange:rop];
            
            //do operator
            float fres=0;
            
            if([op isEqualToString:@"+"]) fres=[l floatValue] + [r floatValue];
            if([op isEqualToString:@"-"]) fres=[l floatValue] - [r floatValue];
            if([op isEqualToString:@"*"]) fres=[l floatValue] * [r floatValue];
            if([op isEqualToString:@"/"]) fres=[l floatValue] / [r floatValue];
            if([op isEqualToString:@"^"]) fres=powf([l floatValue], [r floatValue]);
         
            
            NSLog(@"replacing range |%@| in string |%@| with string |%@|",
                  NSStringFromRange(replacerange),
                  parse,
                  [self castFloat:fres AsStringFromOptionsInVarLiteral:lstring andVarLiteral:rstring]);
            
            //if float
            parse=[parse stringByReplacingCharactersInRange:replacerange withString:[self castFloat:fres AsStringFromOptionsInVarLiteral:lstring andVarLiteral:rstring]];
        }
        
        //get new range to step
        r=[parse rangeOfString:@"{"];
    }
    
    
    //DSTRING replacements
    NSRange dsrange=[parse rangeOfString:@"[["];
    while (dsrange.location!=NSNotFound) {
        //string from [[ +2 to end
        NSString *rstring=[parse substringFromIndex:dsrange.location+2];
        
        //position of close
        NSRange rend=[rstring rangeOfString:@"]]"];
        
        //middle of string
        NSString *mid=rstring;
        if(rend.location!=NSNotFound) mid=[rstring substringToIndex:rend.location];
        
        //the range in the parse string that we're going to replace
        NSRange replacerange={dsrange.location, rend.location+4};
        
        NSLog(@"dstring replacing range |%@| in string |%@| with string |%@| for key |%@|",
              NSStringFromRange(replacerange),
              parse,
              [dStrings objectForKey:mid],
              mid);
        
        //do straight swap of [[$____]]  in parse
        parse=[parse stringByReplacingCharactersInRange:replacerange withString:[dStrings objectForKey:mid]];
        
        //look for next replacement
        dsrange=[parse rangeOfString:@"[["];
    }
    
    return parse;
}

-(NSString*)parseStringFromString:(NSString*)input
{
    return [self parseStringFromString:input withRecall:NO];
}

-(int)parseIntFromString:(NSString*)input
{
    return [[self parseStringFromString:input] intValue];
}

-(float)parseFloatFromString:(NSString*)input
{
    return [[self parseStringFromString:input] floatValue];
}

-(NSString *)inputStringFromValueWithKey: (NSString*)key inDef:(NSDictionary*) pdef
{
    NSString *pstring=@"";
    NSObject *val=[pdef objectForKey:key];
    if([val isKindOfClass:[NSString class]])
    {
        pstring=(NSString*)val;
    }
    else if ([val isKindOfClass:[NSNumber class]]) {
        pstring=[((NSNumber*)val) stringValue];
    }
    return pstring;
}

-(NSString *)parseStringFromValueWithKey: (NSString*)key inDef:(NSDictionary*)pdef
{
    return [self parseStringFromString:[self inputStringFromValueWithKey:key inDef:pdef]];
}

-(int)parseIntFromValueWithKey: (NSString *)key inDef:(NSDictionary*) pdef
{
    return [[self parseStringFromString:[self inputStringFromValueWithKey:key inDef:pdef]] intValue];
}

-(float)parseFloatFromValueWithKey: (NSString *)key inDef:(NSDictionary*) pdef
{
    return [[self parseStringFromString:[self inputStringFromValueWithKey:key inDef:pdef]] floatValue];
}

#pragma mark PDEF parsing and creation

-(NSMutableDictionary*) createStaticPdefFromPdef:(NSDictionary*)dpdef
{
    NSMutableDictionary *spdef=[dpdef mutableCopy];
 
    [self cstatParseKeysInDict:spdef];
    
    //remove any dynamic def/spec stuff from the static definition
    [spdef removeObjectForKey:@"DVARS"];
    [spdef removeObjectForKey:@"DSTRINGS"];
    [spdef removeObjectForKey:@"DBUILD"];
    
    return spdef;
}

-(void) cstatParseKeysInDict:(NSMutableDictionary*)dict
{
    //need local copy of keys as order may change in mutation
    NSArray *keys=[[dict allKeys] copy];

    for(int i=0; i<keys.count; i++)
    {
        NSObject *o=[dict objectForKey:[keys objectAtIndex:i]];

        if([o isKindOfClass:[NSString class]])
        {
            //a string in an array
            NSString *so=(NSString*)o;
            NSString *ps=[self cstatParseValue:so];
            if(ps!=so) [dict setValue:ps forKey:[keys objectAtIndex:i]];
        }
        
        if([o isKindOfClass:[NSNumber class]])
        {
            //a number in an array
            NSString *so=[(NSNumber*)o stringValue];
            NSString *ps=[self cstatParseValue:so];
            if(ps!=so) [dict setValue:ps forKey:[keys objectAtIndex:i]];        
        }
        
        if([o isKindOfClass:[NSMutableArray class]])
        {
            [self cstatParseKeysInArray:(NSMutableArray*)o];
        }
        if([o isKindOfClass:[NSMutableDictionary class]])
        {
            [self cstatParseKeysInDict:(NSMutableDictionary*)o];
        }

    }
    
    [keys release];
}

-(void) cstatParseKeysInArray:(NSMutableArray*)array
{
    for (int i=0; i<[array count]; i++) {
        NSObject *o=[array objectAtIndex:i];
        
        if([o isKindOfClass:[NSString class]])
        {
            //a string in an array
            NSString *so=(NSString*)o;
            NSString *ps=[self cstatParseValue:so];
            if(ps!=so) [array replaceObjectAtIndex:i withObject:ps];
        }
        
        if([o isKindOfClass:[NSNumber class]])
        {
            //a number in an array
            NSString *so=[(NSNumber*)o stringValue];
            NSString *ps=[self cstatParseValue:so];
            if(ps!=so) [array replaceObjectAtIndex:i withObject:ps];            
        }
        
        if([o isKindOfClass:[NSMutableArray class]])
        {
            [self cstatParseKeysInArray:(NSMutableArray*)o];
        }
        if([o isKindOfClass:[NSMutableDictionary class]])
        {
            [self cstatParseKeysInDict:(NSMutableDictionary*)o];
        }
    }
}

-(NSString*) cstatParseValue:(NSString*)val
{
    if([val rangeOfString:@"{"].location!=NSNotFound || [val rangeOfString:@"[["].location!=NSNotFound)
    {
        //parse the thing
        return [self parseStringFromString:val];
    }
    else {
        //return it as is
        return val;
    }
}

#pragma mark

@end