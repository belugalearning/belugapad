//
//  BNWheelObjectRender.m
//  belugapad
//
//  Created by David Amphlett on 08/10/2012.
//
//

#import "BNWheelObjectRender.h"
#import "DWNWheelGameObject.h"
#import "global.h"
#import "ToolConsts.h"
#import "BLMath.h"
#import "DWGameObject.h"
#import "DWGameWorld.h"
#import "AppDelegate.h"
#import "UsersService.h"
#import "DotGrid.h"
#import "DWDotGridAnchorGameObject.h"
#import "DWDotGridShapeGameObject.h"
#import "DWDotGridTileGameObject.h"

@interface BNWheelObjectRender()
{
@private
    ContentService *contentService;
    UsersService *usersService;
}

@end

@implementation BNWheelObjectRender
@synthesize pickerView;

-(BNWheelObjectRender *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BNWheelObjectRender*)[super initWithGameObject:aGameObject withData:data];
    w=(DWNWheelGameObject*)gameObject;
    
    AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
    contentService = ac.contentService;
    usersService = ac.usersService;
    w.ComponentHeight=62;
    w.ComponentWidth=71;
    w.ComponentSpacing=6;
    
    //init pos x & y in case they're not set elsewhere
    
    return self;
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kDWsetupStuff)
    {
        if(!w.pickerView)
        {
            [self setSprite];
        }
    }
    
    if(messageType==kDWmoveSpriteToPosition)
    {
        [self moveSprite];
    }
    
    if(messageType==kDWupdateObjectData)
    {
        
        if(w.InputValue==[self returnPickerNumber])return;
        
        NSString *strInput=[NSString stringWithFormat:@"%d", w.InputValue];
        
//        [w.pickerViewSelection removeAllObjects];
        
        int thisComponent=w.Components-1;
        
        for(int i=[strInput length]-1;i>=0;i--)
        {
            NSString *thisStr=[NSString stringWithFormat:@"%c",[strInput characterAtIndex:i]];
            int thisInt=[thisStr intValue];
            
            [w.pickerViewSelection replaceObjectAtIndex:thisComponent withObject:[NSNumber numberWithInt:thisInt]];
            
//            [w.pickerViewSelection addObject:[NSNumber numberWithInt:thisInt]];
            [w.pickerView spinComponent:thisComponent speed:15 easeRate:5 repeat:1 stopRow:thisInt];
            thisComponent--;
        }
      
        if([strInput length]<w.Components)
        {
            int untouchedComponents=0;
            untouchedComponents=(w.Components)-[strInput length];
            
            
            for(int i=untouchedComponents;i>0;i--)
            {
                [w.pickerViewSelection replaceObjectAtIndex:thisComponent withObject:[NSNumber numberWithInt:0]];
                [w.pickerView spinComponent:thisComponent speed:15 easeRate:5 repeat:1 stopRow:0];
                thisComponent--;
            }
        }
        
        if(w.HasCountBubble)
        {
            [w.CountBubbleLabel setString:[NSString stringWithFormat:@"%d",[self returnPickerNumber]]];
        }
        
        w.OutputValue=w.InputValue;
        w.StrOutputValue=[NSString stringWithFormat:@"%d",w.InputValue];

    }
    
    if(messageType==kDWupdateLabels)
    {
        if(w.Label)[w.Label setPosition:ccp(w.Position.x-150,w.Position.y)];
        if(w.CountBubble)[w.CountBubble setPosition:[self createCountBubblePos]];
    }
    
    if(messageType==kDWdismantle)
    {
        [[w.mySprite parent] removeChild:w.mySprite cleanup:YES];
        [[w.Label parent] removeChild:w.Label cleanup:YES];
        [[w.CountBubble parent] removeChild:w.CountBubble cleanup:YES];
        [w.CountBubble removeFromParentAndCleanup:YES];
        [w.CountBubbleLabel removeFromParentAndCleanup:YES];
        w.AssociatedGO=nil;

        
        if([gameWorld.GameScene isKindOfClass:[DotGrid class]])
            [(DotGrid*)gameWorld.GameScene removeDeadWheel:w];
        
        [w.pickerView removeFromParentAndCleanup:YES];


        
        [gameWorld delayRemoveGameObject:w];

    }
    
    
}



