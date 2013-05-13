//
//  SGBtxeObjectNumber.m
//  belugapad
//
//  Created by gareth on 24/09/2012.
//
//

#import "SGBtxeObjectNumber.h"
#import "SGBtxeTextRender.h"
#import "SGBtxeTextBackgroundRender.h"
#import "SGBtxeNumberDotRender.h"
#import "SGBtxeRow.h"
#import "SGBtxeRowLayout.h"
#import "global.h"


@implementation SGBtxeObjectNumber

@synthesize size, position, worldPosition;
@synthesize textRenderComponent;

@synthesize prefixText, suffixText, numberText, numberValue;

@synthesize enabled, interactive, tag, originalPosition;

@synthesize textBackgroundRenderComponent;

@synthesize container;
@synthesize mount;
@synthesize hidden;

@synthesize assetType;

@synthesize targetNumber, usePicker;

@synthesize numberDotRenderComponent;
@synthesize renderAsDots;
@synthesize numberMode;
@synthesize backgroundType;
@synthesize rowWidth;
@synthesize disableTrailingPadding;

@synthesize numerator, denominator, pickerTargetNumerator, pickerTargetDenominator, showAsMixedFraction;

// LogPolling properties
@synthesize logPollId, logPollType;
-(NSString*)logPollType { return @"SGBtxeObjectNumber"; }

// LogPollPositioning properties
@synthesize logPollPosition;
-(CGPoint)logPollPosition { return self.position; }

-(SGBtxeObjectNumber*)initWithGameWorld:(SGGameWorld*)aGameWorld
{
    if(self=[super initWithGameWorld:aGameWorld])
    {
        
        numberValue=@0;
        [numberValue retain];
        
        
        enabled=YES;
        interactive=YES;
        tag=@"";
        
        numberMode=@"numeral";
        
        size=CGSizeZero;
        position=CGPointZero;
        backgroundType=@"Tile";
        
        renderAsDots=NO;
        
        AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
        loggingService = ac.loggingService;
        [loggingService.logPoller registerPollee:(id<LogPolling>)self];
        
        textRenderComponent=[[SGBtxeTextRender alloc] initWithGameObject:(SGGameObject*)self];
        textBackgroundRenderComponent=[[SGBtxeTextBackgroundRender alloc] initWithGameObject:(SGGameObject*)self];
        
        numberDotRenderComponent=[[SGBtxeNumberDotRender alloc] initWithGameObject:(SGGameObject*)self];
        
    }
    
    return self;
}

-(id<MovingInteractive>)createADuplicateIntoGameWorld:(SGGameWorld *)destGW
{
    //creates a duplicate object text -- something else will need to call setupDraw and attachToRenderBase
    
    SGBtxeObjectNumber *dupe=[[[SGBtxeObjectNumber alloc] initWithGameWorld:destGW] autorelease];
    
    dupe.position=self.position;
    dupe.tag=[[self.tag copy] autorelease];
    dupe.enabled=self.enabled;
    dupe.prefixText=[[self.prefixText copy] autorelease];
    dupe.numberText=[[self.numberText copy] autorelease];
    dupe.suffixText=[[self.suffixText copy] autorelease];
    dupe.assetType=self.assetType;
    dupe.renderAsDots=self.renderAsDots;
    dupe.backgroundType=self.backgroundType;
    dupe.numberValue=self.numberValue;
    
    if(self.numerator) dupe.numerator=[[self.numerator copy] autorelease];
    if(self.denominator) dupe.denominator=[[self.denominator copy] autorelease];
    if(self.pickerTargetNumerator) dupe.pickerTargetNumerator=[[self.pickerTargetNumerator copy] autorelease];
    if(self.pickerTargetDenominator) dupe.pickerTargetDenominator=[[self.pickerTargetDenominator copy] autorelease];
    dupe.showAsMixedFraction=self.showAsMixedFraction;
    
    return (id<MovingInteractive>)dupe;
}

