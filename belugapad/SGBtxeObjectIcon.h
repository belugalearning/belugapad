//
//  SGBtxeObjectIcon.h
//  belugapad
//
//  Created by gareth on 01/10/2012.
//
//

#import "SGGameObject.h"
#import "SGBtxeProtocols.h"

@class SGBtxeIconRender;

@interface SGBtxeObjectIcon : SGGameObject <MovingInteractive, Icon, FadeIn>
{
    CCNode *renderBase;
}

@property (retain) SGBtxeIconRender *iconRenderComponent;

@end
