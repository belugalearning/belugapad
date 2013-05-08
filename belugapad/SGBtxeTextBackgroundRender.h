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

@property (retain) CCNode *backgroundNode;

-(void)setColourOfBackgroundTo:(ccColor3B)thisColour;
-(ccColor3B)returnColourOfBackground;
-(void)setContainerVisible:(BOOL)visible;
-(void)setupDrawWithSize:(CGSize)size;
-(void)redrawBkgWithSize:(CGSize)size;
-(void)updatePosition:(CGPoint)position;
-(void)tagMyChildrenForIntro;
-(void)fadeInElementsFrom:(float)startTime andIncrement:(float)incrTime;
-(void)changeVisibility:(BOOL)visibility;

@end
