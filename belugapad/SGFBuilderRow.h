//
//  SGFBuilderRow.h
//  belugapad
//
//  Created by David Amphlett on 08/04/2013.
//
//

#import "SGGameObject.h"
#import "SGFBuilderObjectProtocols.h"
#import "LogPollingProtocols.h"

@class SGFBuilderRowRender;
@class SGFBuilderRowTouch;

@interface SGFBuilderRow : SGGameObject <Row,RenderedObject, Touchable>

@property (retain) SGFBuilderRowRender *RowRenderComponent;
@property (retain) SGFBuilderRowTouch *RowTouchComponent;

-(SGFBuilderRow*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderLayer:(CCLayer*)aRenderLayer andPosition:(CGPoint)aPosition;

@end
