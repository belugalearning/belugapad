//
//  EditUser.h
//  belugapad
//
//  Created by Nicholas Cartwright on 16/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"

@interface EditZubi : CCLayer
{
}

+ (CCScene *) scene;
- (void) setZubiColor:(ccColor4F)aColor;
- (NSString*) takeScreenshot;

@end