-(id<MovingInteractive>)createADuplicate
{
    return [self createADuplicateIntoGameWorld:gameWorld];
}

-(void)setNumberMode:(NSString *)theNumberMode
{
    if(numberMode==theNumberMode)return;
    if(numberMode)[numberMode release];
    numberMode=theNumberMode;
    [numberMode retain];
    
    numberMode=theNumberMode;
    
    if([theNumberMode isEqualToString:@"numicon"])
        renderAsDots=YES;
    else
        renderAsDots=NO;
}

-(NSString*)numberMode
{
    return numberMode;
}

-(void)changeVisibility:(BOOL)visibility
{
    [numberDotRenderComponent changeVisibility:visibility];
}

-(void)handleMessage:(SGMessageType)messageType
{
    
}

-(void)doUpdate:(ccTime)delta
{
    
}

-(NSNumber*)value
{
    if(numberValue)return numberValue;
    else return @0;
}


-(NSString*)numberText
{
    return numberText;
}

-(void)setNumberText:(NSString *)theNumberText
{
    if(numberText) [numberText release];
    
    numberText=theNumberText;
    [numberText retain];
    
    NSNumberFormatter *nf=[[NSNumberFormatter alloc] init];
    [nf setNumberStyle:NSNumberFormatterDecimalStyle];
    self.numberValue=[nf numberFromString:numberText];
    [nf release];
    
    self.tag=[numberValue stringValue];
}

-(void)setNumberValue:(NSNumber *)theNumberValue
{
    if(numberValue==theNumberValue) return;
    
    NSNumber *oldVal=numberValue;
    numberValue=[theNumberValue retain];
    [oldVal release];
    
    self.tag=[numberValue stringValue];
}

-(NSNumber*)numberValue
{
    return numberValue;
}

-(void)setText:(NSString *)text
{
    if(!text) return;
    
    //split text into parts if passed to this method
    
    BOOL hadPoint=NO, hadStart=NO, hadEnd=NO;
    NSString *seek=@"0123456789";
    
    //strip commas
//    NSString *parse=[text stringByReplacingOccurrencesOfString:@"," withString:@""];
    
    NSString *parse=text;
    
    int nStart=0; // assume number starts at start
    int nEnd=[parse length]-1; //assume number end at end
    
    for(int i=0; i<parse.length; i++)
    {
        NSRange rngMatch={i,0};
        if([seek rangeOfString:[parse substringWithRange:rngMatch]].location != NSNotFound)
        {
            if(!hadStart)
            {
                //start of the string
                nStart=i;
                hadStart=YES;
            }
            //otherwise, continue (inside of string
        }
        else if([[parse substringWithRange:rngMatch] isEqualToString:@"."])
        {
            if(hadStart && !hadEnd && !hadPoint)
            {
                //point inside of a string
                hadPoint=YES;
            }
            else if (hadStart && !hadEnd && hadPoint)
            {
                //in the number, second point >> bail
                nEnd=i;
                hadEnd=YES;
            }
        }
        else
        {
            //not a number or a point
            if(hadStart && !hadEnd)
            {
                //break the number here
                hadEnd=YES;
                nEnd=i;
            }
            
        }
    }
    
    if(nStart>0) self.prefixText=[parse substringToIndex:nStart];
    self.numberText=[parse substringWithRange:NSMakeRange(nStart, nEnd+1)];
    if(nEnd<[parse length]-1) self.suffixText=[parse substringFromIndex:nEnd];
    [self updateDraw];
    NSNumberFormatter *nf=[[NSNumberFormatter alloc] init];
    [nf setNumberStyle:NSNumberFormatterDecimalStyle];
    self.numberValue=[nf numberFromString:numberText];
    
    [self redrawBkg];
    
    [nf release];
    
    self.tag=[numberValue stringValue];
}

-(void)updateDraw
{
    [self.textRenderComponent updateLabel];
    
    if(self.renderAsDots)
        [self.numberDotRenderComponent updateDraw];
}

