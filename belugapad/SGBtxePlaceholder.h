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
}

@property (retain) SGBtxeTextBackgroundRender *textBackgroundComponent;

@end