//
//  SGBtxeIconRender.h
//  belugapad
//
//  Created by gareth on 01/10/2012.
//
//

#import "SGComponent.h"
#import "SGBtxeProtocols.h"

@interface SGBtxeIconRender : SGComponent <FadeIn>
{
    id<Bounding, MovingInteractive, Icon> ParentGO;
}

@property (retain) CCSprite *sprite;
@property (retain) NSString *assetType;

-(void)setupDraw;
-(void)updatePosition:(CGPoint)position;
-(void)updatePositionWithAnimation:(CGPoint)position;
-(void)inflateZindex;
-(void)deflateZindex;

@end
