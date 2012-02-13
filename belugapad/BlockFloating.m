//
//  BlockFloating.m
//  belugapad
//
//  Created by Gareth Jenkins on 27/12/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "BlockFloating.h"
#import "global.h"
#import "SimpleAudioEngine.h"
#import "IceDiv.h"
#import "BLMath.h"
#import "Daemon.h"
#import "ToolConsts.h"

const int kBlockSpawnSpaceWidth=800;
const int kBlockSpawnSpaceHeight=400;
const float kBlockSpawnSpaceXOffset=100.0f;

const float kContainerYOffsetHalfProp=0.625f;

const CGRect kRectButtonCommit={{944, 0}, {80, 80}};

const float kWaterLineActualYOffset=637.0f;
const float kWaterLineResubmergeYOffset=580.0f;

const float kPhysWaterLineSimInverseYOffset=130.0f;

const float kPhysContainerHardLeft=1.0f;
const float kPhysContainerLeftReset=24.0f;
const float kPhysContainerHardRight=1023.0f;
const float kPhysContainerRightReset=1000.0f;
const float kPhysContainerHardBottom=1.0f;
const float kPhysContainerResetBottom=1.0f;

const float kPhysContainerMargin=200.0f;

const float kPhysCPStaticDimension=400.0f;
const int kPhysCPStaticCount=400;
const float kPhysCPActiveDimension=100.0f;
const int kPhysCPActiveCount=600;

const CGPoint kPhysGravityDefault={0, 500};
const float kPhysWaterLineElastcity=0.65f;

const float kScheduleEvalLoopTFPS=6.0f;

const CGPoint kDaemonRest={50, 50};

const float kTimeToAutoMove=1.0f;

static void eachShape(void *ptr, void* unused)
{
	cpShape *shape = (cpShape*) ptr;
	//CCSprite *sprite = shape->data;
    DWGameObject *dataGo=shape->data;
    
	if( dataGo ) {
		cpBody *body = shape->body;

        //data is the go -- send it update pos messages
        NSNumber *degRot=[NSNumber numberWithFloat:(float)CC_RADIANS_TO_DEGREES(-body->a)];
        
        NSDictionary *pl=[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSNumber numberWithFloat:body->p.x], [NSNumber numberWithFloat:body->p.y], degRot, nil] forKeys:[NSArray arrayWithObjects:POS_X, POS_Y, ROT, nil]];
        
		//[sprite setPosition: body->p];
        
        [dataGo handleMessage:kDWupdatePosFromPhys andPayload:pl withLogLevel:-1];
        
		//[sprite setRotation: (float) CC_RADIANS_TO_DEGREES( -body->a )];
	}
}

@implementation BlockFloating

+(CCScene *) scene
{
    CCScene *scene=[CCScene node];
    
    BlockFloating *layer=[BlockFloating node];
    
    [scene addChild:layer];
    
    return scene;
}

-(id) init
{
    if(self=[super init])
    {
        self.isTouchEnabled=YES;
        
        [[CCDirector sharedDirector] openGLView].multipleTouchEnabled=NO;
     
        cx=[[CCDirector sharedDirector] winSize].width / 2.0f;
        cy=[[CCDirector sharedDirector] winSize].height / 2.0f;
        
        problemIsCurrentlySolved=NO;
        
        [self listProblemFiles];
        
        [self setupBkgAndTitle];
        
        //setup daemon
        daemon=[[Daemon alloc] initWithLayer:self andRestingPostion:kDaemonRest];
        
        [self setupAudio];
        
        [self setupSprites];
        
        [self setupChSpace];
        
        [self setupGW];
        
        //psuedo placeholder -- this is where we break into logical model representation
        [self populateGW];
        
        //general go-oriented render, etc
        [gameWorld handleMessage:kDWsetupStuff andPayload:nil withLogLevel:0];
        
        [self schedule:@selector(doUpdate:) interval:1.0f/kScheduleUpdateLoopTFPS];
        
        [self schedule:@selector(evalCompletionOnTimer:) interval:1.0f/kScheduleEvalLoopTFPS];
        
        timeToNextTutorial=TUTORIAL_TIME_START;
        [self schedule:@selector(updateTutorials:) interval:1.0f];

    }
    
    return self;
}

-(void) resetToNextProblem
{
    //write log on problem switch
    [gameWorld writeLogBufferToDiskWithKey:@"BlockFloating"];
    
    //tear down
    [gameWorld release];
    
    [daemon release];
    
    [self removeAllChildrenWithCleanup:YES];
    
    cpSpaceDestroy(space);
    
    currentProblemIndex++;
    if(currentProblemIndex>=[problemFiles count])
        currentProblemIndex=0;
    
    [solutionsDef release];
    solutionsDef=nil;
    
    
    //set up
    [self setupBkgAndTitle];
    
    daemon=[[Daemon alloc] initWithLayer:self andRestingPostion:kDaemonRest];
    
    [self setupChSpace];
    
    [self setupGW];
    
    [self populateGW];
    
    [gameWorld handleMessage:kDWsetupStuff andPayload:nil withLogLevel:0];
}

