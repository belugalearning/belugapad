//
//  SGBtxeTextRender.h
//  belugapad
//
//  Created by gareth on 11/08/2012.
//
//

#import "SGComponent.h"
#import "SGBtxeProtocols.h"

@interface SGBtxeTextRender : SGComponent <FadeIn>
{
    id<Bounding, Text> ParentGO;
}

@property (retain) CCLabelTTF *label;
@property (retain) CCLabelTTF *label0;
@property BOOL useAlternateFont;
@property (retain) NSString *useTheseAssets;

-(void)setupDraw;
-(void)updatePosition:(CGPoint)position;
-(void)updateLabel;
-(void)inflateZindex;
-(void)deflateZindex;
-(void)tagMyChildrenForIntro;

@end
