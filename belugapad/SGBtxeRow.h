//
//  SGBtxeRow.h
//  belugapad
//
//  Created by gareth on 11/08/2012.
//
//

#import "SGGameObject.h"
#import "SGBtxeProtocols.h"

@class SGBtxeRowLayout;

@interface SGBtxeRow : SGGameObject <Container, Bounding, Parser, RenderContainer, FadeIn>
{
    NSMutableArray *children;
    CCNode *baseNode;
}

@property (retain) SGBtxeRowLayout *rowLayoutComponent;


-(SGBtxeRow*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderLayer:(CCLayer*)renderLayerTarget;


@end
