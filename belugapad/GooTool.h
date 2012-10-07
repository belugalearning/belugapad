

#import "DWGameObject.h"
#import "ToolConsts.h"
#import "ToolScene.h"

#import "ObjectiveChipmunk.h"

@interface GooTool : ToolScene
{
    // required toolhost stuff
    ToolHost *toolHost;
    
    // default positional bits
    CGPoint winL;
    float cx, cy, lx, ly;
    
    ChipmunkSpace *cSpace;
    ChipmunkMultiGrab *cGrab;
}

-(void)readPlist:(NSDictionary*)pdef;
-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;
-(float)metaQuestionTitleYLocation;
-(float)metaQuestionAnswersYLocation;

@end
