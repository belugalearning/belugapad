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
        
        [dataGo handleMessage:kDWupdatePosFromPhys andPayload:pl];
        
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
     
        cx=[[CCDirector sharedDirector] winSize].width / 2.0f;
        cy=[[CCDirector sharedDirector] winSize].height / 2.0f;
        
        [self setupBkgAndTitle];
        
        [self setupAudio];
        
        [self setupSprites];
        
        [self setupChSpace];
        
        [self setupGW];
        
        //psuedo placeholder -- this is where we break into logical model representation
        [self populateGW];
        
        //general go-oriented render, etc
        [gameWorld handleMessage:kDWsetupStuff andPayload:nil];
        
        [self schedule:@selector(doUpdate:) interval:1.0f/60.0f];

    }
    
    return self;
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
    cpSpaceResizeStaticHash(space, 400.0f, 40);
    cpSpaceResizeActiveHash(space, 100, 600);
    
    //space->gravity = ccp(9.8*30, 0.0f);
    space->gravity=ccp(0, 500);
    //space->damping=5.0f;
    
    space->elasticIterations = space->iterations;
    
    cpShape *shape;
    
    // bottom
    shape = cpSegmentShapeNew(staticBody, ccp(0,0), ccp(wins.width,0), 0.0f);
    shape->e = 1.0f; shape->u = 1.0f;
    cpSpaceAddStaticShape(space, shape);
    
    // top
    shape = cpSegmentShapeNew(staticBody, ccp(0,wins.height-130), ccp(wins.width,wins.height-130), 0.0f);
    shape->e = 1.0f; shape->u = 1.0f;
    cpSpaceAddStaticShape(space, shape);
    
    // left
    shape = cpSegmentShapeNew(staticBody, ccp(0,0), ccp(0,wins.height), 0.0f);
    shape->e = 1.0f; shape->u = 1.0f;
    cpSpaceAddStaticShape(space, shape);
    
    // right
    shape = cpSegmentShapeNew(staticBody, ccp(wins.width,0), ccp(wins.width,wins.height), 0.0f);
    shape->e = 1.0f; shape->u = 1.0f;
    cpSpaceAddStaticShape(space, shape);
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
    
    if(location.x>975 & location.y>720)
    {
        [[SimpleAudioEngine sharedEngine] playEffect:@"putdown.wav"];
        [[CCDirector sharedDirector] replaceScene:[CCTransitionFadeBL transitionWithDuration:0.3f scene:[NumberLine scene]]];
    }
    else
    {
        
        [gameWorld Blackboard].PickupObject=nil;
        
        NSMutableDictionary *pl=[[NSMutableDictionary alloc] init];
        [pl setObject:[NSNumber numberWithFloat:location.x] forKey:POS_X];
        [pl setObject:[NSNumber numberWithFloat:location.y] forKey:POS_Y];
        
        //broadcast search for pickup object gw
        [gameWorld handleMessage:kDWareYouAPickupTarget andPayload:pl];
        
        if([gameWorld Blackboard].PickupObject!=nil)
        {
            //this is just a signal for the GO to us, pickup object is retained on the blackboard
            [[gameWorld Blackboard].PickupObject handleMessage:kDWpickedUp andPayload:nil];
            
            [[SimpleAudioEngine sharedEngine] playEffect:@"pickup.wav"];
            NSLog(@"got a pickup object");
            
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
        NSMutableDictionary *pl=[[NSMutableDictionary alloc] init];
        [pl setObject:[NSNumber numberWithFloat:location.x] forKey:POS_X];
        [pl setObject:[NSNumber numberWithFloat:location.y] forKey:POS_Y];
        
        [[gameWorld Blackboard].PickupObject handleMessage:kDWupdateSprite andPayload:pl];
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
        NSMutableDictionary *pl=[[NSMutableDictionary alloc] init];
        [pl setObject:[NSNumber numberWithFloat:location.x] forKey:POS_X];
        [pl setObject:[NSNumber numberWithFloat:location.y] forKey:POS_Y];
        
        [[gameWorld Blackboard].PickupObject handleMessage:kDWupdateSprite andPayload:pl];
        
        [[gameWorld Blackboard].PickupObject handleMessage:kDWputdown andPayload:nil];
            
        [gameWorld Blackboard].PickupObject=nil;
        
        [[SimpleAudioEngine sharedEngine] playEffect:@"putdown.wav"];
    }
    
}

-(void)populateGW
{

    
    for (int i=0; i<4; i++)
    {
        DWGameObject *go=[gameWorld addGameObjectWithTemplate:@"TfloatObject"];
        
        float x=arc4random()%800 + 100;
        float y=arc4random()%400;
        
        NSDictionary *ppl=[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSNumber numberWithFloat:x], [NSNumber numberWithFloat:y], nil] forKeys:[NSArray arrayWithObjects:POS_X, POS_Y, nil]];
        [self attachBodyToGO:go atPositionPayload:ppl];        
    }
}

-(void)attachBodyToGO:(DWGameObject *)attachGO atPositionPayload:(NSDictionary *)positionPayload
{
    float x, y;
    x=[[positionPayload objectForKey:POS_X] floatValue];
    y=[[positionPayload objectForKey:POS_Y] floatValue];
    
    //verts of all objects are 1x1 atm
    int num = 4;
	CGPoint verts[] = {
		ccp(-40,-40),
		ccp(-40, 40),
		ccp( 40, 40),
		ccp( 40,-40),
	};
	
	cpBody *body = cpBodyNew(1.0f, cpMomentForPoly(1.0f, num, verts, CGPointZero));
	
	body->p = ccp(x, y);
	cpSpaceAddBody(space, body);
	
	cpShape* shape = cpPolyShapeNew(body, num, verts, CGPointZero);
	shape->e = 0.5f; shape->u = 0.5f;
	shape->data = attachGO;
	cpSpaceAddShape(space, shape);
    
    NSDictionary *pl=[NSDictionary dictionaryWithObject:[NSValue valueWithPointer:body] forKey:PHYS_BODY];
    [attachGO handleMessage:kDWsetPhysBody andPayload:pl];
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
    
    [super dealloc];
}

@end
