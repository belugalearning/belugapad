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
	
	//tofu: template definitions should be cached
	
	//create the game object
	DWGameObject *gameObject=[[DWGameObject alloc] initWithGameWorld:gw];

	[[gameObject store] setObject:templateName forKey:TEMPLATE_NAME];
	
    //parse the root template
	[self parseTemplate:templateName inTemplateDefs:templateDefs forObject:gameObject];
    [gameObject initComplete];
	
    
    return gameObject;
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
		//tofu - tidy this up (no local var is needed)
		
		//ignore behaviours starting with _
		if([behKey characterAtIndex:0]!='_')
		{
			NSDictionary *passData=[behs objectForKey:behKey];
			//tofu got problem with this being static...might need to provide a static loging system.
			//[self logDebugMessage:[NSString stringWithFormat:@"datacount %d", [passData count]] atLevel:2];
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
        [behaviours retain];
        
        localStore=[[NSMutableDictionary alloc] init];
        [localStore retain];
    }
	return self;
}

-(void)loadData:(NSDictionary *)data
{
	//add data - this will overwrite stuff
	for (NSString *k in [data allKeys]) {

		//copy the data from template definition
		//[localStore setObject:[[data objectForKey:k] copy] forKey:[k copy]];
        
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
	
	//tofu: check for existence of behaviour, if not found init/alloc
	if(b==nil)
	{
		[self logDebugMessage:@"behaviour not found, allocting new behaviour for this game object" atLevel:5];
		
		b=[NSClassFromString(behName) alloc];
		[b initWithGameObject:self withData:data];
		[behaviours addObject:b];
        
	}

	
}
-(void)addBehaviour:(DWBehaviour*)behaviour
{
    [behaviours addObject:behaviour];
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
	for(DWBehaviour *b in behaviours)
	{
		[b handleMessage:messageType andPayload:payload];
	}
}
-(void)handleMessage:(DWMessageType)messageType
{
    [self handleMessage:messageType andPayload:nil];
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
	NSLog(@"==================== game object ... localstore follows");
	
	for(NSString *key in [localStore allKeys])
	{
		NSLog(@"%@ == %@", key, [[localStore objectForKey:key] description]);
	}
	
	NSLog(@"...and behviours");
	
	for(DWBehaviour *b in behaviours)
	{
		[b logLocalStore];
	}
}

-(void)logDebugMessage:(NSString *)message atLevel:(int)level
{
	if(level<=DEBUG_LEVEL)
	{
		NSLog(@"%@ lvl%d behaviour debug log: %@", [self description], level, message);
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