-(void)setSprite
{

    if(w.HasCountBubble)
    {
        w.CountBubble=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/dotgrid/DG_counter_multiplication.png")];
        [w.CountBubble setPosition:[self createCountBubblePos]];
        w.CountBubbleLabel=[CCLabelTTF labelWithString:@"" fontName:SOURCE fontSize:25.0f];
        [w.CountBubbleLabel setPosition:ccp(49,18)];
        [w.CountBubbleRenderLayer addChild:w.CountBubble];
        [w.CountBubble addChild:w.CountBubbleLabel];
    }
    
    [self setupNumberWheel];
    
    
    
    
}
-(void)moveSprite
{
    [w.pickerView setPosition:w.Position];

    
}
-(void)moveSpriteHome
{

}
-(void)handleTap
{
}


#pragma mark - CCPickerView for number wheel

-(void)setupNumberWheel
{
    if(!w.pickerViewSelection)w.pickerViewSelection=[[[NSMutableArray alloc]init] autorelease];
    
    if(pickerView) return;
    
    pickerView = [CCPickerView node];
    pickerView.position = w.Position;
    pickerView.dataSource = self;
    pickerView.delegate = self;
    [pickerView autoRepeatNodes:YES];
    [pickerView setLocked:w.Locked];
    
    w.pickerView=pickerView;
        
    for(int i=0;i<w.Components;i++)
        [w.pickerViewSelection addObject:[NSNumber numberWithInt:0]];
    
    
    [w.RenderLayer addChild:pickerView z:20];

}

-(CGPoint)createCountBubblePos
{
    if(w.AssociatedGO)
    {
        DWDotGridShapeGameObject *s=nil;
        
        if([w.AssociatedGO isKindOfClass:[DWDotGridShapeGameObject class]])
            s=(DWDotGridShapeGameObject*)w.AssociatedGO;
        CGPoint total=CGPointZero;
        float lowest=0.0f;
        int tileSize=0;
        BOOL setLowest=NO;
        
        for (DWDotGridTileGameObject *t in s.tiles) {
            total=[BLMath AddVector:t.Position toVector:total];
            if(!setLowest){
                lowest=t.Position.y;
                tileSize=t.tileSize;
                setLowest=YES;
            }
            else if(setLowest && t.Position.y<lowest)
            {
                lowest=t.Position.y;
            }
        }
        
        CGPoint avgPos=ccp(total.x/[s.tiles count], lowest-tileSize);
        
        return avgPos;
    }
    else
    {
        return CGPointZero;
    }
}

#pragma mark CCPickerView delegate methods

- (NSInteger)numberOfComponentsInPickerView:(CCPickerView *)pickerView {
    return w.Components;
}

- (NSInteger)pickerView:(CCPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    
    NSInteger numRows = 0;
    
    switch (component) {
        case 0:
            numRows = 10;
            if(w.HasDecimals)numRows = 11;
            if(w.HasNegative)numRows = 12;
            break;
        case 1:
            numRows = 10;
            break;
        case 2:
            numRows=10;
            break;
        case 3:
            numRows=10;
            break;
        case 4:
            numRows=10;
            break;
        case 5:
            numRows=10;
            break;
        case 6:
            numRows=10;
            break;
        case 7:
            numRows=10;
            break;
        case 8:
            numRows=10;
            break;
        case 9:
            numRows=10;
            break;
        case 10:
            numRows=10;
            break;
        default:
            break;
    }
    
    if(component>0 && w.HasDecimals && component<(w.Components-1))
        numRows++;
    
    
    
    return numRows;
}

- (CGFloat)pickerView:(CCPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
    return w.ComponentHeight;
}

- (CGFloat)pickerView:(CCPickerView *)pickerView widthForComponent:(NSInteger)component {
    return w.ComponentWidth;
}

- (NSString *)pickerView:(CCPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return @"Not used";
}