-(void)listProblemFiles
{
    currentProblemIndex=0;
    
    NSString *broot=[[NSBundle mainBundle] bundlePath];
    NSArray *allFiles=[[NSFileManager defaultManager] contentsOfDirectoryAtPath:broot error:nil];
    problemFiles=[allFiles filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self BEGINSWITH 'float-problem'"]];
    
    [problemFiles retain];
}

-(void)setupBkgAndTitle
{
    CCSprite *bkg=[CCSprite spriteWithFile:@"bg-ipad.png"];
    [bkg setPosition:ccp(cx, cy)];
    [self addChild:bkg z:0];
    
    CCSprite *fg=[CCSprite spriteWithFile:@"fg-ipad-float.png"];
    [fg setPosition:ccp(cx, cy)];
    [self addChild:fg z:2];
    
    problemCompleteLabel=[CCLabelTTF labelWithString:@"" fontName:TITLE_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
    [problemCompleteLabel setColor:kLabelCompleteColor];
    [problemCompleteLabel setPosition:ccp(cx, cy*kLabelCompleteYOffsetHalfProp)];
    [problemCompleteLabel setVisible:NO];
    [self addChild:problemCompleteLabel];
    
    CCSprite *btnFwd=[CCSprite spriteWithFile:@"btn-fwd.png"];
    [btnFwd setPosition:kButtonNextToolPos];
    [self addChild:btnFwd z:2];
    
    //setup ghost layer
    ghostLayer=[[CCLayer alloc]init];
    [self addChild:ghostLayer z:2];
}

-(void)setupChSpace
{
    CGSize wins = [[CCDirector sharedDirector] winSize];
    cpInitChipmunk();
    
    cpBody *staticBody = cpBodyNew(INFINITY, INFINITY);
    space = cpSpaceNew();
    cpSpaceResizeStaticHash(space, kPhysCPStaticDimension, kPhysCPStaticCount);
    cpSpaceResizeActiveHash(space, kPhysCPActiveDimension, kPhysCPActiveCount);
    
    space->gravity=kPhysGravityDefault;
    
    space->elasticIterations = space->iterations;
    
    cpShape *shape=nil;
    
    // bottom
    CGPoint bottomverts[]={ccp(0, -kPhysContainerMargin), ccp(0, 0), ccp(wins.width, 0), ccp(wins.width, -kPhysContainerMargin)};
    shape=cpPolyShapeNew(staticBody, 4, bottomverts, ccp(0,0));
    shape->e = 1.0f; shape->u = 1.0f;
    cpSpaceAddStaticShape(space, shape);
    
    // top
    CGPoint topverts[]={ccp(0, wins.height-kPhysWaterLineSimInverseYOffset), ccp(0, wins.height+kPhysContainerMargin), ccp(wins.width, wins.height+kPhysContainerMargin), ccp(wins.width, wins.height-kPhysWaterLineSimInverseYOffset)};
    shape=cpPolyShapeNew(staticBody, 4, topverts, ccp(0, 0));
    shape->e = kPhysWaterLineElastcity; shape->u = 1.0f;
    cpSpaceAddStaticShape(space, shape);
    
    // left
    CGPoint leftverts[]={ccp(-kPhysContainerMargin, 0), ccp(-kPhysContainerMargin, wins.height), ccp(0, wins.height), ccp(0, 0)};
    shape=cpPolyShapeNew(staticBody, 4, leftverts, ccp(0,0));
    shape->e = 1.0f; shape->u = 1.0f;
    cpSpaceAddStaticShape(space, shape);
    
    // right
    CGPoint rverts[]={ccp(cx*2,0), ccp(cx*2, cy*2), ccp((cx*2)+kPhysContainerMargin, cy*2), ccp((cx*2)+kPhysContainerMargin, 0)};
    cpShape *right=cpPolyShapeNew(staticBody, 4, rverts, ccp(0,0));
    
    right->e=1.0f;
    right->u=1.0f;
    cpSpaceAddStaticShape(space, right);
}

-(void)setupSprites
{
    
}

-(void)setupGW
{
    gameWorld=[[DWGameWorld alloc]initWithGameScene:self];
    
}



-(void)setupAudio
{
    //pre load sfx
    [[SimpleAudioEngine sharedEngine] preloadEffect:@"pickup.wav"];
    [[SimpleAudioEngine sharedEngine] preloadEffect:@"putdown.wav"];
}


-(void) ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(touching)return;
    touching=YES;
    
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    
    //set daemon mode and target
    [daemon setTarget:location];
    [daemon setMode:kDaemonModeFollowing];
    
    //fixed handlers for menu interaction
    if(location.x>kButtonNextToolHitXOffset && location.y>kButtonToolbarHitBaseYOffset)
    {
        [gameWorld writeLogBufferToDiskWithKey:@"BlockFloating"];
        
        [[SimpleAudioEngine sharedEngine] playEffect:@"putdown.wav"];
        [[CCDirector sharedDirector] replaceScene:[CCTransitionFadeBL transitionWithDuration:0.3f scene:[IceDiv scene]]];
    }
    
    else if (location.x<cx && location.y > kButtonToolbarHitBaseYOffset)
    {
        [self resetToNextProblem];
    }
    
    else if (CGRectContainsPoint(kRectButtonCommit, location))
    {
        [self evalCommit];
    }
    
    else
    {
        
        [gameWorld Blackboard].PickupObject=nil;
        
        NSMutableDictionary *pl=[[NSMutableDictionary alloc] init];
        [pl setObject:[NSNumber numberWithFloat:location.x] forKey:POS_X];
        [pl setObject:[NSNumber numberWithFloat:location.y] forKey:POS_Y];
        
        //broadcast search for pickup object gw
        [gameWorld handleMessage:kDWareYouAPickupTarget andPayload:pl withLogLevel:0];
        
        if([gameWorld Blackboard].PickupObject!=nil)
        {
            //this is just a signal for the GO to us, pickup object is retained on the blackboard
            [[gameWorld Blackboard].PickupObject handleMessage:kDWpickedUp andPayload:nil withLogLevel:0];

            //look if this object was mounted -- if so, unmount it as soon as its picked up
            DWGameObject *m=[[[gameWorld Blackboard].PickupObject store] objectForKey:MOUNT];
            if(m)
            {
                [[gameWorld Blackboard].PickupObject handleMessage:kDWunsetMount andPayload:nil withLogLevel:0];
                
                NSDictionary *pl=[NSDictionary dictionaryWithObject:[gameWorld Blackboard].PickupObject forKey:MOUNTED_OBJECT];
                [m handleMessage:kDWunsetMountedObject andPayload:pl withLogLevel:0];
            }

            [[SimpleAudioEngine sharedEngine] playEffect:@"pickup.wav"];
            
            [[gameWorld Blackboard].PickupObject logInfo:@"this object was picked up" withData:0];
            
        }
    }
}


-(void) ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
	CGPoint location=[touch locationInView: [touch view]];
	location=[[CCDirector sharedDirector] convertToGL:location];

    //daemon to move
    [daemon setTarget:location];
    
    if([gameWorld Blackboard].PickupObject!=nil)
    {
        //mod location by pickup offset
        location=[BLMath SubtractVector:[gameWorld Blackboard].PickupOffset from:location];
        
        NSMutableDictionary *pl=[[NSMutableDictionary alloc] init];
        [pl setObject:[NSNumber numberWithFloat:location.x] forKey:POS_X];
        [pl setObject:[NSNumber numberWithFloat:location.y] forKey:POS_Y];
        
        [[gameWorld Blackboard].PickupObject handleMessage:kDWupdateSprite andPayload:pl withLogLevel:-1];
    }
    
}

