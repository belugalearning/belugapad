//
//  SGFractionBuilderRender.h
//  belugapad
//
//  Created by David Amphlett on 03/07/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "SGComponent.h"
#import "SGFractionObjectProtocols.h"

@interface SGFractionBuilderRender : SGComponent
{
    id<Configurable,Interactive> ParentGO;
}

-(void)setup;
-(void)showFraction;
-(void)hideFraction;

@end