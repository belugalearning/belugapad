//
//  SGJmapCloudRender.m
//  belugapad
//
//  Created by gareth on 13/09/2012.
//
//

#import "SGJmapCloudRender.h"
#import "SGJMapCloud.h"
#import "global.h"

#define ENABLE NO

@implementation SGJmapCloudRender

-(SGJmapCloudRender*)initWithGameObject:(SGJmapCloud*)aGameObject
{
    if(self=[super initWithGameObject:(SGGameObject*)aGameObject])
    {
        parentGO=aGameObject;
    }
    
    return self;
}

-(void)setupParticle
{
    particle=[CCParticleSystemQuad particleWithFile:BUNDLE_FULL_PATH(@"/images/jmap/cloud1.plist")];
    [parentGO.particleRenderLayer addChild:particle z:3];
    [particle setPosition:parentGO.Position];
    [particle setScaleX:2.0f];
    [particle setScaleY:1.5f];
    
//    [particle setVisible:parentGO.Visible];
    [particle setVisible:YES];
}

-(void)handleMessage:(SGMessageType)messageType
{
//    if(messageType==kSGvisibilityChanged)
//    {
//        particle.visible=parentGO.Visible;
//    }
//    if(messageType==kSGzoomIn)
//    {
//        particle.visible=parentGO.Visible;
//    }
//    if(messageType==kSGzoomOut)
//    {
//        particle.visible=NO;
//    }
    
    if(messageType==kSGreadyRender && ENABLE)
    {
        [self setupParticle];
    }
}

@end
