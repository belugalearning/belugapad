//
//  SGBtxeObjectText.h
//  belugapad
//
//  Created by gareth on 11/08/2012.
//
//

#import "SGGameObject.h"
#import "SGBtxeProtocols.h"

@class SGBtxeTextBackgroundRender;

@interface SGBtxeObjectText : SGGameObject <Bounding, Text, Interactive>

@property (retain) SGBtxeTextBackgroundRender *textBackgroundRenderComponent;

@end
