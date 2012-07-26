//
//  SGFractionBuilderChunkRender.h
//  belugapad
//
//  Created by David Amphlett on 26/07/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "SGComponent.h"
#import "SGFractionObjectProtocols.h"

@interface SGFractionBuilderChunkRender : SGComponent
{
    id<ConfigurableChunk,Moveable> ParentGO;
}

-(void)setup;

@end
