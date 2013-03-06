//
//  TimesTableMenu.m
//  belugapad
//
//  Created by David Amphlett on 22/02/2013.
//
//

#import "TimesTableMenu.h"
#import "global.h"

const float moveToCentreTime=0.2f;
const float moveBackToPositionTime=0.2f;
const float backgroundFadeInTime=0.4f;
const float backgroundFadeOutTime=0.3f;
const float outerButtonPopOutTime=0.5f;
const float outerButtonPopOutDelay=0.1f;
const float outerButtonPopInTime=0.02f;
const float outerButtonPopInDelay=0.05f;

@implementation TimesTableMenu
+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	TimesTableMenu *layer = [TimesTableMenu node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

-(id) init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super" return value
	if( (self=[super init])) {
        
        
        CGSize winsize=[[CCDirector sharedDirector] winSize];
        winL=CGPointMake(winsize.width, winsize.height);
        lx=winsize.width;
        ly=winsize.height;
        cx=lx / 2.0f;
        cy=ly / 2.0f;
        
        self.isTouchEnabled=YES;
        
        renderLayer = [[[CCLayer alloc]init]autorelease];
        [self addChild:renderLayer];
    
        [self populateMenu];
        
	}
	return self;
}


-(void)populateMenu
{
    gameState=@"SHOW_MAIN_MENU";
    sceneButtons=[[NSMutableArray alloc]init];
    currentSelectionButtons=[[NSMutableArray alloc]init];
    sceneButtonPositions=[[NSMutableArray alloc]init];
    currentSelectionIndex=-1;
    
    CCSprite *background=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/timestables/menu/menu_bg.png")];
    [background setPosition:ccp(cx,cy)];
    [renderLayer addChild:background];
    
    float xStartPos=179.0f;
    float yStartPos=593.0f;
    float xSpacing=208.0f;
    float ySpacing=165.0f;
    int colPerRow=4;
    int currentCol=0;
    int currentRow=0;
    
    // the main buttons
    
    for(int i=0;i<12;i++)
    {
        float thisXPos=xStartPos+(currentCol*xSpacing);
        float thisYPos=yStartPos-(currentRow*ySpacing);
        
        NSString *f=[NSString stringWithFormat:@"/images/timestables/menu/button_small_%d.png", i+1];
    
        CCSprite *s=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(f)];
        [s setPosition:ccp(thisXPos,thisYPos)];
        [renderLayer addChild:s];
        
        currentCol++;
        if(currentCol>colPerRow-1)
        {
            currentRow++;
            currentCol=0;
        }
        
        [sceneButtons addObject:s];
        [sceneButtonPositions addObject:[NSValue valueWithCGPoint:s.position]];
    }
    
    // the 2 bottom buttons
    for(int i=0;i<2;i++)
    {
        
        float thisXPos=xStartPos+((currentCol+1)*xSpacing);
        float thisYPos=yStartPos-(currentRow*ySpacing);
        currentCol++;
        
        NSString *name=nil;
        if(i==0)
            name=@"random";
        else if(i==1)
            name=@"challenging";
        
        NSString *f=[NSString stringWithFormat:@"/images/timestables/menu/button_small_%@.png", name];
        CCSprite *s=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(f)];
        [s setPosition:ccp(thisXPos,thisYPos)];
        [renderLayer addChild:s];
        
        [sceneButtons addObject:s];
        [sceneButtonPositions addObject:[NSValue valueWithCGPoint:s.position]];
    }
}

-(void)createBigNumberOf:(int)thisNumber
{
    gameState=@"SHOW_TABLES";
    
    CCSprite *original=[sceneButtons objectAtIndex:thisNumber];
    
    CCMoveTo *mtc=[CCMoveTo actionWithDuration:moveToCentreTime position:ccp(cx,cy)];
    CCScaleTo *st=[CCScaleTo actionWithDuration:moveToCentreTime scale:1.0f];
    
    CCEaseInOut *ea=[CCEaseInOut actionWithAction:mtc rate:2.0f];
    CCCallBlock *numbers=[CCCallBlock actionWithBlock:^{[self setupOutsideButtons];}];
    CCSequence *sq=[CCSequence actions:ea, numbers, nil];
    
    NSString *f=nil;
    
    if(thisNumber<12)
        f=[NSString stringWithFormat:@"/images/timestables/menu/button_big_%d.png", thisNumber+1];
    else if(thisNumber==12)
        f=@"/images/timestables/menu/button_big_random.png";
    else if(thisNumber==13)
        f=@"/images/timestables/menu/button_big_challenging.png";
    
    CCSprite *s=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(f)];
    [s setPosition:original.position];
    [s setScale:0.38f];
    [renderLayer addChild:s z:20];
    
    [s runAction:sq];
    [s runAction:st];
    [original runAction:[CCFadeOut actionWithDuration:0.1f]];
    
    currentSelection=s;
    currentSelectionIndex=thisNumber;
    
    for(int i=0;i<[sceneButtons count];i++)
    {
        if(i==currentSelectionIndex)continue;
        
        CCSprite *s=[sceneButtons objectAtIndex:i];
        [s runAction:[CCFadeTo actionWithDuration:backgroundFadeOutTime opacity:50]];
    }
}

