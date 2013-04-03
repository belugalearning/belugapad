//
//  TTAppUState.m
//  belugapad
//
//  Created by gareth on 03/04/2013.
//
//

#import "TTAppUState.h"

@implementation TTAppUState

-(TTAppUState*)init
{
    if(self=[super init])
    {
        //init defaults
        logRollover=5;
        
        //write user progress to disk
        persistSaves=YES;
        
        //force overwrite user progress
        overwriteOnLoad=NO;
        
        //standard storage
        NSString* dpath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        persistPath = [[dpath stringByAppendingPathComponent:@"ttapp-appustate.plist"] retain];
        BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:persistPath];
        if(exists && !overwriteOnLoad)
        {
            udata=[[NSMutableDictionary dictionaryWithContentsOfFile:persistPath] retain];
        }
        else
        {
            udata=[[NSMutableDictionary alloc] init];
        }
        
        

    }
    
    return self;
}

-(void)progressUpdated
{
    if(persistSaves)
    {
        [udata writeToFile:persistPath atomically:YES];
    }
    
    NSLog(@"udata: %@", udata);
}

-(void) setLogMax:(int)logmax
{
    logRollover=logmax;
}

-(void) saveCategorisedProgress:(NSDictionary*)categoryValues withPass:(BOOL)pass
{
    //specifically look at categories x and y
    NSNumber *xval=[categoryValues valueForKey:@"x"];
    NSNumber *yval=[categoryValues valueForKey:@"y"];
    
    //look for xval category (these are expressed as keys on the root dictionary)
    NSMutableDictionary *xdict=[udata valueForKey:[xval stringValue]];
    if(xdict==nil)
    {
        xdict=[[NSMutableDictionary alloc] init];
        [udata setObject:xdict forKey:[xval stringValue]];
    }
    
    //look for yval category on this xval
    NSMutableArray *yarray=[xdict valueForKey:[yval stringValue]];
    if(yarray==nil)
    {
        yarray=[[NSMutableArray alloc] init];
        [xdict setObject:yarray forKey:[yval stringValue]];
    }
    
    //purge log if necessary, and add this progress at top of list
    if(yarray.count>=logRollover)
        [yarray removeLastObject];
    
    //build progress dict
    NSDictionary *progd=@{@"pass": [NSNumber numberWithBool:pass], @"date": [NSDate date]};
    
    //insert as first item
    [yarray insertObject:progd atIndex:0];
    
    [self progressUpdated];
    
}

-(NSString*) getPreviousMedalForX:(int)x andY:(int)y
{
    return @"empty";
}

-(void)purgePreviousState
{
    
}

-(NSString*) getMedalForX:(int)x andY:(int)y
{
    NSString *xlkp=[NSString stringWithFormat:@"%d", x];
    NSString *ylkp=[NSString stringWithFormat:@"%d", y];
    
    //find the x category
    NSDictionary *xdict=[udata objectForKey:xlkp];
    if(xdict)
    {
        //find the y array
        NSArray *yarray=[xdict objectForKey:ylkp];
        if(yarray)
        {
            //we have the x and y categories, look at progress
            int totalAnswers=0;
            int totalCorrect=0;
            
            for (NSDictionary *a in yarray) {
                totalAnswers++;
                BOOL pass=[[a objectForKey:@"pass"] boolValue];
                if(pass)totalCorrect++;
            }
            
            //gold -- 5/5
            if(totalCorrect>=5)
                return @"gold";
            else if(totalCorrect>=3)
                return @"silver";
            else if(totalCorrect>=1)
                return @"bronze";
        }
    }
    
    return @"empty";
}

-(void)dealloc
{
    [udata release];
    [persistPath release];
    
    [super dealloc];
}

@end