-(NSString*)text
{
    if(usePicker && !numberValue)
    {
        if(self.pickerTargetNumerator)
        {
            if(!self.numerator && !self.denominator) return @"?/?";
            else if(self.numerator) return [NSString stringWithFormat:@"%d/?", [self.numerator integerValue]];
            else if(self.denominator) return [NSString stringWithFormat:@"?/%d", [self.denominator integerValue]];
        }
        else return @"?";
    }
    
    if(self.numerator && self.showAsMixedFraction==NO) return [NSString stringWithFormat:@"%d/%d", [self.numerator integerValue], [self.denominator integerValue]];
    
    else if(self.numerator && self.showAsMixedFraction==YES)
    {
        int whole=(int)([self.numerator integerValue] / [self.denominator integerValue]);
        int modtop=[self.numerator integerValue] - (whole * [self.denominator integerValue]);
        return [NSString stringWithFormat:@"%d %d/%d", whole, modtop, [self.denominator integerValue]];
    }

    else
    {
        NSString *ps=prefixText;
        if(!ps)ps=@"";
        NSString *ss=suffixText;
        if(!ss)ss=@"";
        
        return [NSString stringWithFormat:@"%@%@%@", ps, numberText, ss];
    }
}

-(BOOL)enabled
{
    return enabled;
}

-(void)setEnabled:(BOOL)theEnabled
{
    enabled=theEnabled;
}

-(CGPoint)worldPosition
{
    return [renderBase convertToWorldSpace:self.position];
}

-(void)setWorldPosition:(CGPoint)theWorldPosition
{
    self.position=[renderBase convertToNodeSpace:theWorldPosition];
}

-(void)setColourOfBackgroundTo:(ccColor3B)thisColour
{
    [self.textBackgroundRenderComponent setColourOfBackgroundTo:thisColour];
    
    // no equivilent for number dots
}

-(void)setPosition:(CGPoint)thePosition
{
    position=thePosition;
    
    [self.textRenderComponent updatePosition:position];
    [self.textBackgroundRenderComponent updatePosition:position];
    
    [self.numberDotRenderComponent updatePosition:position];
}

-(void)inflateZIndex
{
    [self.textRenderComponent inflateZindex];
    [self.numberDotRenderComponent inflateZindex];
    
}
-(void)deflateZindex
{
    [self.textRenderComponent deflateZindex];
    [self.numberDotRenderComponent deflateZindex];
}

-(void)fadeInElementsFrom:(float)startTime andIncrement:(float)incrTime
{
    [textRenderComponent fadeInElementsFrom:startTime andIncrement:incrTime];
    [textBackgroundRenderComponent fadeInElementsFrom:startTime andIncrement:incrTime];
    
    [numberDotRenderComponent fadeInElementsFrom:startTime andIncrement:incrTime];
}

-(void)attachToRenderBase:(CCNode*)theRenderBase;
{
    if(self.hidden)return;
    
    renderBase=theRenderBase;
    
    if(textBackgroundRenderComponent.backgroundNode)
        [renderBase addChild:textBackgroundRenderComponent.backgroundNode];
    
    if(self.renderAsDots)
    {
        [renderBase addChild:numberDotRenderComponent.baseNode];
    }
    else
    {
        [renderBase addChild:textRenderComponent.label0];
        [renderBase addChild:textRenderComponent.label];
    }
}

-(void)tagMyChildrenForIntro
{
    [textRenderComponent.label setTag:3];
    [textRenderComponent.label0 setTag:3];
    [textRenderComponent.label setOpacity:0];
    [textRenderComponent.label0 setOpacity:0];
    [textBackgroundRenderComponent tagMyChildrenForIntro];
    
    for(CCSprite *s in self.numberDotRenderComponent.baseNode.children)
    {
        s.opacity=0;
        s.tag=3;
    }
}

