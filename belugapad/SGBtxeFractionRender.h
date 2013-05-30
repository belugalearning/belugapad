#import "SGComponent.h"
#import "SGBtxeProtocols.h"

@class SGBtxeObjectNumber;

@interface SGBtxeFractionRender : SGComponent <FadeIn>
{
    SGBtxeObjectNumber *ParentGO;
}

@property (retain) CCNode *label;
@property (retain) CCNode *label0;

@property (retain) CCLabelTTF *numLabel;
@property (retain) CCLabelTTF *denomLabel;
@property (retain) CCLabelTTF *intLabel;
@property (retain) CCSprite *divLine;

@property (retain) CCLabelTTF *numLabel0;
@property (retain) CCLabelTTF *denomLabel0;
@property (retain) CCLabelTTF *intLabel0;
@property (retain) CCSprite *divLine0;



@property float maxw;
@property float fractionw;
@property float maxh;

@property BOOL useAlternateFont;
@property (retain) NSString *useTheseAssets;

-(void)setupDraw;
-(void)updatePosition:(CGPoint)position;
-(void)updateLabel;
-(void)inflateZindex;
-(void)deflateZindex;
-(void)tagMyChildrenForIntro;

@end
