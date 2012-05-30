//
//  User.m
//  belugapad
//
//  Created by Nicholas Cartwright on 19/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "User.h"
#import "AppDelegate.h"
#import <CouchCocoa/CouchCocoa.h>

NSString *const kZubiScreenshotFile = @"zubi_screenshot.png";

@interface User()
{
    @private
}
@end

@implementation User

@dynamic type, nickName, password, dateCreation, zubiColor;
@dynamic nodesCompleted;

- (UIImage*) zubiScreenshot
{
    CouchAttachment* a = [self attachmentNamed:kZubiScreenshotFile];
    if (!a) return nil;
    return [[[UIImage alloc] initWithData: a.body] autorelease];
}

- (void) setZubiScreenshot:(UIImage*)image
{
    if (!image)
    {
        [self removeAttachmentNamed:kZubiScreenshotFile];
    } else
    {
        NSData* png = UIImagePNGRepresentation(image);
        [self createAttachmentWithName:kZubiScreenshotFile type:@"image/png" body:png];
    }
}

- (id) initWithNewDocumentInDatabase:(CouchDatabase*)database
{
    NSParameterAssert(database);
    self = [super initWithDocument: nil];
    if (self)
    {
        self.database = database;
        self.type = @"user";
        self.dateCreation = [NSDate date];        
        self.nodesCompleted = [NSArray array];
        
        self.autosaves = YES;
    }
    return self;
}

@end