-(void) ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    touching=NO;
    
    UITouch *touch=[touches anyObject];
	CGPoint location=[touch locationInView: [touch view]];
	location=[[CCDirector sharedDirector] convertToGL:location];
	
    //daemon to (currently) let go and rest
    [daemon setMode:kDaemonModeWaiting];
    
    if([gameWorld Blackboard].PickupObject!=nil)
    {
        [gameWorld Blackboard].DropObject=nil;
        
        //forcibly mod location by pickup offset
        
        CGPoint modLocation=[BLMath SubtractVector:[gameWorld Blackboard].PickupOffset from:location];
        
        //mod y down below water line
        if(modLocation.y>kWaterLineActualYOffset)modLocation.y=kWaterLineResubmergeYOffset;
        
        //check l/r bounds
        if(modLocation.x<kPhysContainerHardLeft)modLocation.x=kPhysContainerLeftReset;
        if(modLocation.x>kPhysContainerHardRight)modLocation.x=kPhysContainerRightReset;
        
        if(modLocation.y<kPhysContainerHardBottom)modLocation.y=kPhysContainerResetBottom;
        
        NSMutableDictionary *pl=[[NSMutableDictionary alloc] init];
        [pl setObject:[NSNumber numberWithFloat:location.x] forKey:POS_X];
        [pl setObject:[NSNumber numberWithFloat:location.y] forKey:POS_Y];
        
        [gameWorld handleMessage:kDWareYouADropTarget andPayload:pl withLogLevel:0];
        
        if([gameWorld Blackboard].DropObject != nil)
        {
            //tell the picked-up object to mount on the dropobject
            [pl removeAllObjects];
            [pl setObject:[gameWorld Blackboard].DropObject forKey:MOUNT];
            [[gameWorld Blackboard].PickupObject handleMessage:kDWsetMount andPayload:pl withLogLevel:0];
            
            [[gameWorld Blackboard].PickupObject handleMessage:kDWputdown andPayload:nil withLogLevel:0];
            
            [pl removeAllObjects];
            [pl setObject:[gameWorld Blackboard].PickupObject forKey:MOUNTED_OBJECT];
            [[gameWorld Blackboard].DropObject handleMessage:kDWsetMountedObject andPayload:pl withLogLevel:0];
            
            [[gameWorld Blackboard].PickupObject logInfo:@"this object was mounted" withData:0];
            [[gameWorld Blackboard].DropObject logInfo:@"mounted object on this go" withData:0];

            
            [[SimpleAudioEngine sharedEngine] playEffect:@"putdown.wav"];
        }
        else
        {
            [pl setObject:[NSNumber numberWithFloat:modLocation.x] forKey:POS_X];
            [pl setObject:[NSNumber numberWithFloat:modLocation.y] forKey:POS_Y];
            
            //was dropped somewhere that wasn't a drop target
            [[gameWorld Blackboard].PickupObject handleMessage:kDWupdateSprite andPayload:pl withLogLevel:0];
            
            [[gameWorld Blackboard].PickupObject handleMessage:kDWputdown andPayload:nil withLogLevel:0];
            
            [[gameWorld Blackboard].PickupObject logInfo:@"dropped on no valid target" withData:0];
        }
            
        [gameWorld Blackboard].PickupObject=nil;
    }
    
}

