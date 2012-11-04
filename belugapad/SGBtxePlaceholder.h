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

@interface SGBtxePlaceholder : SGGameObject <RenderObject, Bounding, Interactive>
{
}

@property (retain) SGBtxeTextBackgroundRender *textBackgroundComponent;

@end
