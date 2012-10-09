

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

#import "GooDrawBatchNode.h"
#import "GooSingle.h"
#import "GooSingleSquare.h"
#import "WaterSingle.h"

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
        [self readySpaceToDraw];
    }
    
    return self;
}

-(void)setupSpace
{
    cSpace=[[ChipmunkSpace alloc] init];
    
    if(useGravity || useWater)
    {
        cSpace.gravity=cpv(0, -200);
    }
    else
    {
        cSpace.gravity=cpv(0,0);
        cSpace.damping=0.05;
    }
    
    [cSpace addBounds:CGRectMake(0, 0, 2*cx, (2*cy)-65) thickness:2000 elasticity:1 friction:1 layers:CP_ALL_LAYERS group:CP_NO_GROUP collisionType:nil];

    cGrab=[[ChipmunkMultiGrab alloc] initForSpace:cSpace withSmoothing:cpfpow(0.8, 60.0) withGrabForce:20000];
    
    springCollect=[[[NSMutableArray alloc] init] autorelease];
    
    drawNode=[[GooDrawBatchNode alloc] initWithSpace:cSpace];
    [self.ForeLayer addChild:drawNode];
    
}

-(void)readySpaceToDraw
{
    drawNode.springShapes=[NSArray arrayWithArray:springCollect];
    
}

- (void)testMakeNumiconSquareGoos:(NSMutableArray *)goos withRadius:(float)r
{
    GooSingleSquare *g1 =[[GooSingleSquare alloc] initWithPos:ccp(800,650) radius:r count:8 mass:1];
    GooSingleSquare *g2 =[[GooSingleSquare alloc] initWithPos:ccp(600,450) radius:r count:8 mass:1];
    GooSingleSquare *g3 =[[GooSingleSquare alloc] initWithPos:ccp(400,450) radius:r count:8 mass:1];
    
    [goos addObject:g1];
    [goos addObject:g2];
    [goos addObject:g3];
    
    [self attach:g1 to:g2 withR:r];
    [self attach:g1 to:g3 withR:r];
    [self attach:g3 to:g2 withR:r];
    
    
    GooSingleSquare *f1 =[[GooSingleSquare alloc] initWithPos:ccp(100,250) radius:r count:8 mass:1];
    GooSingleSquare *f2 =[[GooSingleSquare alloc] initWithPos:ccp(200,250) radius:r count:8 mass:1];
    GooSingleSquare *f3 =[[GooSingleSquare alloc] initWithPos:ccp(300,250) radius:r count:8 mass:1];
    GooSingleSquare *f4 =[[GooSingleSquare alloc] initWithPos:ccp(400,250) radius:r count:8 mass:1];
    GooSingleSquare *f5 =[[GooSingleSquare alloc] initWithPos:ccp(500,250) radius:r count:8 mass:1];
    
    [goos addObject:f1];
    [goos addObject:f2];
    [goos addObject:f3];
    [goos addObject:f4];
    [goos addObject:f5];
    
    [self attach:f1 to:f2 withR:r];
    [self attach:f1 to:f3 withR:r];
    
    [self attach:f2 to:f3 withR:r];
    [self attach:f2 to:f4 withR:r];
    
    [self attach:f3 to:f4 withR:r];
    [self attach:f3 to:f5 withR:r];
    
    [self attach:f4 to:f5 withR:r];
}