-(void)populateGW
{
    NSString *broot=[[NSBundle mainBundle] bundlePath];
    NSString *pfile=[broot stringByAppendingPathComponent:[problemFiles objectAtIndex:currentProblemIndex]];
	NSDictionary *pdef=[NSDictionary dictionaryWithContentsOfFile:pfile];
	
    [gameWorld logInfo:[NSString stringWithFormat:@"started problem: %@", pfile] withData:0];

    //render problem label
    problemDescLabel=[CCLabelTTF labelWithString:[pdef objectForKey:PROBLEM_DESCRIPTION] fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
    [problemDescLabel setPosition:ccp(cx, kLabelTitleYOffsetHalfProp*cy)];
    [problemDescLabel setColor:kLabelTitleColor];

    [self addChild:problemDescLabel];
    
    //problem sub title
    NSString *subT=[pdef objectForKey:PROBLEM_SUBTITLE];
    if(!subT) subT=@"";
    problemSubLabel=[CCLabelTTF labelWithString:subT fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_SUBTITLE_FONT_SIZE];
    [problemSubLabel setPosition:ccp(cx, kLabelSubTitleYOffsetHalfProp*cy)];
    [self addChild:problemSubLabel];
    
    //create problem file name
    CCLabelBMFont *flabel=[CCLabelBMFont labelWithString:[problemFiles objectAtIndex:currentProblemIndex] fntFile:@"visgrad1.fnt"];
    [flabel setPosition:kDebugProblemLabelPos];
    [flabel setOpacity:kDebugLabelOpacity];
    [self addChild:flabel];
    
    //objects
    NSDictionary *objects=[pdef objectForKey:INIT_OBJECTS];
    [self spawnObjects:objects];
    
    //containers
    NSArray *containers=[pdef objectForKey:INIT_CONTAINERS];
    int containerCount=[containers count];
    
    //very basic layout implementation -- distributed space
    float cleftIncr=(cx*2)/(containerCount+1);
    
    for (int i=0; i<containerCount; i++)
    {
        CGPoint p=ccp((i+1)*cleftIncr, (kContainerYOffsetHalfProp*cy));
        
        [self createContainerWithPos:p andData:[containers objectAtIndex:i]];
    }
    
    //retain solutions array
    solutionsDef=[pdef objectForKey:SOLUTIONS];
    [solutionsDef retain];
    
    //get tutorials
    tutorials=[pdef objectForKey:TUTORIALS];
    if(tutorials)
    {
        doTutorials=YES;
        tutorialPos=0;
        tutorialLastParsed=-1;
        [tutorials retain];
    }

    //set additional problem-level vars
    NSNumber *rMode=[pdef objectForKey:REJECT_MODE];
    if (rMode) rejectMode=[rMode intValue];
    
    NSNumber *eMode=[pdef objectForKey:EVAL_MODE];
    if(eMode) evalMode=[eMode intValue];
 
    //any solution valid until one commenced
    trackedSolutionIndex=-1;
    trackingSolution=NO;
    
    //show commit button if evalOnCommit
    if(evalMode==kEvalOnCommit)
    {
        CCSprite *commitBtn=[CCSprite spriteWithFile:@"commit.png"];
        [commitBtn setPosition:ccp((2*cx)-50, 50)];
        [self addChild:commitBtn];
    }
}

-(void)spawnObjects:(NSDictionary*)objects
{
    for (NSDictionary *o in objects) {
        [self createObjectWithCols:[[o objectForKey:DIMENSION_COLS] intValue] andRows:[[o objectForKey:DIMENSION_ROWS] intValue] andTag:[o objectForKey:TAG]];
    }
}

-(void)createObjectWithCols:(int)cols andRows:(int)rows andTag:(NSString*)tagString
{
    //creates an object in the game world
    //ASSUMES kDWsetupStuff is sent to the object (in problem init this comes through sequential populateGW, setup)
    
    DWGameObject *go=[gameWorld addGameObjectWithTemplate:@"TfloatObject"];
    
    [[go store] setObject:[NSNumber numberWithInt:rows] forKey:OBJ_ROWS];
    [[go store] setObject:[NSNumber numberWithInt:cols] forKey:OBJ_COLS];
    
    [[go store] setObject:tagString forKey:TAG];
    
    //randomly distribute new objects in float space
    float x=arc4random()%kBlockSpawnSpaceWidth + kBlockSpawnSpaceXOffset;
    float y=arc4random()%kBlockSpawnSpaceHeight;
    
    NSDictionary *ppl=[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSNumber numberWithFloat:x], [NSNumber numberWithFloat:y], nil] forKeys:[NSArray arrayWithObjects:POS_X, POS_Y, nil]];
    [self attachBodyToGO:go atPositionPayload:ppl];
}

