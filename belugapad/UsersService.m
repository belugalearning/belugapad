//
//  UsersService.m
//  belugapad
//
//  Created by Nicholas Cartwright on 12/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UsersService.h"
#import "Device.h"
#import "User.h"
#import <CouchCocoa/CouchCocoa.h>
#import <CouchCocoa/CouchDesignDocument_Embedded.h>
#import <CouchCocoa/CouchModelFactory.h>
#import <CouchCocoa/CouchTouchDBServer.h>

NSString * const kRemoteUsersDatabaseURI = @"http://www.soFarAslant.com:5984/temp-blm-users";
NSString * const kLocalUserDatabaseName = @"users";
NSString * const kDefaultDesignDocName = @"default";
NSString * const kDeviceUsersLastSessionStart = @"device-users-last-session";
NSString * const kAllUserNicknames = @"all-user-nick-names";
NSString * const kUsersByNickNamePassword = @"users-by-nick-name-password";

@interface UsersService()
{
    @private
    NSString *installationUUID;
    Device *device;
    NSMutableDictionary *currentUserSession;
    
    CouchDatabase *database;
    CouchReplication *pushReplication;
    CouchReplication *pullReplication;
}
-(void)createViews;
-(void)startLiveQueries;
@end

@implementation UsersService

@synthesize installationUUID;
@synthesize currentUser;

-(id)init
{
    self = [super init];
    if (self)
    {
        [[CouchModelFactory sharedInstance] registerClass:[Device class] forDocumentType:@"device"];
        [[CouchModelFactory sharedInstance] registerClass:[User class] forDocumentType:@"user"];
        
        CouchTouchDBServer *server = [CouchTouchDBServer sharedInstance];
        
        database = [server databaseNamed:kLocalUserDatabaseName];
        RESTOperation* op = [database create];
        if (![op wait] && op.error.code != 412)
        {
            self = nil;
            return self;
        }
        database.tracksChanges = YES;
                
        NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
        if (![standardUserDefaults objectForKey:@"installationUUID"])
        {
            // This is the first run of the app on the device
            CouchDocument *deviceDoc = [database untitledDocument];
            RESTOperation *op = [deviceDoc putProperties:[NSDictionary dictionaryWithObjectsAndKeys:
                                                          @"device", @"type"
                                                          , [RESTBody JSONObjectWithDate:[NSDate date]], @"firstLaunchDateTime"
                                                          , [NSArray array], @"userSessions", nil]];
            if (![op wait])
            {
                self = nil;
                return self;
            }
            
            [standardUserDefaults setObject:deviceDoc.documentID forKey:@"installationUUID"];
        }
        
        installationUUID = [standardUserDefaults objectForKey:@"installationUUID"];
        device = [[[CouchModelFactory sharedInstance] modelForDocument:[database documentWithID:installationUUID]] retain];
        device.autosaves = true;
        
        [self createViews];
        [self startLiveQueries];

        pushReplication = [[database pushToDatabaseAtURL:[NSURL URLWithString:kRemoteUsersDatabaseURI]] retain];
        pushReplication.continuous = YES;
        pushReplication = [[database pullFromDatabaseAtURL:[NSURL URLWithString:kRemoteUsersDatabaseURI]] retain];
        pushReplication.continuous = YES;
    }
    return self;
}

-(void)setCurrentUser:(User*)user
{
    NSString *now = [RESTBody JSONObjectWithDate:[NSDate date]];
    
    if (currentUser)
    {
        [currentUserSession setObject:now forKey:@"endDateTime"];
        [currentUser release];
    }
    
    currentUser = [user retain];
    
    currentUserSession = [NSMutableDictionary dictionary];
    [currentUserSession setObject:user.document.documentID forKey:@"userId"];
    [currentUserSession setObject:now forKey:@"startDateTime"];
    
    NSMutableArray *userSessions = [device.userSessions mutableCopy];
    [userSessions addObject:currentUserSession];
    device.userSessions = userSessions;
    [[device save] wait];
}