-(void)returnCurrentBigNumber{
    if(currentSelection==nil)return;
    
    float remTime=outerButtonPopInTime;
    
    for(int i=0;i<[currentSelectionButtons count];i++)
    {
        CCSprite *s=[currentSelectionButtons objectAtIndex:i];
        CCMoveTo *mtc=[CCMoveTo actionWithDuration:remTime position:ccp(cx,cy)];
        CCEaseBounceOut *bo=[CCEaseBounceOut actionWithAction:mtc];
        CCCallBlock *remMe=[CCCallBlock actionWithBlock:^{[s removeFromParentAndCleanup:YES];}];
        CCSequence *thisSQ=[CCSequence actions:bo, remMe, nil];
        [s runAction:thisSQ];
        remTime+=outerButtonPopInDelay;
    }
    
    [currentSelectionButtons removeAllObjects];
    
    CCSprite *s=currentSelection;
    CCSprite *o=[sceneButtons objectAtIndex:currentSelectionIndex];
    
    CGPoint thisPos=[[sceneButtonPositions objectAtIndex:currentSelectionIndex]CGPointValue];

    CCDelayTime *dt=[CCDelayTime actionWithDuration:remTime];
    CCDelayTime *dt2=[CCDelayTime actionWithDuration:remTime];
    CCMoveTo *mtc=[CCMoveTo actionWithDuration:moveBackToPositionTime position:thisPos];
    CCScaleTo *st=[CCScaleTo actionWithDuration:moveBackToPositionTime scale:0.38f];
    
    CCCallBlock *remove=[CCCallBlock actionWithBlock:^{[s removeFromParentAndCleanup:YES];}];
    CCCallBlock *opacity=[CCCallBlock actionWithBlock:^{[o setOpacity:255];}];
    
    CCSequence *sortbiggie=[CCSequence actions:dt, mtc, remove, opacity, nil];
    CCSequence *sortbiggiescale=[CCSequence actions:dt2, st, nil];
    
    [s runAction:sortbiggie];
    [s runAction:sortbiggiescale];
    
    for(int i=0;i<[sceneButtons count];i++)
    {
        if(i==currentSelectionIndex)continue;
        
        CCSprite *s=[sceneButtons objectAtIndex:i];
        [s runAction:[CCFadeTo actionWithDuration:backgroundFadeInTime opacity:255]];
    }
    
    currentSelection=nil;
    currentSelectionIndex=-1;
    gameState=@"SHOW_MAIN_MENU";
    
}

-(void)checkForHitAt:(CGPoint)location
{
    BOOL gotHit=false;
    
    for(int i=0;i<[sceneButtons count];i++)
    {
        CCSprite *s=[sceneButtons objectAtIndex:i];
        if(CGRectContainsPoint(s.boundingBox, location) && currentSelection==nil && currentSelectionIndex!=i)
        {
            
            gotHit=YES;
            [self createBigNumberOf:i];
            break;
        }
    }
    
    if(!gotHit){
        [self returnCurrentBigNumber];
    }
}

-(NSArray*)positionsInCircleWith:(int)points and:(double)radius and:(CGPoint)centre
{
    NSMutableArray *pointPos=[[NSMutableArray alloc]init];
    
    double slice = 2 * M_PI / points;
    for (int i = 0; i < points; i++)
    {
        double angle = slice * i;
        int newX = (int)(centre.x + radius * cos(angle));
        int newY = (int)(centre.y + radius * sin(angle));
        CGPoint p = ccp(newX, newY);
        [pointPos addObject:[NSValue valueWithCGPoint:p]];
    }
    
    return (NSArray*)pointPos;
}

-(void)setupOutsideButtons
{
    NSArray *myPoints=[self positionsInCircleWith:12 and:250 and:ccp(cx,cy)];
    int currentPoint=3;
    float time=outerButtonPopOutTime;
    
    for(int i=0;i<12;i++)
    {
        NSString *type=@"bronze";
        NSString *f=[NSString stringWithFormat:@"/images/timestables/menu/coin_%@_%d.png", type, i+1];
        CCSprite *s=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(f)];
        [s setPosition:ccp(cx,cy)];
        [renderLayer addChild:s z:18];
        
        [currentSelectionButtons addObject:s];
        
        CGPoint endPoint=[[myPoints objectAtIndex:currentPoint]CGPointValue];
        
        CCMoveTo *mt=[CCMoveTo actionWithDuration:time position:endPoint];
        CCEaseBounceOut *bi=[CCEaseBounceOut actionWithAction:mt];
        
        [s runAction:bi];
        
        time+=outerButtonPopOutDelay;
        
        currentPoint--;
        
        if(currentPoint<0)
            currentPoint=11;
        
        NSLog(@"world position of sprite: %@", NSStringFromCGPoint([self convertToWorldSpace:s.position]));
    }
}

-(void)startPipelineFor:(int)thisNumber
{
    
}

-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
}

-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    
    [self checkForHitAt:location];
    
    
    
}
-(void)dealloc
{
    [sceneButtons release];
    [super dealloc];
}
@end
