//
//  BNLineRamblerInput.m
//  belugapad
//
//  Created by Gareth Jenkins on 13/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BNLineRamblerInput.h"

@implementation BNLineRamblerInput

-(BNLineRamblerInput *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BNLineRamblerInput*)[super initWithGameObject:aGameObject withData:data];
    
    return self;
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{

    if(messageType==kDWsetupStuff)
    {

    }
}

-(void)doUpdate:(ccTime)delta
{


}



@end
