//
//  SGBtxeTextBackgroundRender.h
//  belugapad
//
//  Created by gareth on 14/08/2012.
//
//

#import "SGComponent.h"
#import "SGBtxeProtocols.h"

@interface SGBtxeTextBackgroundRender : SGComponent
{
    id<Bounding, Text> ParentGO;
}

@property (retain) CCSprite *sprite;

-(void)setupDrawWithSize:(CGSize)size;
-(void)updatePosition:(CGPoint)position;

@end
