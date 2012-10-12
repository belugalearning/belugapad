//
//  SGBtxeContainerMgr.m
//  belugapad
//
//  Created by gareth on 11/08/2012.
//
//

#import "SGBtxeContainerMgr.h"

@implementation SGBtxeContainerMgr

-(SGBtxeContainerMgr*)initWithGameObject:(id<Container>)aGameObject
{
    if(self=[super initWithGameObject:(SGGameObject*)aGameObject])
    {
        ParentGO=aGameObject;
    }
    return self;
}

-(void)addObjectToContainer:(id<Bounding>)object
{
    [ParentGO.children addObject:object];
}

@end
