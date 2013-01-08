//
//  AdpInserter.m
//  belugapad
//
//  Created by gareth on 03/09/2012.
//
//

#import "AdpInserter.h"
#import "AppDelegate.h"
#import "ContentService.h"
#import <objc/runtime.h>

@implementation AdpInserter

-(id)init
{
    if(self=[super init])
    {
        AppController *ac=(AppController*)[UIApplication sharedApplication].delegate;
        contentService=ac.contentService;
        adplineSettings=ac.AdplineSettings;
        
        _viableInserts=[[NSMutableArray alloc] init];
        _decisionInformation=[[NSMutableDictionary alloc] init];
    }
    return self;
}
    
-(void)buildInserts
{
    @throw [NSException exceptionWithName:@"not implemented" reason:@"buildInserts not implemented iadprn derived class" userInfo:nil];
}

-(NSString*)inserterName
{
    const char* className = class_getName([self class]);
    return [NSString stringWithFormat:@"%s", className];
}

-(void)dealloc
{
    [_viableInserts release];
    [_decisionInformation release];
    
    [super dealloc];
}

@end
