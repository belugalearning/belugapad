//
//  SGDtoolCage.m
//  belugapad
//
//  Created by David Amphlett on 13/08/2012.
//
//

#import "SGDtoolCage.h"
#import "SGDtoolBlock.h"
#import "global.h"

@implementation SGDtoolCage

@synthesize RenderLayer, Position;
@synthesize CageType, BlockType;
@synthesize InitialObjects;
@synthesize MySprite;

-(SGDtoolCage*) initWithGameWorld:(SGGameWorld*)aGameWorld atPosition:(CGPoint)thisPosition andRenderLayer:(CCLayer*)aRenderLayer andCageType:(NSString*)thisCageType
{
    if(self=[super initWithGameWorld:aGameWorld])
    {
        self.Position=thisPosition;
        self.RenderLayer=aRenderLayer;
        self.CageType=thisCageType;
    }
    return self;
}


-(void)handleMessage:(SGMessageType)messageType
{
    //re-broadcast messages to components
}

-(void)doUpdate:(ccTime)delta
{
    //update of components
    
}

-(void)draw:(int)z
{
    
}

-(void)setup
{
    if(InitialObjects==0)InitialObjects=1;
    NSString *sprFileName=nil;
    
    if(!self.CageType)
        sprFileName=@"/images/distribution/DT_Dock_Infinite.png";
    else
        sprFileName=[NSString stringWithFormat:@"/images/distribution/DT_Dock_%@.png", self.CageType];
        
    MySprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(sprFileName)];
    if(InitialObjects==1)
        [MySprite setPosition:ccp(self.Position.x,self.Position.y-45)];
    else if(InitialObjects>1&&InitialObjects<=15)
        [MySprite setPosition:ccp(self.Position.x,self.Position.y-30)];
    else
        [MySprite setPosition:self.Position];
    
    [self.RenderLayer addChild:MySprite];
}

-(void)spawnNewBlock
{
    float totalLength=MySprite.contentSize.width-(73*2);
    
    // render buttons
    float sectionW=0;
    if (InitialObjects<=15)
        sectionW=totalLength / InitialObjects;
    else
        sectionW=totalLength / 15;
    
    float startPosX=MySprite.position.x+74-(MySprite.contentSize.width/2);
    
    int posCount=0;
    for(int i=0;i<self.InitialObjects;i++)
    {
        if(posCount==15)posCount=0;
        float xPos=startPosX+(posCount+0.5) * sectionW;
        float yPos=0;
        
        if(InitialObjects==1)
            yPos=45.0f;
        else if(InitialObjects>1&&InitialObjects<=15)
            yPos=55.0f;
        else
            yPos=107-((i/(int)15)*50);
        
        id<Configurable,Selectable,Pairable,Moveable> newblock;
        newblock=[[[SGDtoolBlock alloc] initWithGameWorld:gameWorld andRenderLayer:self.RenderLayer andPosition:ccp(xPos, yPos) andType:BlockType] autorelease];
        newblock.MyContainer=self;
        [newblock setup];
        posCount++;
    }
}

-(void)removeBlockFromMe:(id)thisBlock
{
    ((id<Moveable>)thisBlock).MyContainer=nil;
}

-(void)dealloc
{
    [super dealloc];
}

@end

