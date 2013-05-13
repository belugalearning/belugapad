//
//  NumberWheel.m
//  belugapad
//
//  Created by David Amphlett on 12/05/2013.
//
//

#import "NumberWheel.h"
#import "global.h"
#import "SGBtxeProtocols.h"
#import "SGBtxeObjectNumber.h"

@implementation NumberWheel

@synthesize mySprite;
@synthesize SpriteFileName;
@synthesize Position;
@synthesize RenderLayer;
@synthesize pickerViewSelection;
@synthesize pickerView;
@synthesize Components;
@synthesize InputValue;
@synthesize OutputValue;
@synthesize StrOutputValue;
@synthesize Label;
@synthesize Locked;
@synthesize HasDecimals;
@synthesize HasNegative;
@synthesize ComponentHeight;
@synthesize ComponentWidth;
@synthesize ComponentSpacing;
@synthesize UnderlaySpriteFileName;
@synthesize AssociatedObject;
@synthesize fractionPart;
@synthesize fractionWheel;

-(NumberWheel *)init //WithRenderlayer:(CCLayer*)renderLayer
{
    self=(NumberWheel*)[super init];
    w=self;
    
    self.ComponentHeight=62;
    self.ComponentWidth=71;
    self.ComponentSpacing=6;
    self.StrOutputValue=nil;
    
    return self;
}


-(void)showNumberWheel
{
    pickerView.visible=true;
}

-(void)hideNumberWheel
{
    pickerView.visible=false;
}

-(void)setupNumberWheel
{
    if(!self.pickerViewSelection)self.pickerViewSelection=[[[NSMutableArray alloc]init] autorelease];
    
    if(pickerView) return;
    
    pickerView = [CCPickerView node];
    pickerView.anchorPoint=ccp(1.0f,0.5f);
    pickerView.position = self.Position;
    pickerView.dataSource = self;
    pickerView.delegate = self;
    [pickerView autoRepeatNodes:YES];
    [pickerView setLocked:self.Locked];
    
    self.pickerView=pickerView;
    
    for(int i=0;i<self.Components;i++)
        [self.pickerViewSelection addObject:[NSNumber numberWithInt:0]];
    
    
    [self.RenderLayer addChild:pickerView z:20];
    
}

#pragma mark CCPickerView delegate methods

- (NSInteger)numberOfComponentsInPickerView:(CCPickerView *)pickerView {
    return self.Components;
}

- (NSInteger)pickerView:(CCPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    
    NSInteger numRows = 0;
    
    switch (component) {
        case 0:
            numRows = 10;
            if(self.HasDecimals)numRows = 11;
            if(self.HasNegative)numRows = 12;
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
    
    if(component>0 && self.HasDecimals)
        numRows++;
    
    
    
    return numRows;
}

- (CGFloat)pickerView:(CCPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
    return self.ComponentHeight;
}

- (CGFloat)pickerView:(CCPickerView *)pickerView widthForComponent:(NSInteger)component {
    return self.ComponentWidth;
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
}

- (void)pickerView:(CCPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    
    [self.pickerViewSelection replaceObjectAtIndex:component withObject:[NSNumber numberWithInteger:row]];
    
    if([AssociatedObject conformsToProtocol:@protocol(NumberPicker)] && [fractionPart isEqualToString:@"n"]){
        
        
//        NSString *otherWheel=@"";
//        
//        
//        if(!fractionWheel.StrOutputValue)
//            otherWheel=@"?";
//        else
//            otherWheel=[NSString stringWithFormat:@"%d",[fractionWheel returnPickerNumber]];
        
        float value=0;
        
        if(fractionWheel.StrOutputValue){
            value=(float)[self returnPickerNumber]/[fractionWheel returnPickerNumber];
            ((id<Value>)AssociatedObject).numberValue=[NSNumber numberWithFloat:value];
        }
        ((id<Value>)AssociatedObject).numerator=[NSNumber numberWithInteger:[self returnPickerNumber]];

        [((SGBtxeObjectNumber*)AssociatedObject) updateDraw];
        
//        NSLog(@"%d/%@ /// %@", [self returnPickerNumber], otherWheel, ((id<Text>)AssociatedObject).text);
        
    }
    else if([AssociatedObject conformsToProtocol:@protocol(NumberPicker)] && [fractionPart isEqualToString:@"d"])
    {
        NSString *otherWheel=@"";
        
//        if(!fractionWheel.StrOutputValue)
//            otherWheel=@"?";
//        else
//            otherWheel=[NSString stringWithFormat:@"%d",[fractionWheel returnPickerNumber]];
//        
        float value=0;
        
        if(fractionWheel.StrOutputValue){
            value=(float)[otherWheel floatValue]/[self returnPickerNumber];
            ((id<Value>)AssociatedObject).numberValue=[NSNumber numberWithFloat:value];
        }
        
        ((id<Value>)AssociatedObject).denominator=[NSNumber numberWithFloat:[self returnPickerNumber]];
        [((SGBtxeObjectNumber*)AssociatedObject) updateDraw];
//        NSLog(@"%@/%d /// %@", otherWheel, [self returnPickerNumber], ((id<Text>)AssociatedObject).text);
    }
    
    self.OutputValue=[self returnPickerNumber];
    self.StrOutputValue=[self returnPickerNumberString];
    
    
    NSLog(@"didSelect row = %d, component = %d, totSum = %d", row, component, [self returnPickerNumber]);
    
}

- (CGFloat)spaceBetweenComponents:(CCPickerView *)pickerView {
    return self.ComponentSpacing;
}

- (CGSize)sizeOfPickerView:(CCPickerView *)pickerView {
    CGSize size = CGSizeMake(42, 100);
    
    return size;
}

- (CCNode *)underlayImage:(CCPickerView *)pickerView {
    CCSprite *sprite = [CCSprite spriteWithFile:BUNDLE_FULL_PATH(self.UnderlaySpriteFileName)];
    return sprite;
}

- (CCNode *)overlayImage:(CCPickerView *)pickerView {
    CCSprite *sprite = [CCSprite spriteWithFile:BUNDLE_FULL_PATH(self.SpriteFileName)];
    return sprite;
}

- (void)onDoneSpinning:(CCPickerView *)pickerView component:(NSInteger)component {
    
    // this is the method called when a component stops spinning
    //NSLog(@"Component %d stopped spinning.", component);
}

-(float)returnBaseOfNumber:(int)pickerSelectionIndex
{
    int adjustedIndex=(pickerSelectionIndex-[self.pickerViewSelection count]);
    
    return pow((double)10,adjustedIndex);
}

-(int)returnPickerNumber
{
    int retNum=0;
    int power=0;
    
    for(int i=[self.pickerViewSelection count]-1;i>=0;i--)
    {
        NSNumber *n=[self.pickerViewSelection objectAtIndex:i];
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
    
    for(int i=0;i<[self.pickerViewSelection count];i++)
    {
        int n=[[self.pickerViewSelection objectAtIndex:i]intValue];
        
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