-(void)addTestShapes
{
//    ChipmunkBody *b=[cSpace add:[ChipmunkBody bodyWithMass:1 andMoment:cpMomentForCircle(1, 0, 50, cpvzero)]];
//    b.pos=cpv(cx+200, cy-100);
//    
//    ChipmunkShape *s=[cSpace add:[ChipmunkCircleShape circleWithBody:b radius:50 offset:cpvzero]];
//    s.friction=0.7;
//    
//    cpFloat size = 30.0;
//    
//    cpVect pentagon[5];
//    for(int i=0; i < 5; i++){
//        cpFloat angle = -2*M_PI*i/5.0;
//        pentagon[i] = cpv(size*cos(angle), size*sin(angle));
//    }
//    
//    ChipmunkBody *body = [cSpace add:[ChipmunkBody bodyWithMass:1.0 andMoment:cpMomentForPoly(1.0, 5, pentagon, cpvzero)]];
//    body.pos = cpv(100, 400);
//    
//    ChipmunkShape *shape = [cSpace add:[ChipmunkPolyShape polyWithBody:body count:5 verts:pentagon offset:cpvzero]];
//    shape.elasticity = 0.0; shape.friction = 0.4;

    NSMutableArray *goos=[[[NSMutableArray alloc] init] autorelease];
    
    if(shapeConfig==1)
    {
        [goos addObject:[[GooSingleSquare alloc] initWithPos:ccp(cx,cy) radius:50 count:8 mass:1]];
    }
    else if(shapeConfig==2)
    {
        [goos addObject:[[GooSingleSquare alloc] initWithPos:ccp(800,650) radius:50 count:8 mass:1]];
        [goos addObject:[[GooSingleSquare alloc] initWithPos:ccp(600,450) radius:50 count:8 mass:1]];
        [goos addObject:[[GooSingleSquare alloc] initWithPos:ccp(400,250) radius:50 count:8 mass:1]];
    }
    else if(shapeConfig==3)
    {
        [goos addObject:[[GooSingle alloc] initWithPos:ccp(cx+150, 650) radius:50.0f count:26 mass:1]];
        [goos addObject:[[GooSingle alloc] initWithPos:ccp(cx-160, 650) radius:50.0f count:26 mass:1]];
        [goos addObject:[[GooSingle alloc] initWithPos:ccp(cx, 650) radius:50.0f count:26 mass:1]];

        [goos addObject:[[GooSingleSquare alloc] initWithPos:ccp(800,650) radius:50 count:8 mass:1]];
        [goos addObject:[[GooSingleSquare alloc] initWithPos:ccp(600,450) radius:50 count:8 mass:1]];
        [goos addObject:[[GooSingleSquare alloc] initWithPos:ccp(400,250) radius:50 count:8 mass:1]];
    }
    
    else if(shapeConfig==4)
    {
        [self testMakeNumiconSquareGoos:goos withRadius:50];
    }
    
    else if(shapeConfig==6)
    {
        [self testMakeNumiconSquareGoos:goos withRadius:24];
    }
    
    else if(shapeConfig==5)
    {
        GooSingle *g1 =[[GooSingle alloc] initWithPos:ccp(800,650) radius:30 count:20 mass:1];
        GooSingle *g2 =[[GooSingle alloc] initWithPos:ccp(600,450) radius:30 count:20 mass:1];
        GooSingle *g3 =[[GooSingle alloc] initWithPos:ccp(400,450) radius:30 count:20 mass:1];
        
        [goos addObject:g1];
        [goos addObject:g2];
        [goos addObject:g3];
        
        [self attachTight:g1 to:g2];
        [self attachTight:g1 to:g3];
        [self attachTight:g3 to:g2];
        
        
        GooSingle *f1 =[[GooSingle alloc] initWithPos:ccp(100,250) radius:30 count:20 mass:1];
        GooSingle *f2 =[[GooSingle alloc] initWithPos:ccp(200,200) radius:30 count:20 mass:1];
        GooSingle *f3 =[[GooSingle alloc] initWithPos:ccp(300,250) radius:30 count:20 mass:1];
        GooSingle *f4 =[[GooSingle alloc] initWithPos:ccp(400,200) radius:30 count:20 mass:1];
        GooSingle *f5 =[[GooSingle alloc] initWithPos:ccp(500,250) radius:30 count:20 mass:1];
        
        [goos addObject:f1];
        [goos addObject:f2];
        [goos addObject:f3];
        [goos addObject:f4];
        [goos addObject:f5];
        
        [self attachTight:f1 to:f2];
        [self attachTight:f1 to:f3];
        
        [self attachTight:f2 to:f3];
        [self attachTight:f2 to:f4];
        
        [self attachTight:f3 to:f4];
        [self attachTight:f3 to:f5];
        
        [self attachTight:f4 to:f5];
    }

    for(GooSingle *gs in goos)
    {
        [cSpace add:gs];
    }
    

    if(useWater)
    {
        
        //water goo
        float xc=0, yc=0;
        
        for(int i=0; i<200; i++)
        {
            xc+=50;
            if(xc>1000)
            {
                xc=0;
                yc+=50;
            }
            
            float r=10 + (arc4random()%15);
            
            WaterSingle *wg=[[WaterSingle alloc] initWithPos:ccp(xc, yc) radius:r count:5 mass:1];
            [cSpace add:wg];
            
            if(renderWater) [goos addObject:wg];
            
        }
    }
    

    drawNode.gooShapes=[NSArray arrayWithArray:goos];

    
//    cpVect verts[3];
//    verts[0]=CGPointMake(100,100);
//    verts[1]=CGPointMake(120, 100);
//    verts[2]=CGPointMake(120, 80);
//    
//    ChipmunkBody *bpoly=[cSpace add:[ChipmunkBody bodyWithMass:1 andMoment:cpMomentForPoly(1, 3, &verts[0], cpvzero)]];
//    ChipmunkShape *spoly=[cSpace add:[ChipmunkPolyShape polyWithBody:bpoly count:3 verts:&verts[0] offset:cpvzero]];
//    spoly.friction=0.7;
    
}



