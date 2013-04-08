//
//  SGFBuilderRowRender.m
//  belugapad
//
//  Created by David Amphlett on 08/04/2013.
//
//

#import "SGFBuilderRowRender.h"
#import "SGComponent.h"
#import "global.h"

@implementation SGFBuilderRowRender

-(SGFBuilderRowRender*)initWithGameObject:(id<Row,RenderedObject, Touchable>)aGameObject
{
    if(self=[super initWithGameObject:(SGGameObject*)aGameObject])
    {
        ParentGO=aGameObject;
    }
    
    return self;
}

-(void)setupSprite
{
    if(ParentGO.MySprite)return;
    
    CCSprite *s=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/fractions/fraction.png")];
    s.position=ParentGO.Position;
    [ParentGO.RenderLayer addChild:s];
    
    if(!ParentGO.DenominatorUpButton)
    {
        CCSprite *upBtn=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/fractions/denominatorbtn.png")];
        
        [upBtn setPosition:ccp(-50,(s.contentSize.height/2)+25)];
        [s addChild:upBtn];
        
        ParentGO.DenominatorUpButton=upBtn;
    }
    if(!ParentGO.DenominatorDownButton)
    {
        CCSprite *downBtn=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/fractions/denominatorbtn.png")];
        [downBtn setPosition:ccp(-50,(s.contentSize.height/2)-25)];
        [downBtn setRotation:180];
        [s addChild:downBtn];
        ParentGO.DenominatorDownButton=downBtn;
    }

    
    ParentGO.MySprite=s;
    
}

@end
