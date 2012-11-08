//
//  SGBtxeObjectOperator.h
//  belugapad
//
//  Created by gareth on 07/11/2012.
//
//

#import "SGGameObject.h"
#import "SGBtxeProtocols.h"

@class SGBtxeTextBackgroundRender;

@interface SGBtxeObjectOperator : SGGameObject <Text, MovingInteractive, NumberPicker, Containable, ValueOperator>
{
    CCNode *renderBase;
}

@property (retain) SGBtxeTextBackgroundRender *textBackgroundRenderComponent;

@end