-(void)createContainerWithPos:(CGPoint)pos andData:(NSDictionary*)containerData
{
    //creates a container in the game world
    //ASSUMES kDWsetupStuff is sent to the object (in problem init this comes through sequential populateGW, setup)
    
    DWGameObject *c=[gameWorld addGameObjectWithTemplate:@"TfloatContainer"];
    [[c store] setObject:[NSNumber numberWithFloat:pos.x] forKey:POS_X];
    [[c store] setObject:[NSNumber numberWithFloat:pos.y] forKey:POS_Y];
    [c loadData:containerData];
    
    [gameWorld.Blackboard.AllStores addObject:c];
}

-(void)attachBodyToGO:(DWGameObject *)attachGO atPositionPayload:(NSDictionary *)positionPayload
{
    float x=[[positionPayload objectForKey:POS_X] floatValue];
    float y=[[positionPayload objectForKey:POS_Y] floatValue];
    
    //pull unit dimensions from object
    int c=[[[attachGO store] objectForKey:OBJ_COLS] intValue];
    int r=[[[attachGO store] objectForKey:OBJ_ROWS] intValue];
    
    //verts of all objects are 1x1 atm
    int num = 4;
	CGPoint verts[] = {
		ccp(-HALF_SIZE,-HALF_SIZE), //bottom left
		ccp(-HALF_SIZE, (r-1)*UNIT_SIZE + HALF_SIZE), //top left
		ccp((c-1)*UNIT_SIZE + HALF_SIZE, (r-1)*UNIT_SIZE + HALF_SIZE), //top right
		ccp((c-1)*UNIT_SIZE + HALF_SIZE, -HALF_SIZE), // bottom right
	}; 
    
	cpBody *body = cpBodyNew(1.0f, cpMomentForPoly(1.0f, num, verts, CGPointZero));
	
	body->p = ccp(x, y);
	cpSpaceAddBody(space, body);
	
	cpShape* shape = cpPolyShapeNew(body, num, verts, CGPointZero);
	shape->e = 0.5f; shape->u = 0.5f;
	shape->data = attachGO;
	cpSpaceAddShape(space, shape);
    
    NSDictionary *pl=[NSDictionary dictionaryWithObject:[NSValue valueWithPointer:body] forKey:PHYS_BODY];
    [attachGO handleMessage:kDWsetPhysBody andPayload:pl withLogLevel:0];
}

-(void)doUpdate:(ccTime)delta
{
    int steps = 2;
	CGFloat dt = delta/(CGFloat)steps;
	
	for(int i=0; i<steps; i++){
		cpSpaceStep(space, dt);
	}
	cpSpaceHashEach(space->activeShapes, &eachShape, nil);
	cpSpaceHashEach(space->staticShapes, &eachShape, nil);
    
    if(autoMoveToNextProblem)
    {
        timeToAutoMoveToNextProblem+=delta;
        if(timeToAutoMoveToNextProblem>=kTimeToAutoMove)
        {
            [self resetToNextProblem];
            autoMoveToNextProblem=NO;
        }
    }
    
    //now update gameworld (pos updates will happen in above &eachShape)
    [gameWorld doUpdate:delta];
    
    //daemon updates
    [daemon doUpdate:delta];
}

-(void)updateTutorials:(ccTime)delta
{
    if (doTutorials==NO) return;
    
    timeToNextTutorial-=delta;
    {
        if(timeToNextTutorial<0)
        {
            //get correct tutorial here and show
            NSDictionary *tdef=[tutorials objectAtIndex:tutorialPos];
            
            [self showGhostOf:[tdef objectForKey:GHOST_OBJECT] to:[tdef objectForKey:GHOST_DESTINATION]];
            
            
            //don't re-parse tutorials already shown (i.e. just do the ghosting stuff above)
            if(tutorialPos>tutorialLastParsed)
            {
                [gameWorld logInfo:[NSString stringWithFormat:@"tutorial: pre actions for phase %d", tutorialPos] withData:0];
                
                //set subtitle if there
                NSString *subt=[tdef objectForKey:PROBLEM_SUBTITLE];
                if(subt) [problemSubLabel setString:subt];
                
                //parse any PRE_ actions
                [self parseTutorialActionsFor:[tdef objectForKey:PRE_ACTIONS]];
            
                tutorialLastParsed=tutorialPos;
            }

            [gameWorld logInfo:[NSString stringWithFormat:@"showing ghost for phase %d", tutorialPos] withData:0];
            
            timeToNextTutorial=TUTORIAL_TIME_REPEAT;
        }
    }
}

