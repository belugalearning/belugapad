//
//  Blackboard.m
//
//  Created by Gareth Jenkins on 29/09/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DWBlackboard.h"


@implementation DWBlackboard

@synthesize DropObject;
@synthesize PriorityDropObject;
@synthesize DropObjectDistance;
@synthesize PickupObject;
@synthesize ProximateObject;
@synthesize LastSelectedObject;
@synthesize SelectedObjects;
@synthesize AllStores;
@synthesize CurrentStore;
@synthesize ComponentRenderLayer;
@synthesize MovementLayer;
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
@synthesize CurrentHandle;
@synthesize TestTouchLocation;
@synthesize MoveTouchLocation;
@synthesize CurrentColumnValue;


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

-(void)dealloc
{
    self.DropObject=nil;
    self.PickupObject=nil;
    self.ProximateObject=nil;
    self.LastSelectedObject=nil;
    self.CurrentStore=nil;
    self.ComponentRenderLayer=nil;
    self.MovementLayer=nil;
    self.ProblemExpression=nil;
    self.ProblemVariableSubstitutions=nil;
    self.FirstAnchor=nil;
    self.LastAnchor=nil;
    self.CurrentHandle=nil;
    
    self.AllStores=nil;
    self.SelectedObjects=nil;
    
    [super dealloc];
}

@end
