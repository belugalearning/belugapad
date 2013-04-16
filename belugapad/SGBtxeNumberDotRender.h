//
//  SGBtxeNumberDotRender.h
//  belugapad
//
//  Created by gareth on 23/11/2012.
//
//

#import "SGComponent.h"
#import "SGBtxeProtocols.h"

@interface SGBtxeNumberDotRender : SGComponent
{
    id<Value> ParentGO;
    float spacing;
}
@property (retain) CCNode *baseNode;
@property (readonly) CGSize size;

-(void)fadeInElementsFrom:(float)startTime andIncrement:(float)incrTime;
-(void)setupDraw;
-(void)updateDraw;
-(void)inflateZindex;
-(void)deflateZindex;
-(void)updatePosition:(CGPoint)thePosition;
-(void)changeVisibility:(BOOL)visibility;


@end