-(void)doClauseActionsWithForceNow:(BOOL)forceRejectNow
{
    //step over containers and evaluate rejections
    for (DWGameObject *c in gameWorld.Blackboard.AllStores) {
        NSMutableArray *matchesSols=[[c store] objectForKey:MATCHES_IN_SOLUTIONS];
        if(!matchesSols || [matchesSols count]==0)
        {
            //no matches -- reject 
            if(rejectMode==kRejectOnAction || forceRejectNow)
            {
                [c handleMessage:kDWejectContents andPayload:nil withLogLevel:0];
            }
            
            //hook do tutorial ?
        }
        else
        {
            //this container matches some solutions
            
            //hook xp / action / tutorial
        }
    }
}

-(void)evalCommit
{
    [self evalCompletionWithForceCommit:YES];
    
    [self doClauseActionsWithForceNow:YES];
}

-(void)evalCompletionOnTimer:(ccTime)delta
{
    [self evalCompletionWithForceCommit:NO];
    
    //look at containers and rejection options, eject anything that doesn't match current solution progress, and/or trigger other actions
    [self doClauseActionsWithForceNow:NO];
}

-(void)evalCompletionWithForceCommit:(BOOL)forceCommit
{
    //evaluation implemented as delta to simulate completely abstracted (from tool implementation) evaluation
    //actual value parsing is not tool specific (just behaviour reliant -- e.g. containers, unit-based object) and would suit
    //inferred aplicability across tools -- but is currently tied to float-problem*.plist data format
    
    int solComplete=0;
    float solScore=0.0f;
    
    //purge any solution match data from containers
    [gameWorld handleMessage:kDWpurgeMatchSolutions andPayload:nil withLogLevel:0];

    for(int solIndex=0; solIndex<[solutionsDef count]; solIndex++)
    {
        NSDictionary *sol=[solutionsDef objectAtIndex:solIndex];
        
        if([self evalClauses:[sol objectForKey:CLAUSES] withSolIndex:solIndex])
        {
            solComplete=1;
            solScore=[[sol objectForKey:SOLUTION_SCORE]floatValue];
            
            [problemCompleteLabel setVisible:YES];
            
            
            if(problemIsCurrentlySolved==NO && (evalMode==kEvalAuto || forceCommit))
            {
                [self doProblemSolvedActionsFor:sol withCompletion:solComplete andScore:solScore];
                
                problemIsCurrentlySolved=YES;
            }
            
            break;
        }
    }
    
    //as this eval is abstracted from state events, need to hide solution text if the solution's been broken before progressing
    if(solComplete==0)
    {
        if(problemIsCurrentlySolved)
        {
            [problemCompleteLabel setVisible:NO];
            
            problemIsCurrentlySolved=NO;
            
            [gameWorld logInfo:@"solution broken" withData:0];
            
            //reset any tracking clauses -- user could start on a new solution
            trackedSolutionIndex=-1;
            trackingSolution=NO;
        }

    }
    
    //evaluate tutorials
    if(doTutorials)
    {
        NSDictionary *tdef=[tutorials objectAtIndex:tutorialPos];
        
        if([self evalClauses:[tdef objectForKey:CLAUSES] withSolIndex:-1])
        {
            //this tutorial has been completed
            
            //immediately remove any ghosts
            [self clearGhost];
            
            //clear problem subtitle
            [problemSubLabel setString:@""];
            
            //parse any POST_ actions
            [self parseTutorialActionsFor:[tdef objectForKey:POST_ACTIONS]];
            
            //set tutorial timer to start -- i.e. like first tutorial (not reapeat timer)
            timeToNextTutorial=TUTORIAL_TIME_START;
            
            [gameWorld logInfo:[NSString stringWithFormat:@"tutorial phase %d complete", tutorialPos] withData:0];
            
            tutorialPos++;
        }
        
        //disable tutorials once we've incremented past the last one
        if(tutorialPos>=[tutorials count])
            doTutorials=NO;
    }
    
}

-(void)doProblemSolvedActionsFor:(NSDictionary*)sol withCompletion:(int)solComplete andScore:(float)solScore
{
    
    //try and use the defined solution text
    NSString *soltext=[sol objectForKey:SOLUTION_DISPLAY_TEXT];
    
    //other wise populate with generic complete and score
    if(!soltext) soltext=[NSString stringWithFormat:@"complete (solution %d, score %f)", solComplete, solScore];
    
    NSString *playsound=[sol objectForKey:PLAY_SOUND];
    if(playsound) [[SimpleAudioEngine sharedEngine] playEffect:playsound];
    
    [problemCompleteLabel setString:soltext];
    
    [gameWorld logInfo:[NSString stringWithFormat:@"solution found with value %f and text %@", solScore, soltext] withData:0];
    
    //move to next problem
    autoMoveToNextProblem=YES;
    timeToAutoMoveToNextProblem=0.0f;
}

