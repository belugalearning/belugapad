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
    if(DropObject)[DropObject release];
    if(PickupObject)[PickupObject release];
    if(ProximateObject)[ProximateObject release];
    if(LastSelectedObject)[LastSelectedObject release];
    if(CurrentStore)[CurrentStore release];
    if(ComponentRenderLayer)[ComponentRenderLayer release];
    if(MovementLayer)[MovementLayer release];
    if(ProblemExpression)[ProblemExpression release];
    if(ProblemVariableSubstitutions)[ProblemVariableSubstitutions release];
    if(FirstAnchor)[FirstAnchor release];
    if(LastAnchor)[LastAnchor release];
    if(CurrentHandle)[CurrentHandle release];
    
    [AllStores release];
    [SelectedObjects release];
    
    [super dealloc];
}

@end