- (CCNode *)pickerView:(CCPickerView *)pickerView nodeForRow:(NSInteger)row forComponent:(NSInteger)component reusingNode:(CCNode *)node {
    
    if(row<10)
    {
        CCLabelTTF *l=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", row]fontName:@"Chango" fontSize:32];
        [l setColor:ccc3(68,68,68)];
        
        return l;
    }
    else if(row==10)
    {
        CCLabelTTF *l=[CCLabelTTF labelWithString:@"." fontName:@"Chango" fontSize:32];
        [l setColor:ccc3(68,68,68)];
        return l;
    }
    else if(row==11)
    {
        CCLabelTTF *l=[CCLabelTTF labelWithString:@"-" fontName:@"Chango" fontSize:32];
        [l setColor:ccc3(68,68,68)];
        return l;
    }
    
    return nil;
    
    //    temp.color = ccYELLOW;
    //    temp.textureRect = CGRectMake(0, 0, kComponentWidth, kComponentHeight);
    //
    //    NSString *rowString = [NSString stringWithFormat:@"%d", row];
    //    CCLabelBMFont *label = [CCLabelBMFont labelWithString:rowString fntFile:@"bitmapFont.fnt"];
    //    label.position = ccp(kComponentWidth/2, kComponentHeight/2-5);
    //    [temp addChild:label];
    //    return temp;
    
}

- (void)pickerView:(CCPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    
    [w.pickerViewSelection replaceObjectAtIndex:component withObject:[NSNumber numberWithInteger:row]];


        w.OutputValue=[self returnPickerNumber];
        w.StrOutputValue=[self returnPickerNumberString];
    
    
    if(w.AssociatedGO)
    {
        w.OutputValue=[self returnPickerNumber];
        [w.AssociatedGO handleMessage:kDWupdateObjectData];
        [w.AssociatedGO handleMessage:kDWupdateLabels];
    }
    
    if([gameWorld.GameScene isKindOfClass:[DotGrid class]])
    {
        DotGrid *dgScene=(DotGrid*)gameWorld.GameScene;
        [dgScene updateSumWheel];
    }
    
    NSLog(@"didSelect row = %d, component = %d, totSum = %d", row, component, [self returnPickerNumber]);
    
}

- (CGFloat)spaceBetweenComponents:(CCPickerView *)pickerView {
    return w.ComponentSpacing;
}

- (CGSize)sizeOfPickerView:(CCPickerView *)pickerView {
    CGSize size = CGSizeMake(42, 100);
    
    return size;
}

- (CCNode *)underlayImage:(CCPickerView *)pickerView {
    CCSprite *sprite = [CCSprite spriteWithFile:BUNDLE_FULL_PATH(w.UnderlaySpriteFileName)];
    return sprite;
}

- (CCNode *)overlayImage:(CCPickerView *)pickerView {
    CCSprite *sprite = [CCSprite spriteWithFile:BUNDLE_FULL_PATH(w.SpriteFileName)];
    return sprite;
}

- (void)onDoneSpinning:(CCPickerView *)pickerView component:(NSInteger)component {
    
    // this is the method called when a component stops spinning
    //NSLog(@"Component %d stopped spinning.", component);
}

-(float)returnBaseOfNumber:(int)pickerSelectionIndex
{
    int adjustedIndex=(pickerSelectionIndex-[w.pickerViewSelection count]);
    
    return pow((double)10,adjustedIndex);
}

-(int)returnPickerNumber
{
    int retNum=0;
    int power=0;
    
    for(int i=[w.pickerViewSelection count]-1;i>=0;i--)
    {
        NSNumber *n=[w.pickerViewSelection objectAtIndex:i];
        int thisNum=[n intValue];
        thisNum=thisNum*(pow((double)10,power));
        retNum+=thisNum;
        power++;
    }
    
    return retNum;
}

-(NSString*)returnPickerNumberString
{
    NSString *fullNum=@"";
    
    for(int i=0;i<[w.pickerViewSelection count];i++)
    {
        int n=[[w.pickerViewSelection objectAtIndex:i]intValue];
        
        if(n<10)
        {
            fullNum=[NSString stringWithFormat:@"%@%d", fullNum, n];
        }
        else if(n==10)
        {
            fullNum=[NSString stringWithFormat:@"%@.", fullNum];
        }
        else if(n==11)
        {
            fullNum=[NSString stringWithFormat:@"%@-", fullNum];
        }
        
    }
    
    return fullNum;
}

-(void) dealloc
{
    [super dealloc];
}

@end
