//
//  SGBtxeRow.m
//  belugapad
//
//  Created by gareth on 11/08/2012.
//
//

#import "SGBtxeRow.h"
#import "SGBtxeContainerMgr.h"
#import "SGBtxeRowLayout.h"
#import "SGBtxeParser.h"
#import "SGBtxePlaceholder.h"
#import "SGBtxeObjectIcon.h"
#import "SGBtxeObjectText.h"
#import "SGBtxeObjectNumber.h"
#import "SGBtxeObjectOperator.h"
#import "SGBtxeText.h"

#import "global.h"

@implementation SGBtxeRow

@synthesize children, containerMgrComponent;   //Container properties
@synthesize renderLayer, forceVAlignTop;
@synthesize size, position, worldPosition, rowWidth;       //Bounding properties
@synthesize rowLayoutComponent;
@synthesize parserComponent;
@synthesize baseNode;
@synthesize myAssetType;
@synthesize defaultNumbermode;
@synthesize tintMyChildren;
@synthesize backgroundType;
@synthesize maxChildrenPerLine;
@synthesize hidden;


-(SGBtxeRow*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderLayer:(CCLayer*)renderLayerTarget
{
    if(self=[super initWithGameWorld:aGameWorld])
    {
        children=[[NSMutableArray alloc] init];
        size=CGSizeZero;
        position=CGPointZero;
        forceVAlignTop=NO;
//        isLarge=NO;
        tintMyChildren=YES;
        backgroundType=@"Tile";
        myAssetType=@"Small";
        self.defaultNumbermode=@"number";
        containerMgrComponent=[[SGBtxeContainerMgr alloc] initWithGameObject:(SGGameObject*)self];
        rowLayoutComponent=[[SGBtxeRowLayout alloc] initWithGameObject:(SGGameObject*)self];
        parserComponent=[[SGBtxeParser alloc] initWithGameObject:(SGGameObject*)self];
        rowWidth=BTXE_ROW_DEFAULT_MAX_WIDTH;
        
        self.renderLayer=renderLayerTarget;
    }
    return self;
}

-(void)handleMessage:(SGMessageType)messageType
{
    
}

-(void)doUpdate:(ccTime)delta
{
    
}

-(BOOL)containsObject:(id)o
{
    //just checks if o is in this row's children
    return [children containsObject:o];
}

-(void)inflateZindex
{
    self.baseNode.zOrder=99;
}
-(void)deflateZindex
{
    baseNode.zOrder=0;
}

-(void)setupDraw
{
    //create base node
    baseNode=[[CCNode alloc] init];
    self.baseNode.position=self.position;
    [renderLayer addChild:self.baseNode];
    
    //render each child
    for (id<Bounding, RenderObject> c in children) {
        
        if([((id<NSObject>)c) conformsToProtocol:@protocol(MovingInteractive)])
        {
            ((id<MovingInteractive>)c).assetType=self.myAssetType;
            ((id<MovingInteractive>)c).mount=nil;
        }
        
        if([((id<NSObject>)c) isKindOfClass:[SGBtxePlaceholder class]])
            ((SGBtxePlaceholder*)c).assetType=self.myAssetType;
        
        if([((id<NSObject>)c) conformsToProtocol:@protocol(MovingInteractive)])
            ((id<MovingInteractive>)c).backgroundType=self.backgroundType;
        
        if([((id<NSObject>)c) isKindOfClass:[SGBtxePlaceholder class]])
            ((SGBtxePlaceholder*)c).backgroundType=self.backgroundType;
        
        
        [c setupDraw];
        
        //we could potentially do this separately (create, layout, attach) -- but for the moment
        // this shouldn't have a performance impact as Cocos won't do stuff with this until we
        // release the run loop
        [c attachToRenderBase:self.baseNode];
    }
    
    //layout position of stuff
    [self.rowLayoutComponent layoutChildren];

}

-(void)setPosition:(CGPoint)thePosition
{
    position=thePosition;
    self.baseNode.position=self.position;
    
    //also need to update position of children as not all move with the base node
    for(id<Bounding> c in children)
    {
        c.position=c.position;
    }
}

-(void)tagMyChildrenForIntro
{
    if(!gameWorld.Blackboard.inProblemSetup)return;
    
    for(id c in children)
    {
        if([c isKindOfClass:[SGBtxeText class]])
        {
            [(SGBtxeText*)c tagMyChildrenForIntro];
        }
        if([c isKindOfClass:[SGBtxeObjectText class]])
        {
            [(SGBtxeObjectText*)c tagMyChildrenForIntro];
        }
        if([c isKindOfClass:[SGBtxeObjectIcon class]])
        {
            [(SGBtxeObjectIcon*)c tagMyChildrenForIntro];
        }
        if([c isKindOfClass:[SGBtxeObjectNumber class]])
        {
            [(SGBtxeObjectNumber*)c tagMyChildrenForIntro];
        }
        if([c isKindOfClass:[SGBtxeObjectOperator class]])
        {
            [(SGBtxeObjectOperator*)c tagMyChildrenForIntro];
        }
    }
}

-(NSString*)returnRowStringForSpeech
{
    NSString *rowString=@"";
    id lastc=nil;
    
    for(id c in children)
    {
        if(lastc)
        {
            if(([lastc isKindOfClass:[SGBtxeObjectIcon class]] || [lastc isKindOfClass:[SGBtxeObjectNumber class]] ||
               [lastc isKindOfClass:[SGBtxeObjectText class]]) &&
               ([c isKindOfClass:[SGBtxeObjectIcon class]] || [c isKindOfClass:[SGBtxeObjectNumber class]] ||
                [c isKindOfClass:[SGBtxeObjectText class]]))
            {
                rowString=[NSString stringWithFormat:@"%@, ", rowString];
            }
        }
        
        if([c isKindOfClass:[SGBtxeText class]])
        {
            rowString=[NSString stringWithFormat:@"%@ %@", rowString, [(SGBtxeText*)c returnMyText]];
        }
        
        if([c isKindOfClass:[SGBtxeObjectText class]])
        {
            rowString=[NSString stringWithFormat:@"%@ %@", rowString, [(SGBtxeObjectText*)c returnMyText]];
        }
        
        if([c isKindOfClass:[SGBtxeObjectNumber class]])
        {
            SGBtxeObjectNumber *bon=(SGBtxeObjectNumber*)c;
            
            NSNumberFormatter *nf = [NSNumberFormatter new];
            nf.numberStyle = NSNumberFormatterDecimalStyle;
//            NSNumber *thisNumber=[NSNumber numberWithFloat:[[(SGBtxeObjectNumber*)c numberText]floatValue]];
//            NSString *str = [nf stringFromNumber:thisNumber];
            NSString *str=bon.text;
            
            NSLog(@"text from db: %@", str);
            
            [nf release];
            
            if([[(SGBtxeObjectNumber*)c numberText]floatValue]<0)
            {
                str=[str stringByReplacingOccurrencesOfString:@"-" withString:@""];
                rowString=[NSString stringWithFormat:@"%@ negative %@", rowString, str];
            }
            else
            {
                rowString=[NSString stringWithFormat:@"%@ %@", rowString, str];
            }
        }
        
        if([c isKindOfClass:[SGBtxeObjectIcon class]])
        {
            rowString=[NSString stringWithFormat:@"%@ %@", rowString, [(SGBtxeObjectIcon*)c returnMyText]];
        }
        
        if([c isKindOfClass:[SGBtxeObjectOperator class]])
        {
            rowString=[NSString stringWithFormat:@"%@ %@", rowString, [(SGBtxeObjectOperator*)c returnMyText]];
        }
        lastc=c;
        
    }
    
    return rowString;
}

-(void)animateAndMoveToPosition:(CGPoint)thePosition
{
    for(id<NSObject> go in children)
    {
        if([go isKindOfClass:[SGBtxeObjectIcon class]])
        {
            ((SGBtxeObjectIcon*)go).animatePos=YES;
        }
    }
    
    position=thePosition;
    [self.baseNode runAction:[CCEaseInOut actionWithAction:[CCMoveTo actionWithDuration:0.25f position:position] rate:2.0f]];
}

-(void)relayoutChildrenToWidth:(float)width
{
    [self.rowLayoutComponent layoutChildrenToWidth:width];
}

-(void)fadeInElementsFrom:(float)startTime andIncrement:(float)incrTime
{
    float incr=startTime;
    
    for(id c in children)
    {
        if([c conformsToProtocol:@protocol(FadeIn)])
        {
            [c fadeInElementsFrom:incr andIncrement:incrTime];
            incr+=incrTime;
        }
    }
}

-(void)parseXML:(NSString *)xmlString
{
    [self.parserComponent parseXML:xmlString];
}

-(void)dealloc
{
    self.children=nil;
    self.containerMgrComponent=nil;
    self.rowLayoutComponent=nil;
    self.parserComponent=nil;
    self.renderLayer=nil;
    self.baseNode=nil;
    
    [children release];
    
    [super dealloc];
}

@end
