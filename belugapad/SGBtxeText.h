//
//  SGBtxeText.h
//  belugapad
//
//  Created by gareth on 11/08/2012.
//
//

#import "SGGameObject.h"
#import "SGBtxeProtocols.h"

@interface SGBtxeText : SGGameObject <Bounding, Text, RenderObject, FadeIn, Containable>

-(void)tagMyChildrenForIntro;
-(NSString*)returnMyText;

@end
