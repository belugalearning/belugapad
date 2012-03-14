//
//  BNLineRamblerInput.m
//  belugapad
//
//  Created by Gareth Jenkins on 13/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BNLineRamblerInput.h"
#import "DWRamblerGameObject.h"


@implementation BNLineRamblerInput

-(BNLineRamblerInput *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BNLineRamblerInput*)[super initWithGameObject:aGameObject withData:data];
    
    ramblerGameObject=(DWRamblerGameObject*)gameObject;
    
    return self;
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{

    if(messageType==kDWsetupStuff)
    {

    }
    
    else if (messageType==kDWnlineReleaseRamblerAtOffset)
    {
    
        int valueOffset=-ramblerGameObject.TouchXOffset / ramblerGameObject.DefaultSegmentSize;
        
        //look at remainder
        
        float rem=ramblerGameObject.TouchXOffset - (valueOffset * ramblerGameObject.DefaultSegmentSize);
        
        if(-rem > ramblerGameObject.DefaultSegmentSize / 2.0f) 
        {
            valueOffset += ramblerGameObject.CurrentSegmentValue;
        }
        else if(-rem < -(ramblerGameObject.DefaultSegmentSize / 2.0f)) 
        {
            valueOffset -= ramblerGameObject.CurrentSegmentValue;
        }
        
        int newValue=ramblerGameObject.Value+valueOffset;
        
        if (newValue > [ramblerGameObject.MaxValue intValue]) newValue=[ramblerGameObject.MaxValue intValue];
        if (newValue < [ramblerGameObject.MinValue intValue]) newValue=[ramblerGameObject.MinValue intValue];
        
        ramblerGameObject.Value=newValue;
    }
    
}

-(void)doUpdate:(ccTime)delta
{


}



@end
