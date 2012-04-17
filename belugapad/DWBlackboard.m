//
//  Blackboard.m
//
//  Created by Gareth Jenkins on 29/09/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DWBlackboard.h"


@implementation DWBlackboard

@synthesize DropObject;
@synthesize DropObjectDistance;
@synthesize PickupObject;
@synthesize ProximateObject;
@synthesize LastSelectedObject;
@synthesize SelectedObjects;
@synthesize AllStores;
@synthesize CurrentStore;
@synthesize ComponentRenderLayer;
@synthesize PickupOffset;
@synthesize hostLX;
@synthesize hostLY;
@synthesize hostCX;
@synthesize hostCY;
@synthesize inProblemSetup;
@synthesize ProblemExpression;
@synthesize ProblemVariableSubstitutions;
@synthesize FirstAnchor;
@synthesize LastAnchor;


-(id) init
{
    if((self=[super init]))
    {
    
        [self loadData];
        
    }
    
    return self;
}

-(void)loadData
{
    AllStores=[[NSMutableArray alloc] init];
    SelectedObjects=[[NSMutableArray alloc] init];
}



@end
