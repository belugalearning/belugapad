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
            [self setSprite];
        }
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
    pickerView.position = ccp(21, 560);
    pickerView.dataSource = self;
    pickerView.delegate = self;
    
    w.pickerView=pickerView;
    
    [w.pickerViewSelection addObject:[NSNumber numberWithInt:0]];
    
    
    [w.RenderLayer addChild:w.pickerView z:20];
}

#pragma mark CCPickerView delegate methods

- (NSInteger)numberOfComponentsInPickerView:(CCPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(CCPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    
    NSInteger numRows = 0;
    
    switch (component) {
        case 0:
            numRows = 2;
            break;
        case 1:
            numRows = 2;
            break;
        case 2:
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
    CCSprite *sprite = [CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/numberwheel/FB_OutPut_Pipe__Picker_Overlay.png")];
    return sprite;
}

- (void)onDoneSpinning:(CCPickerView *)pickerView component:(NSInteger)component {
    
    NSLog(@"Component %d stopped spinning.", component);
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
