//
//  SGBtxeRowLayout.m
//  belugapad
//
//  Created by gareth on 11/08/2012.
//
//

#import "SGBtxeRowLayout.h"
#import "global.h"
#import "ToolConsts.h"

@implementation SGBtxeRowLayout

-(SGBtxeRowLayout*)initWithGameObject:(id<Bounding, Container, RenderContainer>)aGameObject
{
    if(self=[super initWithGameObject:(SGGameObject*)aGameObject])
    {
        ParentGo=aGameObject;
    }
    return self;
}

-(void)layoutChildren
{
    [self layoutChildrenToWidth:ParentGo.rowWidth];
}

-(void)layoutChildrenToWidth:(float)rowMaxWidth
{
    float totalW=0, maxH=0;
    
    BOOL tintingOn=ParentGo.tintMyChildren;
    
    //get max height, total width
    for(id<Bounding> c in ParentGo.children)
    {
        if(c.size.height > maxH)maxH=c.size.height;
        totalW+=c.size.width + BTXE_HPAD;
    }
    
    //increase maxH
    maxH+=BTXE_VPAD;
    
    //remove last lot (effectively) of horiz padding
    if(totalW>0)totalW-=BTXE_HPAD;
    
    
    //figure out how many lines we need
    int lines=(int)((totalW / rowMaxWidth)+0.99);
    if(lines<1)lines=1;
    
    //set width of a line
    //float lineW=totalW / lines;
    
    //set line width to space allowed, e.g. force lines to full
    float lineW=rowMaxWidth;
    
    //get height of each line -- same for all at the minute
    // ...this can later be assessed line by line (re-calcing maxH for each line)
    float totalH=maxH * lines;
    float lineH=maxH;
    
    //set start (-half of line)
    float headXPos=-lineW / 2.0f;
    int colourIndex=0;
    
    //start Y at half of one line down from half of total container
    // ... a render mode may want this to flow down from top (not centre it) (e.g. for toolhost problem descriptions)
    //default is centre valign
    float headYPos=(totalH / 2.0f) - (lineH / 2.0f);
    if(ParentGo.forceVAlignTop)
    {
        //force alignment top down
        headYPos=0.0f;
//        headYPos=-lineH/2.0f;
    }
    
    int actualLines=1;
    
    NSMutableArray *centreBuffer=[[NSMutableArray alloc] init];
    
    //step items
    for(id<Bounding, NSObject> c in ParentGo.children)
    {
        NSLog(@"heady %f", headYPos);

        //if this element takes the line past lineW, flow to next line (only if item W is < lineW -- else just stick it on)
        if(((headXPos + c.size.width) > (lineW / 2.0f)) && c.size.width<lineW)
        {
            //centre objects in last line buffer
            [self centreObjectsIn:centreBuffer withHeadXPos:headXPos+c.size.width-BTXE_HPAD inWidth:rowMaxWidth];
            [centreBuffer removeAllObjects];
            
            //flow onto next line
            headXPos=-lineW / 2.0f;
            headYPos-=lineH;
            
            actualLines++;
        }
        
        //place object here (offset for centre position)
        c.position=CGPointMake(headXPos + (c.size.width / 2.0), headYPos);
        
        //if applicable, set this as the original position
        if([c conformsToProtocol:@protocol(MovingInteractive)])
        {
            id<MovingInteractive>thisMIo=(id<MovingInteractive>)c;
            if(!thisMIo.interactive)
                thisMIo.position=ccp(thisMIo.position.x,thisMIo.position.y+1);
            
            thisMIo.originalPosition=c.position;
            
            if(tintingOn){
                [thisMIo.textBackgroundRenderComponent setColourOfBackgroundTo:kBTXEColour[colourIndex]];
                colourIndex++;
            }
            
            if(colourIndex>7)colourIndex=0;
        }
        
        //  increment cum width (w/ width + spacer)
        headXPos+=c.size.width + BTXE_HPAD;
        
        //add to central buffer
        [centreBuffer addObject:c];
    }
    
    //centre last row
    [self centreObjectsIn:centreBuffer withHeadXPos:headXPos-BTXE_HPAD inWidth:rowMaxWidth];
    [centreBuffer release];    
    
    //set size of parent
    ParentGo.size=CGSizeMake(totalW, actualLines*lineH);
}

-(void)centreObjectsIn:(NSMutableArray*)buffer withHeadXPos:(float)usedWidth inWidth:(float)width
{
    //actual movement in width is greater because it was drawing from left to right offset at centre
    usedWidth+=width/2.0f;
    
    float moveBy=(width-usedWidth) / 2.0f;
    
    for(id<Bounding, NSObject> c in buffer)
    {
        c.position=ccp(c.position.x + moveBy, c.position.y);
        
        //if applicable, set this as the original position
        if([c conformsToProtocol:@protocol(MovingInteractive)])
        {
            ((id<MovingInteractive>)c).originalPosition=c.position;
        }
    }
}

@end