-(NSArray*)deviceUsersByLastSessionDate
{
    // The view named kDeviceUsersLastSessionStart will pull back the most recent session start for each user on each device
    // key: [deviceId, userId]      value:sessionStart
    CouchQuery *q = [[database designDocumentWithName:kDefaultDesignDocName] queryViewNamed:kDeviceUsersLastSessionStart];
    q.groupLevel = 2;
    q.startKey = [NSArray arrayWithObjects:device.document.documentID, nil];
    q.endKey = [NSArray arrayWithObjects:device.document.documentID, [NSDictionary dictionary], nil];
    [[q start] wait];
    
    // now need to sort the users themselves by their most recent session start
    NSArray *sortedBySessionStartDesc = [q.rows.allObjects sortedArrayUsingComparator:^(id a, id b) {
        return [(NSString*)((CouchQueryRow*)b).value compare:(NSString*)((CouchQueryRow*)a).value];
    }];
    
    NSMutableArray *users = [NSMutableArray array];
    for (CouchQueryRow *row in sortedBySessionStartDesc)
    {
        CouchDocument *userDoc = [database documentWithID:row.key1];
        User *user = [[CouchModelFactory sharedInstance] modelForDocument:userDoc];
        if (user) [users addObject:user];
    }
    
    return [users copy];
}

-(BOOL) nickNameIsAvailable:(NSString*)nickName
{
    CouchQuery *q = [[database designDocumentWithName:kDefaultDesignDocName] queryViewNamed:kAllUserNicknames];
    q.keys = [NSArray arrayWithObject:nickName];
    q.prefetch = YES;
    [[q start] wait];
    return [q.rows.allObjects count] == 0;
}

-(User*) userMatchingNickName:(NSString*)nickName
                     andPassword:(NSString*)password
{
    CouchQuery *q = [[database designDocumentWithName:kDefaultDesignDocName] queryViewNamed:kUsersByNickNamePassword];
    q.keys = [NSArray arrayWithObject:[NSArray arrayWithObjects:nickName, password, nil]];
    [[q start] wait];
    
    if ([q.rows.allObjects count] == 0) return nil;
    
    return [[CouchModelFactory sharedInstance] modelForDocument:((CouchQueryRow*)[q.rows.allObjects objectAtIndex:0]).document];
}

-(User*) createUserWithNickName:(NSString*)nickName
                    andPassword:(NSString*)password
                    andZubiColor:(NSData*)color // rgba
               andZubiScreenshot:(UIImage*)image
{
    User *u = [[[User alloc] initWithNewDocumentInDatabase:database] autorelease];
    u.nickName = nickName;
    u.password = password;
    u.zubiColor = color;
    u.zubiScreenshot = image;
    u.autosaves = YES;
    RESTOperation *op = [u save];
    [op wait];
    return u;
}

-(void)createViews
{
    CouchDesignDocument* design = [database designDocumentWithName:kDefaultDesignDocName];
    
    [design defineViewNamed:kDeviceUsersLastSessionStart
                   mapBlock:MAPBLOCK({        
                id type = [doc objectForKey:@"type"];                        
                if (type && 
                    [type respondsToSelector:@selector(isEqualToString:)] && 
                    [type isEqualToString:@"device"])
                {
                    for (NSDictionary *session in [doc objectForKey:@"userSessions"]) {
                        emit([NSArray arrayWithObjects:[doc objectForKey:@"_id"], [session objectForKey:@"userId"], nil], 
                             [session objectForKey:@"startDateTime"]);
                    }
                }
        }) 
                reduceBlock:REDUCEBLOCK({
        NSSortDescriptor *sd = [NSSortDescriptor sortDescriptorWithKey:nil ascending:NO selector:@selector(localizedCaseInsensitiveCompare:)];
        NSArray *sessionsByStartDesc = [values sortedArrayUsingDescriptors:[NSArray arrayWithObject:sd]];
        return [sessionsByStartDesc objectAtIndex:0];
                })
                    version: @"v1.04"];
    
    [design defineViewNamed:kAllUserNicknames
                   mapBlock:MAPBLOCK({
        id type = [doc objectForKey:@"type"];
        if (type &&
            [type respondsToSelector:@selector(isEqualToString:)] &&
            [type isEqualToString:@"user"])
        {
            emit([doc objectForKey:@"nickName"], nil);
        }
    })
                    version: @"v1.01"];
    
    [design defineViewNamed:kUsersByNickNamePassword
                        mapBlock:MAPBLOCK({        
        id type = [doc objectForKey:@"type"];        
        
        if (type && 
            [type respondsToSelector:@selector(isEqualToString:)] && 
            [type isEqualToString:@"user"])
        {
            emit([NSArray arrayWithObjects:[doc objectForKey:@"nickName"], [doc objectForKey:@"password"], nil], nil);
        }
    })
                    version: @"v1.00"];
}

-(void)startLiveQueries
{
}

-(void)dealloc
{
    [device release];
    [pushReplication release];
    [pullReplication release];
    [super dealloc];
}
    

@end
