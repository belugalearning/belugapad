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

@interface SGFBuilderRow : SGGameObject <Row,RenderedObject>

@property (retain) SGFBuilderRowRender *RowRenderComponent;

-(SGFBuilderRow*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderLayer:(CCLayer*)aRenderLayer andPosition:(CGPoint)aPosition;

@end
