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
#import "NumberLine.h"
#import "BLMath.h"

static void
eachShape(void *ptr, void* unused)
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
        
        [self listProblemFiles];
        
        [self setupBkgAndTitle];
        
        [self setupAudio];
        
        [self setupSprites];
        
        [self setupChSpace];
        
        [self setupGW];
        
        //psuedo placeholder -- this is where we break into logical model representation
        [self populateGW];
        
        //general go-oriented render, etc
        [gameWorld handleMessage:kDWsetupStuff andPayload:nil withLogLevel:0];
        
        [self schedule:@selector(doUpdate:) interval:1.0f/60.0f];

    }
    
    return self;
}

-(void) resetToNextProblem
{
    //tear down
    [gameWorld release];
    
    [self removeAllChildrenWithCleanup:YES];
    
    cpSpaceDestroy(space);
    
    currentProblemIndex++;
    if(currentProblemIndex>=[problemFiles count])
        currentProblemIndex=0;
    
    
    //set up
    [self setupBkgAndTitle];
    
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
    
    
    CCLabelTTF *title=[CCLabelTTF labelWithString:@"Floating Blocks" fontName:TITLE_FONT fontSize:TITLE_SIZE];
    
    [title setColor:TITLE_COLOR3];
    [title setOpacity:TITLE_OPACITY];
    [title setPosition:ccp(cx, cy - (0.75f*cy))];
    
    [self addChild:title];
    
    
    CCSprite *btnFwd=[CCSprite spriteWithFile:@"btn-fwd.png"];
    [btnFwd setPosition:ccp(1024-18-10, 768-28-5)];
    [self addChild:btnFwd z:2];
    
}

-(void)setupChSpace
{
    CGSize wins = [[CCDirector sharedDirector] winSize];
    cpInitChipmunk();
    
    cpBody *staticBody = cpBodyNew(INFINITY, INFINITY);
    space = cpSpaceNew();
    cpSpaceResizeStaticHash(space, 400.0f, 400);
    cpSpaceResizeActiveHash(space, 100, 600);
    
    //space->gravity = ccp(9.8*30, 0.0f);
    space->gravity=ccp(0, 500);
    //space->damping=5.0f;
    
    space->elasticIterations = space->iterations;
    
    cpShape *shape;
    
    // bottom
    //shape = cpSegmentShapeNew(staticBody, ccp(0,-200), ccp(wins.width,0), 0.0f);
    CGPoint bottomverts[]={ccp(0, -200), ccp(0, 0), ccp(wins.width, 0), ccp(wins.width, -200)};
    shape=cpPolyShapeNew(staticBody, 4, bottomverts, ccp(0,0));
    shape->e = 1.0f; shape->u = 1.0f;
    cpSpaceAddStaticShape(space, shape);
    
    // top
    //shape = cpSegmentShapeNew(staticBody, ccp(0,wins.height-130), ccp(wins.width,wins.height-130), 0.0f);
    CGPoint topverts[]={ccp(0, wins.height-130), ccp(0, wins.height+200), ccp(wins.width, wins.height+200), ccp(wins.width, wins.height-130)};
    shape=cpPolyShapeNew(staticBody, 4, topverts, ccp(0, 0));
    shape->e = 0.65f; shape->u = 1.0f;
    cpSpaceAddStaticShape(space, shape);
    
    // left
    //shape = cpSegmentShapeNew(staticBody, ccp(0,0), ccp(0,wins.height), 0.0f);
    CGPoint leftverts[]={ccp(-200, 0), ccp(-200, wins.height), ccp(0, wins.height), ccp(0, 0)};
    shape=cpPolyShapeNew(staticBody, 4, leftverts, ccp(0,0));
    shape->e = 1.0f; shape->u = 1.0f;
    cpSpaceAddStaticShape(space, shape);
    
    // right
    //shape = cpSegmentShapeNew(staticBody, ccp(wins.width,0), ccp(wins.width+200,wins.height), 0.0f);
//    shape=cpSegmentShapeNew(staticBody, ccp(800, 0), ccp(1224, 768), 0.0f);
//    shape->e = 1.0f; shape->u = 1.0f;
//    cpSpaceAddStaticShape(space, shape);
    
//    cpBody *staticBodyRight = cpBodyNew(INFINITY, INFINITY);
    CGPoint rverts[]={ccp(1024,0), ccp(1024, 768), ccp(1200, 768), ccp(1200, 0)};
    cpShape *right=cpPolyShapeNew(staticBody, 4, rverts, ccp(0,0));
    
    //cpShape *right=cpSegmentShapeNew(staticBody, ccp(1024,0), ccp(1024,768), 0.0f);
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
    
    //fixed handlers for menu interaction
    if(location.x>975 && location.y>720)
    {
        [gameWorld writeLogBufferToDiskWithKey:@"BlockFloating"];
        
        [[SimpleAudioEngine sharedEngine] playEffect:@"putdown.wav"];
        [[CCDirector sharedDirector] replaceScene:[CCTransitionFadeBL transitionWithDuration:0.3f scene:[NumberLine scene]]];
    }
    
    else if (location.x<cx && location.y > 720)
    {
        [self resetToNextProblem];
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
                
                NSDictionary *pl=[NSDictionary dictionaryWithObject:m forKey:MOUNTED_OBJECT];
                [m handleMessage:kDWunsetMountedObject andPayload:pl withLogLevel:0];
            }

            [[SimpleAudioEngine sharedEngine] playEffect:@"pickup.wav"];
            
            //NSLog(@"got a pickup object");
            [[gameWorld Blackboard].PickupObject logInfo:@"this object was picked up" withData:0];
            
        }
    }
}


