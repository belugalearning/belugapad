

#import "GooTool.h"
#import "ToolHost.h"
#import "global.h"
#import "ToolConsts.h"
#import "DWGameWorld.h"
#import "BLMath.h"

#import "BAExpressionHeaders.h"
#import "BAExpressionTree.h"
#import "BATQuery.h"
#import "UsersService.h"
#import "AppDelegate.h"

#import "ChipmunkDebugNode.h"

@interface GooTool()
{
@private
    ContentService *contentService;
    UsersService *usersService;
}

@end

@implementation GooTool

#pragma mark - scene setup
-(id)initWithToolHost:(ToolHost *)host andProblemDef:(NSDictionary *)pdef
{
    toolHost=host;
    
    if(self=[super init])
    {
        //this will force override parent setting
        //TODO: is multitouch actually required on this tool?
        [[CCDirector sharedDirector] view].multipleTouchEnabled=YES;
        
        CGSize winsize=[[CCDirector sharedDirector] winSize];
        winL=CGPointMake(winsize.width, winsize.height);
        lx=winsize.width;
        ly=winsize.height;
        cx=lx / 2.0f;
        cy=ly / 2.0f;
        
        self.BkgLayer=[[[CCLayer alloc]init] autorelease];
        self.ForeLayer=[[[CCLayer alloc]init] autorelease];
        
        [toolHost addToolBackLayer:self.BkgLayer];
        [toolHost addToolForeLayer:self.ForeLayer];
        
        AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
        contentService = ac.contentService;
        usersService = ac.usersService;
        
        [self readPlist:pdef];
        
        [self setupSpace];
        [self addTestShapes];
    }
    
    return self;
}

-(void)setupSpace
{
    cSpace=[[ChipmunkSpace alloc] init];
    cSpace.gravity=cpv(0, -200);
    [cSpace addBounds:CGRectMake(0, 0, 2*cx, 2*cy) thickness:5 elasticity:1 friction:1 layers:CP_ALL_LAYERS group:CP_NO_GROUP collisionType:nil];

    cGrab=[[ChipmunkMultiGrab alloc] initForSpace:cSpace withSmoothing:cpfpow(0.8, 60.0) withGrabForce:20000];
    
    ChipmunkDebugNode *dn=[ChipmunkDebugNode debugNodeForChipmunkSpace:cSpace];
    [self.ForeLayer addChild:dn z:10];
}

-(void)addTestShapes
{
    ChipmunkBody *b=[cSpace add:[ChipmunkBody bodyWithMass:1 andMoment:cpMomentForCircle(1, 0, 50, cpvzero)]];
    b.pos=cpv(cx, cy);
    
    ChipmunkShape *s=[cSpace add:[ChipmunkCircleShape circleWithBody:b radius:50 offset:cpvzero]];
    s.friction=0.7;
    
}

-(void)doUpdateOnTick:(ccTime)delta
{
    [cSpace step:delta];
}

#pragma mark - gameworld setup and population
-(void)readPlist:(NSDictionary*)pdef
{

}


#pragma mark - touches events
-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    
    [cGrab beginLocation:location];
}

-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    
    [cGrab updateLocation:location];
}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    
    [cGrab endLocation:location];
}

-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{

}


#pragma mark - meta question
-(float)metaQuestionTitleYLocation
{
    return kLabelTitleYOffsetHalfProp*cy;
}

-(float)metaQuestionAnswersYLocation
{
    return kMetaQuestionYOffsetPlaceValue*cy;
}

#pragma mark - dealloc
-(void) dealloc
{
    [cGrab release];
    [cSpace release];
    
    [self.ForeLayer removeAllChildrenWithCleanup:YES];
    [self.BkgLayer removeAllChildrenWithCleanup:YES];
    
    [super dealloc];
}
@end