-(void)parseTutorialActionsFor:(NSDictionary*)actionSet
{
    //spawn any new objects
    NSDictionary *objs=[actionSet objectForKey:INIT_OBJECTS];
    if(objs) [self spawnObjects:objs];
    
    //enable any containers
    NSArray *enablec=[actionSet objectForKey:ENABLE_CONTAINERS];
    if(enablec)
    {
        for (NSString *cont in enablec) {
            DWGameObject *contgo=[gameWorld gameObjectWithKey:TAG andValue:cont];
            [[contgo store] removeObjectForKey:HIDDEN];
            [contgo handleMessage:kDWenable andPayload:nil withLogLevel:0];
        }
    }
    
    //play sound
    NSString *playsound=[actionSet objectForKey:PLAY_SOUND];
    if(playsound) [[SimpleAudioEngine sharedEngine] playEffect:playsound];
}

-(int)evalClauses:(NSDictionary*)clauses withSolIndex:(int)solIndex
{
    //returns YES if all clauses passed
    int clausesPassed=0;
   
    for (NSDictionary *clause in clauses) {
        float val1=0;
        float val2=0;
        NSString *clauseType=[clause objectForKey:CLAUSE_TYPE];
        
        BOOL valIsSize=NO;
        if([clauseType isEqualToString:SIZE_EQUAL_TO] || [clauseType isEqualToString:SIZE_GREATER_THAN] || [clauseType isEqualToString:SIZE_LESS_THAN])
            valIsSize=YES;
        
        BOOL pass=NO;
        
        //for now, evaluate contained by separately from value evaluations
        if([clauseType isEqualToString:IS_CONTAINED_BY])
        {
            DWGameObject *goc=[gameWorld gameObjectWithKey:TAG andValue:[clause objectForKey:ITEM2_CONTAINER_TAG]];
            DWGameObject *goo=[gameWorld gameObjectWithKey:TAG andValue:[clause objectForKey:ITEM1_OBJECT_TAG]];
            NSArray *gocmounteds=[[goc store] objectForKey:MOUNTED_OBJECTS];
            if([gocmounteds containsObject:goo])
            {
                pass=YES;
            }
        }
        else
        {
            //this is implemented as specific item1, item2 references to ensure left/right positioning of items whilst
            // using a non-specific data format (e.g. current plist)
            val1=[self getEvaluatedValueForItemTag:[clause objectForKey:ITEM1_CONTAINER_TAG] andItemValue:[clause objectForKey:ITEM1_VALUE] andValueRequiredIsSize:valIsSize];
            
            val2=[self getEvaluatedValueForItemTag:[clause objectForKey:ITEM2_CONTAINER_TAG] andItemValue:[clause objectForKey:ITEM2_VALUE] andValueRequiredIsSize:valIsSize];
            

            //do evaluation of val1 to val2, based on clause type
            if([clauseType isEqualToString:SIZE_EQUAL_TO] || [clauseType isEqualToString:COUNT_EQUAL_TO])
            {
                if(val1==val2)
                    pass=YES;
            }
            else if([clauseType isEqualToString:SIZE_GREATER_THAN] || [clauseType isEqualToString:COUNT_GREATER_THAN])
            {
                if(val1>val2)
                    pass=YES;
            }
            else if([clauseType isEqualToString:SIZE_LESS_THAN] || [clauseType isEqualToString:COUNT_LESS_THAN])
            {
                if(val1<val2)
                    pass=YES;
            }
        }
        
        if(pass)
        {
            //assume item1 is a container, get it from gw and get matches in sols marray
            DWGameObject *cont=[gameWorld gameObjectWithKey:TAG andValue:[clause objectForKey:ITEM1_CONTAINER_TAG]];
            NSMutableArray *matchesInSols=[[cont store]objectForKey:MATCHES_IN_SOLUTIONS];
            if(!matchesInSols)
            {
                matchesInSols=[[NSMutableArray alloc]init];                
                [[cont store] setObject:matchesInSols forKey:MATCHES_IN_SOLUTIONS];
            }
            
            //add this solution index to that array
            if(![matchesInSols containsObject:[NSNumber numberWithInt:solIndex]])
            {
                [matchesInSols addObject:[NSNumber numberWithInt:solIndex]];
            }
            
            clausesPassed++;
        }

    }
    
    if(clausesPassed>=[clauses count])
        return YES;
    else
        return NO;
}

