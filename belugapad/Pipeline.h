//
//  Pipeline.h
//  belugapad
//
//  Created by Gareth Jenkins on 08/05/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CouchDBDerivedDocument.h"

@interface Pipeline : CouchDBDerivedDocument

@property (readonly) NSString *name;
@property (readonly) NSArray *problems;

@end
