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
        
        float rm=fabsf(ramblerGameObject.TouchXOffset) - fabsf(valueOffset * ramblerGameObject.DefaultSegmentSize);
        
        if(rm> (ramblerGameObject.DefaultSegmentSize / 2.0f))
        {
            if (ramblerGameObject.TouchXOffset>0) {
                valueOffset -= ramblerGameObject.CurrentSegmentValue;
            }
            else {
                valueOffset += ramblerGameObject.CurrentSegmentValue;
            }
        }
        
        int valueSign=1;
        if(valueOffset<0)valueSign=-1;
        
        //do value stitching assessment without signing
        valueOffset=abs(valueOffset);
        
        //adjust value offset to auto stitching
        if(ramblerGameObject.AutoStitchIncrement>0)
        {
            if(valueOffset>ramblerGameObject.AutoStitchIncrement)
            {
                //snap back to value offset
                valueOffset=ramblerGameObject.AutoStitchIncrement;
            }
            else {
//                float valueProp=fabsf(ramblerGameObject.TouchXOffset) / ((float)ramblerGameObject.AutoStitchIncrement * ramblerGameObject.DefaultSegmentSize);

                if(fabsf(ramblerGameObject.TouchXOffset) >= ((float)ramblerGameObject.AutoStitchIncrement - 0.5f) * ramblerGameObject.DefaultSegmentSize)
                {
                    //snap forward
                    valueOffset=ramblerGameObject.AutoStitchIncrement;
                }
                else {
                    //snap back to no offset
                    valueOffset=0;
                }
            }
        }
        
        //re-sign offset now stitching assessment is done
        valueOffset=valueOffset*valueSign;
                
        int newValue=ramblerGameObject.Value+valueOffset;
        
        if (ramblerGameObject.MaxValue && newValue > [ramblerGameObject.MaxValue intValue]) newValue=[ramblerGameObject.MaxValue intValue];
        if (ramblerGameObject.MinValue && newValue < [ramblerGameObject.MinValue intValue]) newValue=[ramblerGameObject.MinValue intValue];
        
        ramblerGameObject.Value=newValue;
        
        [[gameObject gameWorld] handleMessage:kDWdoSelection andPayload:nil withLogLevel:0];
    }
    
}

-(void)doUpdate:(ccTime)delta
{


}



@end
