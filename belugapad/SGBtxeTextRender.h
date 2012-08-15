//
//  SGBtxeTextRender.h
//  belugapad
//
//  Created by gareth on 11/08/2012.
//
//

#import "SGComponent.h"
#import "SGBtxeProtocols.h"

@interface SGBtxeTextRender : SGComponent
{
    id<Bounding, Text> ParentGO;
}

@property (retain) CCLabelTTF *label;

-(void)setupDraw;
-(void)updatePosition:(CGPoint)position;

@end
