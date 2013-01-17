//
//  SGBtxeRow.h
//  belugapad
//
//  Created by gareth on 11/08/2012.
//
//

#import "SGGameObject.h"
#import "SGBtxeProtocols.h"

@class SGBtxeRowLayout;

@interface SGBtxeRow : SGGameObject <Container, Bounding, Parser, RenderContainer, FadeIn>
{
    NSMutableArray *children;
}

@property (retain) SGBtxeRowLayout *rowLayoutComponent;

@property int maxChildrenPerLine;

-(SGBtxeRow*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderLayer:(CCLayer*)renderLayerTarget;

-(void)tagMyChildrenForIntro;
-(BOOL)containsObject:(id)o;
-(void)inflateZindex;
-(void)deflateZindex;
-(void)relayoutChildrenToWidth:(float)width;
-(void)animateAndMoveToPosition:(CGPoint)thePosition;
-(NSString*)returnRowStringForSpeech;


@end
