//
//  SGDtoolBlockPairing.h
//  belugapad
//
//  Created by David Amphlett on 06/07/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "SGComponent.h"
#import "SGDtoolObjectProtocols.h"

@interface SGDtoolBlockPairing : SGComponent
{
    id<Pairable> ParentGO;
}

@end