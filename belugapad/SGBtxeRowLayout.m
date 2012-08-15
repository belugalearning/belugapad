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
    
    //remove last lot (effectively) of horiz padding
    if(totalW>0)totalW-=BTXE_HPAD;
    
    //set start (-half)
    float headXPos=-totalW / 2.0f;
    
    //step items
    for(id<Bounding, NSObject> c in ParentGo.children)
    {
        //place object here (offset for centre position)
        c.position=CGPointMake(headXPos + (c.size.width / 2.0), 0);
        
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
