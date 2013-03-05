//
//  TimesTableMenu.m
//  belugapad
//
//  Created by David Amphlett on 22/02/2013.
//
//

#import "TimesTableMenu.h"
#import "global.h"

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
    sceneButtonPositions=[[NSMutableArray alloc]init];
    
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
    lastZIndex=original.zOrder;
    
    [original setZOrder:100];
    
    CCMoveTo *mtc=[CCMoveTo actionWithDuration:1.00f position:ccp(cx,cy)];
    CCEaseInOut *ea=[CCEaseInOut actionWithAction:mtc rate:2.0f];
    [original runAction:ea];
}

-(void)checkForHitAt:(CGPoint)location
{
    for(int i=0;i<[sceneButtons count];i++)
    {
        CCSprite *s=[sceneButtons objectAtIndex:i];
        if(CGRectContainsPoint(s.boundingBox, location))
        {
            [self createBigNumberOf:i];
            break;
        }
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
