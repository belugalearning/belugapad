//
//  DWGameObject.m
//
//  Created by Gareth Jenkins on 16/06/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "DWGameObject.h"
#import "DWBehaviour.h"


@implementation DWGameObject

@synthesize gameWorld;

+(DWGameObject*) createFromTemplate:(NSString*) templateName withWorld:(DWGameWorld *)gw
{
    //load templates from templatesdefs
	NSString *path=[[NSBundle mainBundle] pathForResource:@"templatedefs-general" ofType:@"plist"];
	NSDictionary *templateDefs=[NSDictionary dictionaryWithContentsOfFile:path];
	
	//create the game object
	DWGameObject *gameObject=[[DWGameObject alloc] initWithGameWorld:gw];

	[[gameObject store] setObject:templateName forKey:TEMPLATE_NAME];
	
    //parse the root template
	[self parseTemplate:templateName inTemplateDefs:templateDefs forObject:gameObject];
    [gameObject initComplete];
	
    [gameObject autorelease];
    return gameObject;
}

+(void) populateObject:(DWGameObject*) theObject fromTemplate:(NSString*) templateName withWorld:(DWGameWorld *)gw
{
    //load templates from templatesdefs
	NSString *path=[[NSBundle mainBundle] pathForResource:@"templatedefs-general" ofType:@"plist"];
	NSDictionary *templateDefs=[NSDictionary dictionaryWithContentsOfFile:path];

    [theObject initWithGameWorld:gw];
    
	[[theObject store] setObject:templateName forKey:TEMPLATE_NAME];
	
    //parse the root template
	[self parseTemplate:templateName inTemplateDefs:templateDefs forObject:theObject];
    [theObject initComplete];
	
    //[theObject autorelease];    
}

+(void) parseTemplate:(NSString *)templateName inTemplateDefs:(NSDictionary *)templateDefs forObject:(DWGameObject *)gameObject
{
	//get template
	NSDictionary *t=[templateDefs objectForKey:templateName];
	
	//get list of implements - and call parse template on these
	NSArray *implements=[t objectForKey:IMPLEMENT_TEMPLATES];
	if(implements!=nil)
	{
		for (NSString *imp in implements) {
			[self parseTemplate:imp inTemplateDefs:templateDefs forObject:gameObject];
		}
	}
	
	//get list of behaviours - and load those, inc behaviour-level vars
	NSDictionary *behs=[t objectForKey:BEHAVIOURS];
    
	for(NSString *behKey in [behs allKeys])
	{
		//ignore behaviours starting with _
		if([behKey characterAtIndex:0]!='_')
		{
			NSDictionary *passData=[behs objectForKey:behKey];
			[gameObject addBehaviour:behKey
							withData:passData];
		}
	}
	
	//set object-level data
	[gameObject loadData:[t objectForKey:OBJECT_DATA]];
}

-(void)initComplete
{
    [self handleMessage:kDWonGameObjectInitComplete];
}

-(DWGameObject *) initWithGameWorld:(DWGameWorld*)aGameWorld
{
    if( (self=[super init] )) 
    {
        gameWorld=aGameWorld;
        behaviours=[[NSMutableArray alloc] init];
        
        localStore=[[NSMutableDictionary alloc] init];
    }
	return self;
}

-(void)loadData:(NSDictionary *)data
{
	//add data - this will overwrite stuff
	for (NSString *k in [data allKeys]) {

		//copy the data from template definition
        
        NSObject *oc =[[data objectForKey:k] copy];
        NSString *kc=[k copy];
        
        [localStore setObject:oc forKey:kc];
        
        [oc release];
        [kc release];
	}
}

-(void)addBehaviour:(NSString *)behName withData:(NSDictionary *)data
{
	DWBehaviour *b=nil;
	
	//look in current behaviours
	for(DWBehaviour *o in behaviours)
	{
		if([behName isEqualToString:NSStringFromClass([o class])])
		{
			[self logDebugMessage:@"existing behaviour found, overwriting data if required but not allocating new behaviour" atLevel:5];
			
			b=o;
			break;
		}
	}
	
	//check for existence of behaviour, if not found init/alloc
	if(!b)
	{
		[self logDebugMessage:@"behaviour not found, allocting new behaviour for this game object" atLevel:5];
		
		DWBehaviour *newb=[[NSClassFromString(behName) alloc] initWithGameObject:self withData:data];
		[behaviours addObject:newb];
        [newb release];
	}
}
-(void)addBehaviour:(DWBehaviour*)behaviour
{
    [behaviours addObject:behaviour];
}

-(void)logInfo:(NSString *) desc withData:(int)logData
{
    [gameWorld logInfoWithRawMessage:[NSString stringWithFormat:@"%@, %@, %d, %@, %d", [NSDate date], [localStore objectForKey:TEMPLATE_NAME], (int)self, desc, logData]];
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload withLogLevel:(int)logLevel
{
    //log here
    if(logLevel>= LOG_OUTPUT_LEVEL)
    {
        [self logInfo:@"go-handled-loggable-message" withData:messageType];
    }
    
    
	for(DWBehaviour *b in behaviours)
	{
		[b handleMessage:messageType andPayload:payload];
	}
}
-(void)handleMessage:(DWMessageType)messageType
{
    [self handleMessage:messageType andPayload:nil withLogLevel:0];
}

-(void)doUpdate:(ccTime)delta
{
	for(DWBehaviour *b in behaviours)
	{
		[b doUpdate:delta];
	}
}

-(void)logLocalStore
{
	DLog(@"==================== game object ... localstore follows");
	
	for(NSString *key in [localStore allKeys])
	{
		DLog(@"%@ == %@", key, [[localStore objectForKey:key] description]);
	}
	
	DLog(@"...and behviours");
	
	for(DWBehaviour *b in behaviours)
	{
		[b logLocalStore];
	}
}

-(void)logDebugMessage:(NSString *)message atLevel:(int)level
{
	if(level<=DEBUG_LEVEL)
	{
		DLog(@"%@ lvl%d behaviour debug log: %@", [self description], level, message);
	}
}

-(NSMutableDictionary *)store
{
	return localStore;
}


-(DWBehaviour*) queryBehaviourByClass:(Class)classType
{
    for(DWBehaviour *behaviour in behaviours)
    {
        if([behaviour isKindOfClass:classType])
        {
            return behaviour;
        }
        
    }
    return nil;
}

-(void)cleanup
{
    for (DWBehaviour *b in behaviours) {
        [b cleanup];
    }
    
    [localStore removeAllObjects];
}

-(void)dealloc
{
	[behaviours release];
	[localStore release];
	
	[super dealloc];
}

@end
