//
//  TTAppUState.m
//  belugapad
//
//  Created by gareth on 03/04/2013.
//
//

#import "TTAppUState.h"
#import "global.h"
#import "AppDelegate.h"

#define TTAPP_Q_COUNT 15

@implementation TTAppUState

-(TTAppUState*)init
{
    if(self=[super init])
    {
        ac=(AppController*)[[UIApplication sharedApplication] delegate];
        
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
        
        //retain current udata as previous udata until told to purge
        prevUdata=[[NSDictionary dictionaryWithDictionary:udata] retain];
    }
    
    return self;
}

-(void)progressUpdated
{
    if(persistSaves)
    {
        [udata writeToFile:persistPath atomically:YES];
    }
    
//    NSLog(@"udata: %@", udata);
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



-(void)purgePreviousState
{
    [prevUdata release];
    prevUdata=[[NSDictionary dictionaryWithDictionary:udata] retain];
}

-(NSString*) getPreviousMedalForX:(int)x andY:(int)y
{
    return [self getMedalForX:x andY:y withData:prevUdata];
}

-(NSString*) getMedalForX:(int)x andY:(int)y
{
    return [self getMedalForX:x andY:y withData:udata];
}

-(NSString*) getMedalForX:(int)x andY:(int)y withData:(NSDictionary*)data
{
    NSString *xlkp=[NSString stringWithFormat:@"%d", x];
    NSString *ylkp=[NSString stringWithFormat:@"%d", y];
    
    //find the x category
    NSDictionary *xdict=[data objectForKey:xlkp];
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

-(float) getScoreForX:(int)x
{
    float tot=0;
    for(int i=1; i<13; i++)
    {
        tot+=[self getScoreForX:x andY:i];
    }
    return tot/12.0f;
}

-(float) getScoreForX:(int)x andY:(int)y
{
    NSString *medal=[self getMedalForX:x andY:y];
    if([medal isEqualToString:@"gold"]) return 100.0f;
    else if([medal isEqualToString:@"silver"]) return 50.0f;
    else if([medal isEqualToString:@"bronze"]) return 25.0f;
    else return 0;
}

-(void)setupPipelineFor:(int)pforIndex
{
    NSMutableArray *pipe=[[NSMutableArray alloc] init];
    
    if(pforIndex<12)
    {
        //populate with index-selected questions
        NSString *mps=[NSString stringWithFormat:@"/Problems/timestable/flat/%d/", pforIndex+1];
        NSString *dirp=BUNDLE_FULL_PATH(mps);
        NSArray *files=[[NSFileManager defaultManager] contentsOfDirectoryAtPath: dirp error:nil];
        
        for(int i=0;i<TTAPP_Q_COUNT;i++)
        {
            int max=files.count;
            int r=arc4random()%max;
            NSString *newp=[NSString stringWithFormat:@"%@/%@", dirp, [files objectAtIndex:r]];
            [pipe addObject:newp];
        }
        
        //    [pipe addObject:[NSString stringWithFormat:@"/Problems/timestable/flat/%d/table%d-hard-1.plist", currentSelectionIndex+1, currentSelectionIndex+1]];
        //
        //    [pipe addObject:[NSString stringWithFormat:@"/Problems/timestable/flat/%d/table%d-hard-2.plist", currentSelectionIndex+1, currentSelectionIndex+1]];
        //
    }
    else if (pforIndex==12)
    {
        //populate with random questions
        for(int i=0; i<TTAPP_Q_COUNT; i++)
        {
            int rx=(arc4random()%12)+1;
            
            NSString *mps=[NSString stringWithFormat:@"/Problems/timestable/flat/%d/", rx];
            NSString *dirp=BUNDLE_FULL_PATH(mps);
            NSArray *files=[[NSFileManager defaultManager] contentsOfDirectoryAtPath: dirp error:nil];
            
            int max=files.count;
            int r=arc4random()%max;
            NSString *newp=[NSString stringWithFormat:@"%@/%@", dirp, [files objectAtIndex:r]];
            [pipe addObject:newp];
        }
        
    }
    else if (pforIndex==13)
    {
        //populate with challenging questions
        
    }

    [ac.contentService changeTestProblemListTo:[NSArray arrayWithArray:pipe]];
    [pipe release];
}

-(void)dealloc
{
    [udata release];
    [prevUdata release];
    [persistPath release];
    
    [super dealloc];
}

@end