-(void)setupDraw
{
    if(self.hidden)return;
    
    textRenderComponent.useTheseAssets=self.assetType;
    
    // text mode
    self.textRenderComponent.useAlternateFont=YES;
    [self.textRenderComponent setupDraw];
    
    
    //don't show the label if it's not enabled
    if(!self.enabled)
    {
        textRenderComponent.label.visible=NO;
        textRenderComponent.label0.visible=NO;
    }
    
    
    if(self.renderAsDots)
    {
        [self.numberDotRenderComponent setupDraw];
        self.size=self.numberDotRenderComponent.size;
    }
    else
    {
        //set size to size of cclabelttf plus the background overdraw size (the background itself is currently stretchy)
        if(self.interactive)
            self.size=CGSizeMake(self.textRenderComponent.label.contentSize.width+BTXE_OTBKG_WIDTH_OVERDRAW_PAD, self.textRenderComponent.label.contentSize.height);
        else
//            self.size=CGSizeMake(self.textRenderComponent.label.contentSize.width+(BTXE_OTBKG_WIDTH_OVERDRAW_PAD/3), self.textRenderComponent.label.contentSize.height);
            self.size=CGSizeMake(self.textRenderComponent.label.contentSize.width, self.textRenderComponent.label.contentSize.height);

    }
    
    if([self.backgroundType isEqualToString:@"Card"] && [self.assetType isEqualToString:@"Large"] && size.width<170)
        size.width=170.0f;
    else if([self.backgroundType isEqualToString:@"Card"] && [self.assetType isEqualToString:@"Medium"] && size.width<116)
        size.width=116;
    else if([self.backgroundType isEqualToString:@"Card"] && [self.assetType isEqualToString:@"Smaller"] && size.width<40)
        size.width=40;

    //background sprite to text (using same size)
    [textBackgroundRenderComponent setupDrawWithSize:self.size];
}

-(NSString*)returnMyText
{
    return self.text;
}

-(CGRect)returnBoundingBox
{
    return CGRectZero;
}

-(void)actOnTap
{
    return;
}

-(void)redrawBkg
{
    CGSize toThisSize=CGSizeMake(self.textRenderComponent.label.contentSize.width+BTXE_OTBKG_WIDTH_OVERDRAW_PAD, self.textRenderComponent.label.contentSize.height);
    
    self.size=toThisSize;
    
    [textBackgroundRenderComponent redrawBkgWithSize:toThisSize];
//    id<Containable>myMount=(id<Containable>)self.mount;
    SGBtxeRow *myRow=(SGBtxeRow*)self.container;
    SGBtxeRowLayout *layoutComp=myRow.rowLayoutComponent;
    
    [layoutComp layoutChildren];
}

-(void)destroy
{
    [loggingService.logPoller unregisterPollee:(id<LogPolling>)self];
    [self detachFromRenderBase];
    
    [gameWorld delayRemoveGameObject:self];
}

-(void)detachFromRenderBase
{
    [textBackgroundRenderComponent.backgroundNode removeFromParentAndCleanup:YES];
    [textRenderComponent.label0 removeFromParentAndCleanup:YES];
    [textRenderComponent.label removeFromParentAndCleanup:YES];
    
    [self.numberDotRenderComponent.baseNode removeFromParentAndCleanup:YES];
}

-(void)activate
{
    self.enabled=YES;
    self.textRenderComponent.label.visible=self.enabled;
    self.textRenderComponent.label0.visible=self.enabled;
    self.numberDotRenderComponent.baseNode.visible=self.enabled;
}

-(void)returnToBase
{
    self.position=self.originalPosition;
}

-(void)dealloc
{
    self.text=nil;
    self.textRenderComponent=nil;
    self.numberDotRenderComponent=nil;
    
    self.prefixText=nil;
    self.numberText=nil;
    self.suffixText=nil;
    self.numberValue=nil;
    self.container=nil;
    self.logPollId = nil;
    if (logPollId) [logPollId release];
    logPollId = nil;

    [super dealloc];
}

@end
