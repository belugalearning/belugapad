//
//  SGBtxePlaceholder.h
//  belugapad
//
//  Created by gareth on 03/11/2012.
//
//

#import "SGGameObject.h"
#import "SGBtxeProtocols.h"

@class SGBtxeTextBackgroundRender;

@interface SGBtxePlaceholder : SGGameObject <RenderObject, Bounding, Interactive, BtxeMount, Containable>
{
    CCNode *renderBase;
    CCDrawNode *drawNode;
    BOOL debugBoundingBox;
}

-(void)setContainerVisible:(BOOL)visible;
-(void)displayBoundingBox;

@property (retain) SGBtxeTextBackgroundRender *textBackgroundComponent;
@property (retain) NSString *targetTag;
//@property BOOL isLargeObject;
@property (retain) NSString *assetType;


@end