-(void) ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
	CGPoint location=[touch locationInView: [touch view]];
	location=[[CCDirector sharedDirector] convertToGL:location];
    
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
	
    if([gameWorld Blackboard].PickupObject!=nil)
    {
        [gameWorld Blackboard].DropObject=nil;
        
        //forcibly mod location by pickup offset
        
        CGPoint modLocation=[BLMath SubtractVector:[gameWorld Blackboard].PickupOffset from:location];
        
        //mod y down below water line
        //tofu hard-coded water line at effective -130 from top
        //tofy this is on touch end lcoaiton -- will need to change for different shape size        
        if(modLocation.y>637)modLocation.y=580;
        
        //check l/r bounds
        if(modLocation.x<1)modLocation.x=24;
        if(modLocation.x>1023)modLocation.x=1000;
        
        if(modLocation.y<1)modLocation.y=1;
        
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
            
            //NSLog(@"mounted float object (presumably) on a drop target");
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
	
    //render problem label
    problemDescLabel=[CCLabelTTF labelWithString:[pdef objectForKey:PROBLEM_DESCRIPTION] fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
    [problemDescLabel setPosition:ccp(cx, cy+(0.85*cy))];
    [problemDescLabel setColor:ccc3(255, 255, 255)];
    [self addChild:problemDescLabel];
    
    //create problem file name
    CCLabelBMFont *flabel=[CCLabelBMFont labelWithString:[problemFiles objectAtIndex:currentProblemIndex] fntFile:@"visgrad1.fnt"];
    [flabel setPosition:ccp(135, 755)];
    [flabel setOpacity:65];
    [self addChild:flabel];
    
    //objects
    NSDictionary *objects=[pdef objectForKey:INIT_OBJECTS];
    for (NSDictionary *o in objects) {
        [self createObjectWithCols:[[o objectForKey:DIMENSION_COLS] intValue] andRows:[[o objectForKey:DIMENSION_ROWS] intValue] andTag:[o objectForKey:TAG]];
    }
    
    //containers
    NSArray *containers=[pdef objectForKey:INIT_CONTAINERS];
    int containerCount=[containers count];
    
    //very basic layout implementation -- distributed space
    float cleftIncr=(cx*2)/(containerCount+1);
    
    for (int i=0; i<containerCount; i++)
    {
        CGPoint p=ccp((i+1)*cleftIncr, (0.625*cy));
        
        [self createContainerWithPos:p andData:[containers objectAtIndex:0]];
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
    float x=arc4random()%800 + 100;
    float y=arc4random()%400;
    
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
}

-(void)populateGWHard
{
    
    for (int i=0; i<10; i++)
    {
        DWGameObject *go=[gameWorld addGameObjectWithTemplate:@"TfloatObject"];
        
        [[go store] setObject:[NSNumber numberWithInt:(arc4random()%3)+1] forKey:OBJ_ROWS];
        [[go store] setObject:[NSNumber numberWithInt:(arc4random()%3)+1] forKey:OBJ_COLS];
        
        
        float x=arc4random()%800 + 100;
        float y=arc4random()%400;
        
        NSDictionary *ppl=[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSNumber numberWithFloat:x], [NSNumber numberWithFloat:y], nil] forKeys:[NSArray arrayWithObjects:POS_X, POS_Y, nil]];
        [self attachBodyToGO:go atPositionPayload:ppl];        
    }
    
    //create a 2 test containers
    DWGameObject *m2=[gameWorld addGameObjectWithTemplate:@"TfloatContainer"];
    [[m2 store] setObject:[NSNumber numberWithFloat:418.0f] forKey:POS_X];
    [[m2 store] setObject:[NSNumber numberWithFloat:183.0f] forKey:POS_Y];
    
    DWGameObject *m3=[gameWorld addGameObjectWithTemplate:@"TfloatContainer"];
    [[m3 store] setObject:[NSNumber numberWithFloat:606.0f] forKey:POS_X];
    [[m3 store] setObject:[NSNumber numberWithFloat:183.0f] forKey:POS_Y];
}

-(void)attachBodyToGO:(DWGameObject *)attachGO atPositionPayload:(NSDictionary *)positionPayload
{
    float x, y;
    x=[[positionPayload objectForKey:POS_X] floatValue];
    y=[[positionPayload objectForKey:POS_Y] floatValue];
    
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

//    CGPoint verts[] = {
//		ccp(-40,-40), //bottom left
//		ccp(-40, 40), //top left
//		ccp( 40, 40),
//		ccp( 40,-40),
//	};
    
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
    
    //now update gameworld (pos updates will happen in above &eachShape)
    [gameWorld doUpdate:delta];
}


-(void)dealloc
{
    cpSpaceFree(space);
	space = NULL;
    
    [gameWorld release];
    
    [problemFiles release];
    
    [super dealloc];
}

@end