-(float)getEvaluatedValueForItemTag: (NSString *)itemContainerTag andItemValue:(NSNumber*)itemValue andValueRequiredIsSize:(BOOL)valIsSize
{
    if(itemContainerTag)
    {
        DWGameObject *container =[gameWorld gameObjectWithKey:TAG andValue:itemContainerTag];
        if(container)
        {
            if(valIsSize)
            {
                //required value is the sum of unit size of all items contained by the specified container
                NSArray *containerObjects=[[container store] objectForKey:MOUNTED_OBJECTS];
                float contSize=0.0f;
                for (DWGameObject *o in containerObjects) {
                    float vol=[[[o store] objectForKey:OBJ_ROWS] floatValue] * [[[o store] objectForKey:OBJ_COLS] floatValue];
                    contSize+=vol;
                }
                
                return contSize;
            }
            else
            {
                //required value is the count of items contained by the specified container
                NSArray *containerMountedItems=[[container store] objectForKey:MOUNTED_OBJECTS];
                return [containerMountedItems count];
                
            }
        }
    }
    else
    {
        //assume we're using a value -- doesn't matter whether it's for size or count, it's fixed in the problem definition
        return [itemValue floatValue];
    }
    return 0.0f;
}

-(void)showGhostOf:(NSString *)ghostObjectTag to:(NSString *)ghostDestinationTag
{
    //clear any current ghosts
    [self clearGhost];
    
    //get the object
    DWGameObject *gogo=[gameWorld gameObjectWithKey:TAG andValue:ghostObjectTag];
    
    //get the destination
    DWGameObject *godest=[gameWorld gameObjectWithKey:TAG andValue:ghostDestinationTag];
    
    if(gogo && godest)
    {
        //clone the source sprite
        CCSprite *cpSource=[[gogo store] objectForKey:MY_SPRITE];
        
        CCSprite *cpGhost=[self ghostCopySprite:cpSource];
        
        [ghostLayer addChild:cpGhost];
        
        //get destination object's position
        //  container position is on go as pos_x, _y as is effective independent of sprite
        float dposx=[[[godest store] objectForKey:POS_X] floatValue];
        float dposy=[[[godest store] objectForKey:POS_Y] floatValue];
        
        //move master sprite -- children will follow
        CCDelayTime *a0=[CCDelayTime actionWithDuration:GHOST_DURATION_MOVE];
        CCMoveTo *a1=[CCMoveTo actionWithDuration:GHOST_DURATION_MOVE position:ccp(dposx, dposy)];
        CCSequence *seqMove=[CCSequence actions:a0, a1, nil];
        [cpGhost runAction:seqMove];
        
        //reset rotation by -current rotation
        CCRotateBy *r1=[CCRotateBy actionWithDuration:GHOST_DURATION_MOVE angle:20.0f];
        [cpGhost runAction:r1];
        
        
        //fade each sprite individually -- this needs the move time added to delay as actions will run in parallel
        CCDelayTime *a2=[CCDelayTime actionWithDuration:GHOST_DURATION_STAY + GHOST_DURATION_MOVE];
        CCFadeTo *a3=[CCFadeTo actionWithDuration:GHOST_DURATION_FADE opacity:0];
        CCSequence *seq=[CCSequence actions:a2, a3, nil];
        [cpGhost runAction:seq];
        
        for (CCSprite *c in [cpGhost children]) {
            //create a new sequence for each child sprite
            CCDelayTime *a2a=[CCDelayTime actionWithDuration:GHOST_DURATION_STAY + GHOST_DURATION_MOVE];
            CCFadeTo *a3a=[CCFadeTo actionWithDuration:GHOST_DURATION_FADE opacity:0];
            CCSequence *seqa=[CCSequence actions:a2a, a3a, nil];
            
            [c runAction:seqa];
        }
        
        //attach daemon to master sprite if user not already touching
        if(!touching) 
        {
            [daemon followObject:cpGhost];
            daemonIsGhosting=YES;
        }
        
    }
}

-(CCSprite *)ghostCopySprite:(CCSprite*)spriteSource
{
    CCSprite *ghost=[CCSprite spriteWithTexture:[spriteSource texture]];
    [ghost setPosition:[spriteSource position]];
    [ghost setRotation:[spriteSource rotation]];
    
    for (CCSprite *c in [spriteSource children]) {
        CCSprite *cpc=[CCSprite spriteWithTexture:[c texture]];
        
        [cpc setPosition:[c position]];
        [cpc setRotation:[c rotation]];
        
        //opacity and tint don't get set for child sprites -- so reset for each here
        [cpc setOpacity:GHOST_OPACITY];
        [cpc setColor:ccc3(0, GHOST_TINT_G, 0)];
        
        [ghost addChild:cpc];
        
    }
    
    [ghost setOpacity:GHOST_OPACITY];
    [ghost setColor:ccc3(0, GHOST_TINT_G, 0)];
    
    return ghost;
}

-(void)clearGhost
{
    if(daemonIsGhosting)
    {
        [daemon setMode:kDaemonModeResting];
        daemonIsGhosting=NO;
    }
    
    [ghostLayer removeAllChildrenWithCleanup:YES];
}

-(void)dealloc
{
    cpSpaceFree(space);
	space = NULL;
    
    [gameWorld release];
    
    [problemFiles release];
    [solutionsDef release];
    
    if(tutorials)
        [tutorials release];
    
    [super dealloc];
}

@end
