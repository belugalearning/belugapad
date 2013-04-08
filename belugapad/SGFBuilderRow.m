//
//  SGFBuilderRow.m
//  belugapad
//
//  Created by David Amphlett on 08/04/2013.
//
//

#import "SGFBuilderRow.h"
#import "SGFBuilderRowRender.h"
#import "SGFBuilderRowTouch.h"
#import "SGFBuilderBlock.h"


@implementation SGFBuilderRow

@synthesize ContainedBlocks;
@synthesize Denominator;
@synthesize RenderLayer, MySprite, Position;
@synthesize DenominatorDownButton, DenominatorUpButton;
@synthesize RowRenderComponent;
@synthesize RowTouchComponent;

-(SGFBuilderRow*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderLayer:(CCLayer*)aRenderLayer andPosition:(CGPoint)aPosition
{
    if(self=[super initWithGameWorld:aGameWorld])
    {
        self.RenderLayer=aRenderLayer;
        self.Position=aPosition;
    }
    
    RowRenderComponent=[[SGFBuilderRowRender alloc] initWithGameObject:self];
    RowTouchComponent=[[SGFBuilderRowTouch alloc] initWithGameObject:self];
    ContainedBlocks=[[NSMutableArray alloc]init];
    
    return self;
}

-(void)checkTouch:(CGPoint)location
{
    [RowTouchComponent checkTouch:location];
}

-(void)setup
{
    [RowRenderComponent setupSprite];
}

-(void)splitFraction
{
    
//    fractionSprite=ParentGO.FractionSprite;
//    float leftPos=fractionSprite.position.x-(fractionSprite.contentSize.width/2);
//    //        float leftPos=fractionSprite.position.x;
//    float posOnFraction=fractionSprite.contentSize.width/(ParentGO.MarkerPosition+1);
//    float adjPosOnFraction=posOnFraction*([ParentGO.Chunks count]);
//    CGPoint startPos=ccp(leftPos+adjPosOnFraction,fractionSprite.position.y);
//    
//    startPos=[fractionSprite.parent convertToWorldSpace:startPos];
//    
//    id<ConfigurableChunk> chunk;
//    chunk=[[[SGFbuilderChunk alloc] initWithGameWorld:gameWorld andRenderLayer:ParentGO.RenderLayer andPosition:startPos] autorelease];
//    chunk.MyParent=ParentGO;
//    chunk.CurrentHost=ParentGO;
//    chunk.ScaleX=20.0f/(ParentGO.MarkerPosition+1);
//    NSLog(@"this chunk's scale is %f. 20/MarkerPos=%f, MarkerPos=%d", chunk.ScaleX, 20.0f/ParentGO.MarkerPosition, ParentGO.MarkerPosition);
//    chunk.Value=ParentGO.Value/(ParentGO.MarkerPosition+1);
    
    NSLog(@"need to split fraction. current denominator is %d", Denominator);
    
    if([ContainedBlocks count]>0)
    {
        for(id<RenderedObject> go in ContainedBlocks)
        {
            [go destroy];
        }
        
        [ContainedBlocks removeAllObjects];
    }
    
    
    for(int i=0;i<Denominator;i++)
    {
        
        float leftPos=MySprite.position.x-(MySprite.contentSize.width/2);
        //    float sectionSize=MySprite.contentSize.width/Denominator;
        //    float startXPos=MySprite.position.x-(MySprite.contentSize.width/2);
        float startYPos=MySprite.position.y-(MySprite.contentSize.height/2);
        float posOnFraction=MySprite.contentSize.width/(Denominator+1);
        float adjPosOnFraction=posOnFraction*([ContainedBlocks count]);
        CGPoint startPos=ccp(leftPos+adjPosOnFraction,MySprite.position.y);
        
        
        id <Block,RenderedObject> block=[[SGFBuilderBlock alloc]initWithGameWorld:gameWorld andRenderLayer:self.RenderLayer andPosition:startPos];
        [block setup];
        
        [ContainedBlocks addObject:block];

        NSLog(@"%d new block time!", i);
    }
}

-(void)setRowDenominator:(int)incr
{
    int oldDenominator=Denominator;
    
    Denominator+=incr;
    
    if(Denominator<0)
        Denominator=0;
    
    if(oldDenominator!=Denominator)
    {
        [self splitFraction];
    }
    

}

-(void)destroy
{
    [RowRenderComponent destroy];
}

@end
