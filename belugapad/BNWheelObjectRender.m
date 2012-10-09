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

//CCPickerView
#define kComponentWidth 54
#define kComponentHeight 32
#define kComponentSpacing 0

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
    
    //init pos x & y in case they're not set elsewhere
    
    return self;
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kDWsetupStuff)
    {
        if(!w.pickerView)
        {
            [self setupNumberWheel];
        }
    }
    
    if(messageType==kDWupdateObjectData)
    {
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
        
    }
    
    if(messageType==kDWupdateLabels)
    {
        [w.Label setPosition:ccp(w.Position.x-150,w.Position.y)];
    }
    
    if(messageType==kDWdismantle)
    {
        [[w.mySprite parent] removeChild:w.mySprite cleanup:YES];
    }
    
    
}



-(void)setSprite
{
    NSString *spriteFileName=[[[NSString alloc]init] autorelease];
    
    if(w.SpriteFileName)
        spriteFileName=w.SpriteFileName;
    
    else
        spriteFileName=[NSString stringWithFormat:@"/images/piesplitter/slice.png"];
    
    [self setupNumberWheel];
    
    
    
    
}
-(void)moveSprite
{

    
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
    if(!w.pickerViewSelection)w.pickerViewSelection=[[[NSMutableArray alloc]init]retain];
    
    if(pickerView) return;
    
    pickerView = [CCPickerView node];
    pickerView.position = w.Position;
    pickerView.dataSource = self;
    pickerView.delegate = self;
    [pickerView autoRepeatNodes:YES];
    
    w.pickerView=pickerView;
    
    for(int i=0;i<w.Components;i++)
        [w.pickerViewSelection addObject:[NSNumber numberWithInt:0]];
    
    
    [w.RenderLayer addChild:pickerView z:20];
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
    
    return numRows;
}

- (CGFloat)pickerView:(CCPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
    return kComponentHeight;
}

- (CGFloat)pickerView:(CCPickerView *)pickerView widthForComponent:(NSInteger)component {
    return kComponentWidth;
}

- (NSString *)pickerView:(CCPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return @"Not used";
}

- (CCNode *)pickerView:(CCPickerView *)pickerView nodeForRow:(NSInteger)row forComponent:(NSInteger)component reusingNode:(CCNode *)node {
    
    CCLabelTTF *l=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", row]fontName:@"Chango" fontSize:24];
    return l;
    
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
    
    if(w.AssociatedGO)
    {
        w.OutputValue=[self returnPickerNumber];
        [w.AssociatedGO handleMessage:kDWupdateObjectData];
    }
    
    NSLog(@"didSelect row = %d, component = %d, totSum = %d", row, component, [self returnPickerNumber]);
    
}

- (CGFloat)spaceBetweenComponents:(CCPickerView *)pickerView {
    return kComponentSpacing;
}

- (CGSize)sizeOfPickerView:(CCPickerView *)pickerView {
    CGSize size = CGSizeMake(42, 100);
    
    return size;
}

- (CCNode *)overlayImage:(CCPickerView *)pickerView {
    CCSprite *sprite = [CCSprite spriteWithFile:BUNDLE_FULL_PATH(w.SpriteFileName)];
    return sprite;
}

- (void)onDoneSpinning:(CCPickerView *)pickerView component:(NSInteger)component {
    
    // this is the method called when a component stops spinning
    //NSLog(@"Component %d stopped spinning.", component);
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

-(void) dealloc
{
    [super dealloc];
}

@end
