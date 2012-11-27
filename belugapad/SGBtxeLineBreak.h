//
//  SGBtxeObjectText.h
//  belugapad
//
//  Created by gareth on 11/08/2012.
//
//

#import "SGGameObject.h"
#import "SGBtxeProtocols.h"

@class SGBtxeLineBreak;

@interface SGBtxeLineBreak : SGGameObject <Containable,Bounding>
{
    CCNode *renderBase;
}

-(void)tagMyChildrenForIntro;
-(NSString*)returnMyText;

@end
