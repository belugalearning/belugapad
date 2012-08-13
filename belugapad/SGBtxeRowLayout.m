//
//  SGBtxeRowLayout.m
//  belugapad
//
//  Created by gareth on 11/08/2012.
//
//

#import "SGBtxeRowLayout.h"

@implementation SGBtxeRowLayout

-(SGBtxeRowLayout*)initWithGameObject:(id<Bounding, Container>)aGameObject
{
    if(self=[super initWithGameObject:(SGGameObject*)aGameObject])
    {
        
    }
    return self;
}

-(void)layoutChildren
{
    //step children, position (set their position property)
    
    //get total width (width + padding)
    
    //set start (-half)
    
    //step items
    
    //  put left of first item at far left of this
    
    //  increment cum width (w/ width + spacer)
    
    
}

@end
