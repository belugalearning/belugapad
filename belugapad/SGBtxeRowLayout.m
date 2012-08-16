//
//  SGBtxeRowLayout.m
//  belugapad
//
//  Created by gareth on 11/08/2012.
//
//

#import "SGBtxeRowLayout.h"
#import "global.h"

@implementation SGBtxeRowLayout

-(SGBtxeRowLayout*)initWithGameObject:(id<Bounding, Container>)aGameObject
{
    if(self=[super initWithGameObject:(SGGameObject*)aGameObject])
    {
        ParentGo=aGameObject;
    }
    return self;
}

-(void)layoutChildren
{
    float totalW=0, maxH=0;
    
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
    int lines=(int)((totalW / BTXE_ROW_DEFAULT_MAX_WIDTH)+0.5);
    if(lines<1)lines=1;
    
    //set width of a line
    float lineW=totalW / lines;
    
    //get height of each line -- same for all at the minute
    // ...this can later be assessed line by line (re-calcing maxH for each line)
    float totalH=maxH * lines;
    float lineH=maxH;
    
    //set start (-half of line)
    float headXPos=-lineW / 2.0f;
    
    //start Y at half of one line down from half of total container
    // ... a render mode may want this to flow down from top (not centre it) (e.g. for toolhost problem descriptions)
    float headYPos=(totalH / 2.0f) - (lineH / 2.0f);
    
    //step items
    for(id<Bounding, NSObject> c in ParentGo.children)
    {
        //if this element takes the line past lineW, flow to next line (only if item W is < lineW -- else just stick it on)
        if(((headXPos + c.size.width) > (lineW / 2.0f)) && c.size.width<lineW)
        {
            //flow onto next line
            headXPos=-lineW / 2.0f;
            headYPos-=lineH;
        }
        
        //place object here (offset for centre position)
        c.position=CGPointMake(headXPos + (c.size.width / 2.0), headYPos);
        
        //if applicable, set this as the original position
        if([c conformsToProtocol:@protocol(MovingInteractive)])
        {
            ((id<MovingInteractive>)c).originalPosition=c.position;
        }
        
        //  increment cum width (w/ width + spacer)
        headXPos+=c.size.width + BTXE_HPAD;
    }
}

@end
