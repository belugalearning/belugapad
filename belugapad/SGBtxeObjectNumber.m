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
#import "global.h"


@implementation SGBtxeObjectNumber

@synthesize size, position, worldPosition;
@synthesize textRenderComponent;

@synthesize prefixText, suffixText, numberText, numberValue;

@synthesize enabled, tag, originalPosition;

@synthesize textBackgroundRenderComponent;

@synthesize container;
@synthesize mount;
@synthesize hidden;


-(SGBtxeObjectNumber*)initWithGameWorld:(SGGameWorld*)aGameWorld
{
    if(self=[super initWithGameWorld:aGameWorld])
    {
        prefixText=@"";
        numberText=@"";
        suffixText=@"";
        numberValue=@0;
        
        enabled=YES;
        tag=@"";
        
        size=CGSizeZero;
        position=CGPointZero;
        textRenderComponent=[[SGBtxeTextRender alloc] initWithGameObject:(SGGameObject*)self];
        
        textBackgroundRenderComponent=[[SGBtxeTextBackgroundRender alloc] initWithGameObject:(SGGameObject*)self];
        
    }
    
    return self;
}

-(id<MovingInteractive>)createADuplicate
{
    //creates a duplicate object text -- something else will need to call setupDraw and attachToRenderBase
    
    SGBtxeObjectNumber *dupe=[[[SGBtxeObjectNumber alloc] initWithGameWorld:gameWorld] autorelease];
    
    dupe.position=self.position;
    dupe.tag=[[self.tag copy] autorelease];
    dupe.enabled=self.enabled;
    
    dupe.prefixText=[[self.prefixText copy] autorelease];
    dupe.numberText=[[self.numberText copy] autorelease];
    dupe.suffixText=[[self.suffixText copy] autorelease];
    
    return (id<MovingInteractive>)dupe;
}

-(void)handleMessage:(SGMessageType)messageType
{
    
}

-(void)doUpdate:(ccTime)delta
{
    
}

-(NSNumber*)value
{
    return numberValue;
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
    if(numberValue)[numberValue release];
    
    numberValue=theNumberValue;
    [numberValue retain];
    
    
    self.tag=[numberValue stringValue];
}

-(NSNumber*)numberValue
{
    return numberValue;
}

-(void)setText:(NSString *)text
{
    //split text into parts if passed to this method
    
    BOOL hadPoint=NO, hadStart=NO, hadEnd;
    NSString *seek=@"0123456789";
    
    //strip commas
    NSString *parse=[text stringByReplacingOccurrencesOfString:@"," withString:@""];
    
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
    
    if(nStart>0) prefixText=[parse substringToIndex:nStart];
    numberText=[parse substringWithRange:NSMakeRange(nStart, nEnd+1)];
    if(nEnd<[parse length]-1) suffixText=[parse substringFromIndex:nEnd];
    
    NSNumberFormatter *nf=[[NSNumberFormatter alloc] init];
    [nf setNumberStyle:NSNumberFormatterDecimalStyle];
    self.numberValue=[nf numberFromString:numberText];
    [nf release];
    
    self.tag=[numberValue stringValue];
}

-(NSString*)text
{
    NSString *ps=prefixText;
    if(!ps)ps=@"";
    NSString *ss=suffixText;
    if(!ss)ss=@"";
    
    return [NSString stringWithFormat:@"%@%@%@", ps, numberText, ss];
}

-(CGPoint)worldPosition
{
    return [renderBase convertToWorldSpace:self.position];
}

-(void)setWorldPosition:(CGPoint)theWorldPosition
{
    self.position=[renderBase convertToNodeSpace:theWorldPosition];
}

-(void)setPosition:(CGPoint)thePosition
{
    position=thePosition;
    
    [self.textRenderComponent updatePosition:position];
    
    [self.textBackgroundRenderComponent updatePosition:position];
}

-(void)inflateZIndex
{
    [self.textRenderComponent inflateZindex];
}
-(void)deflateZindex
{
    [self.textRenderComponent deflateZindex];
}

-(void)fadeInElementsFrom:(float)startTime andIncrement:(float)incrTime
{
    [textRenderComponent fadeInElementsFrom:startTime andIncrement:incrTime];
}

-(void)attachToRenderBase:(CCNode*)theRenderBase;
{
    if(self.hidden)return;
    
    renderBase=theRenderBase;
    
    [renderBase addChild:textBackgroundRenderComponent.sprite];
    
    [renderBase addChild:textRenderComponent.label0];
    [renderBase addChild:textRenderComponent.label];
}

-(void)setupDraw
{
    if(self.hidden)return;
    
    // text mode
    self.textRenderComponent.useAlternateFont=YES;
    [self.textRenderComponent setupDraw];
    
    
    //don't show the label if it's not enabled
    if(!self.enabled)
    {
        textRenderComponent.label.visible=NO;
        textRenderComponent.label0.visible=NO;
    }
    
    //set size to size of cclabelttf plus the background overdraw size (the background itself is currently stretchy)
    self.size=CGSizeMake(self.textRenderComponent.label.contentSize.width+BTXE_OTBKG_WIDTH_OVERDRAW_PAD, self.textRenderComponent.label.contentSize.height);

    //background sprite to text (using same size)
    [textBackgroundRenderComponent setupDrawWithSize:self.size];
}

-(void)destroy
{
    [self detachFromRenderBase];
    
    [gameWorld delayRemoveGameObject:self];
}

-(void)detachFromRenderBase
{
    [textBackgroundRenderComponent.sprite removeFromParentAndCleanup:YES];
    [textRenderComponent.label0 removeFromParentAndCleanup:YES];
    [textRenderComponent.label removeFromParentAndCleanup:YES];
}

-(void)activate
{
    self.enabled=YES;
    self.textRenderComponent.label.visible=self.enabled;
    self.textRenderComponent.label0.visible=self.enabled;
}

-(void)returnToBase
{
    self.position=self.originalPosition;
}

-(void)dealloc
{
    self.text=nil;
    self.textRenderComponent=nil;
    
    self.prefixText=nil;
    self.numberText=nil;
    self.suffixText=nil;
    self.numberValue=nil;
    self.container=nil;

    [numberValue release];
    
    [super dealloc];
}

@end
