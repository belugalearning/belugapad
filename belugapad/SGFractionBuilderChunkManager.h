//
//  SGFractionBuilderChunk.h
//  belugapad
//
//  Created by David Amphlett on 24/07/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "SGComponent.h"
#import "SGFractionObjectProtocols.h"

@interface SGFractionBuilderChunkManager : SGComponent
{
    id<Configurable,Moveable,Interactive> ParentGO;
}

-(id)createChunk;
-(void)removeChunks;
-(void)ghostChunk;
-(void)changeChunk:(id<ConfigurableChunk>)thisChunk toBelongTo:(id<Interactive>)newFraction;
-(void)orderChildrenToLeftOn:(id<Configurable,Interactive>)newFraction;



@end
