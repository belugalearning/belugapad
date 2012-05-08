//
//  Pipeline.h
//  belugapad
//
//  Created by Gareth Jenkins on 08/05/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <CouchCocoa/CouchCocoa.h>

@interface Pipeline : CouchModel

@property (readonly, retain) NSArray *problems;
@property (readonly, retain) NSString *name;

@end
