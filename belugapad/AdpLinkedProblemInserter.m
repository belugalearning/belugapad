//
//  AdpLinkedProblemInserter.m
//  belugapad
//
//  Created by gareth on 04/09/2012.
//
//

#import "AdpLinkedProblemInserter.h"
#import "ContentService.h"

@implementation AdpLinkedProblemInserter

-(void)buildInserts
{
    //retrieve linked problem information from pdef and insert
    
    NSArray *linked=[contentService.currentPDef objectForKey:@"LINKED_HELPER_PROBLEMS"];
    if(linked)
    {
        for(NSString *lpid in linked)
        {
            [self.viableInserts addObject:@{ @"PROBLEM_ID" : lpid}];
        }
    }
}

@end
