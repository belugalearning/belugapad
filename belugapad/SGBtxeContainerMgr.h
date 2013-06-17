//
//  SGBtxeContainerMgr.h
//  belugapad
//
//  Created by gareth on 11/08/2012.
//
//

#import "SGComponent.h"
#import "SGBtxeProtocols.h"

@interface SGBtxeContainerMgr : SGComponent
{
    id<Container> ParentGO;
}

-(void)addObjectToContainer:(id<Bounding>)object;
-(void)removeObjectFromContainer:(id<Bounding, NSObject>)object;

@end
