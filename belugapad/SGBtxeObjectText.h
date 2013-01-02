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

@interface SGBtxeObjectText : SGGameObject <Text, MovingInteractive, NumberPicker, Containable, FadeIn>
{
    CCNode *renderBase;
}

@property (retain) SGBtxeTextBackgroundRender *textBackgroundRenderComponent;

-(void)tagMyChildrenForIntro;
-(NSString*)returnMyText;

@end
