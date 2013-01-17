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
@synthesize RandomPositions;
@synthesize CurrentObject;

-(SGDtoolCage*) initWithGameWorld:(SGGameWorld*)aGameWorld atPosition:(CGPoint)thisPosition andRenderLayer:(CCLayer*)aRenderLayer andCageType:(NSString*)thisCageType
{
    if(self=[super initWithGameWorld:aGameWorld])
    {
        self.Position=thisPosition;
        self.RenderLayer=aRenderLayer;
        self.CageType=thisCageType;
        self.CurrentObject=nil;
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
    else if(InitialObjects>30)InitialObjects=30;
    
    NSString *sprFileName=nil;
    
    if(!self.CageType)
        sprFileName=@"/images/distribution/DT_Dock_Infinite.png";
    else if([self.CageType isEqualToString:@"Infinite-Random"])
        sprFileName=@"/images/distribution/DT_Dock_Infinite.png";
    else if([self.CageType isEqualToString:@"Infinite-RandomValue"])
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
    
    NSLog(@"cage currentobject? %@", self.CurrentObject?@"YES":@"NO");
    if(self.CurrentObject)return;
    
    float spacer=66.0f;
    
    float totalLength=MySprite.contentSize.width-(spacer*2);

    int skipCount=0;
    int numberOfFreeSpaces=0;
    
    
    if([CageType isEqualToString:@"15"])
        numberOfFreeSpaces=15-InitialObjects;
    if([CageType isEqualToString:@"30"])
        numberOfFreeSpaces=30-InitialObjects;
    
    int chance=((float)numberOfFreeSpaces/(float)(InitialObjects+numberOfFreeSpaces))*100;
    
    if(!self.RandomPositions)chance=0;
    
    // render buttons
    float sectionW=0;
    if (InitialObjects<=15)
        sectionW=totalLength / InitialObjects;
    else
        sectionW=totalLength / 15;
    
    float startPosX=MySprite.position.x+(spacer+1)-(MySprite.contentSize.width/2);
    int totalCount=0;
    int createCount=0;
    int posCount=0;
    while(createCount<InitialObjects)
    {

        int randomNo=arc4random() % 100;
        if(randomNo<chance && skipCount<numberOfFreeSpaces)
        {
            skipCount++;
            posCount++;
            totalCount++;
            continue;
        }
        
        int thisBlockType=0;
        NSString *newBlockType=BlockType;
        
        if([CageType isEqualToString:@"Infinite-Random"])
        {
            thisBlockType=arc4random() % 5;
            
            if(thisBlockType==0)
                newBlockType=@"Circle";
            else if(thisBlockType==1)
                newBlockType=@"Diamond";
            else if(thisBlockType==2)
                newBlockType=@"Ellipse";
            else if(thisBlockType==3)
                newBlockType=@"House";
            else if(thisBlockType==4)
                newBlockType=@"RoundedSquare";
            else if(thisBlockType==5)
                newBlockType=@"Square";
        }
        
        if([CageType isEqualToString:@"Infinite-RandomValue"])
        {
            thisBlockType=arc4random() % 4;
            
            if(thisBlockType==0)
                newBlockType=@"Value_001";
            else if(thisBlockType==1)
                newBlockType=@"Value_01";
            else if(thisBlockType==2)
                newBlockType=@"Value_1";
            else if(thisBlockType==3)
                newBlockType=@"Value_10";
            else if(thisBlockType==4)
                newBlockType=@"Value_100";
        }
        
        
        //if(posCount==15)posCount=0;
        float xPos=startPosX+((posCount%15)+0.5) * sectionW;
        float yPos=0;
        
        if(InitialObjects==1)
            yPos=45.0f;
        else if(InitialObjects>1&&InitialObjects<=15)
            yPos=55.0f;
        else
            yPos=120-((totalCount/(int)15)*60);
        
        id<Configurable,Selectable,Pairable,Moveable> newblock;
        newblock=[[[SGDtoolBlock alloc] initWithGameWorld:gameWorld andRenderLayer:self.RenderLayer andPosition:ccp(xPos, yPos) andType:newBlockType] autorelease];
        newblock.MyContainer=self;
        self.CurrentObject=newblock;
        [newblock setup];
        posCount++;
        totalCount++;
        createCount++;
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

