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
    NSDate *currentSessionStart;
}
@end

@implementation User

@dynamic type, nickName, password, creationDateTime, zubiColor, sessions;
@dynamic topicsStarted, topicsCompleted, currentTopicId;
@dynamic modulesStarted, modulesCompleted, currentModuleId;
@dynamic elementsStarted, elementsCompleted, currentElementId;
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
        self.creationDateTime = [NSDate date];
        self.sessions = [NSMutableArray array];
        
        self.topicsStarted = [NSArray array];
        self.topicsCompleted = [NSArray array];
        
        self.modulesStarted = [NSArray array];
        self.modulesCompleted = [NSArray array];
        
        self.elementsStarted = [NSArray array];
        self.elementsCompleted = [NSArray array];
        
        self.nodesCompleted = [NSArray array];
        
        self.autosaves = YES;
    }
    return self;
}

-(void)startSession
{
    currentSessionStart = [[NSDate date] retain];
}

-(void)endSession
{
    NSMutableArray *mutableSessions = self.sessions ? [self.sessions mutableCopy] : [NSMutableArray array];
    NSDictionary *session = [NSDictionary dictionaryWithObjectsAndKeys: [RESTBody JSONObjectWithDate:currentSessionStart], "@start",
                                                                        [RESTBody JSONObjectWithDate:[NSDate date]], @"end",
                                                                        nil];
    [mutableSessions addObject:session];
    self.sessions = mutableSessions;
    
    [currentSessionStart release];
    currentSessionStart = nil;
}

@end
