//
//  SGJmapCloud.m
//  belugapad
//
//  Created by gareth on 13/09/2012.
//
//

#import "SGJmapCloud.h"

#import "SGJmapCloudRender.h"
#import "SGJmapCloudSeeker.h"
#import "SGJmapCloudMotion.h"

@implementation SGJmapCloud

@synthesize Position, RenderBatch;
@synthesize Visible, ProximityEvalComponent;
@synthesize particleRenderLayer;

-(SGJmapCloud*)initWithGameWorld:(SGGameWorld*)aGameWorld andRenderBatch:(CCSpriteBatchNode*)aRenderBatch andPosition:(CGPoint)aPosition
{
    if(self=[super initWithGameWorld:aGameWorld])
    {
        self.RenderBatch=aRenderBatch;
        Position=aPosition;
        self.Visible=NO;
        
        _seekerComponent=[[SGJmapCloudSeeker alloc] initWithGameObject:self];
        _renderComponent=[[SGJmapCloudRender alloc] initWithGameObject:self];
        _motionComponent=[[SGJmapCloudMotion alloc] initWithGameObject:self];
    }
    
    return self;
}

-(void)handleMessage:(SGMessageType)messageType
{
//    [self.seekerComponent handleMessage:messageType];
//    [self.motionComponent handleMessage:messageType];
    [self.renderComponent handleMessage:messageType];
}

-(void)doUpdate:(ccTime)delta
{
    
}

-(void)dealloc
{
    self.seekerComponent=nil;
    self.renderComponent=nil;
    self.motionComponent=nil;
    
    [super dealloc];
}

@end