-(void)attach:(id<GooBody>)g1 to:(id<GooBody>)g2 withR:(float)r
{
    cpVect apos=cpvzero;
    
    [cSpace add:[ChipmunkSlideJoint slideJointWithBodyA:g1.centralBody bodyB:g2.centralBody anchr1:apos anchr2:apos min:r*2 max:r*4]];
    
    ChipmunkDampedSpring *s=[ChipmunkDampedSpring dampedSpringWithBodyA:g1.centralBody bodyB:g2.centralBody anchr1:apos anchr2:apos restLength:0 stiffness:3 damping:1];
    [cSpace add:s];
    if(renderSprings)[springCollect addObject:s];
}

-(void)attachTight:(id<GooBody>)g1 to:(id<GooBody>)g2
{
    cpVect apos=cpvzero;
    
    [cSpace add:[ChipmunkSlideJoint slideJointWithBodyA:g1.centralBody bodyB:g2.centralBody anchr1:apos anchr2:apos min:50 max:100]];
    
    [cSpace add:[ChipmunkDampedSpring dampedSpringWithBodyA:g1.centralBody bodyB:g2.centralBody anchr1:apos anchr2:apos restLength:0 stiffness:3 damping:1]];
}

-(void)doUpdateOnTick:(ccTime)delta
{
    [cSpace step:deltaP+delta];
    
//    if(updateP)
//    {
//        [cSpace step:deltaP+delta];
//        updateP=NO;
//        deltaP=0;
//    }
//    else
//    {
//        updateP=YES;
//        deltaP+=delta;
//    }
}

#pragma mark - gameworld setup and population
-(void)readPlist:(NSDictionary*)pdef
{
    shapeConfig=[[pdef objectForKey:@"SHAPE_CONFIG"] integerValue];
    
    useGravity=[[pdef objectForKey:@"GRAVITY"] boolValue];
    
    useWater=[[pdef objectForKey:@"WATER"] boolValue];
    renderWater=[[pdef objectForKey:@"RENDER_WATER"] boolValue];
    
    renderSprings=[[pdef objectForKey:@"RENDER_SPRINGS"] boolValue];
}


#pragma mark - touches events
-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    
    hasStartedGrabbing=YES;
    [cGrab beginLocation:location];
}

-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    
    if(hasStartedGrabbing)
        [cGrab updateLocation:location];
}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    
    if(hasStartedGrabbing)
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
    
    [drawNode release];
    
    [self.ForeLayer removeAllChildrenWithCleanup:YES];
    [self.BkgLayer removeAllChildrenWithCleanup:YES];
    
    [super dealloc];
}
@end
