//
//  SGBtxeObjectNumber.m
//  belugapad
//
//  Created by gareth on 24/09/2012.
//
//

#import "SGBtxeObjectNumber.h"
#import "SGBtxeTextRender.h"


@implementation SGBtxeObjectNumber

@synthesize size, position;
@synthesize textRenderComponent;

@synthesize prefixText, suffixText, numberText, numberValue;

-(SGBtxeObjectNumber*)initWithGameWorld:(SGGameWorld*)aGameWorld
{
    if(self=[super initWithGameWorld:aGameWorld])
    {
        prefixText=@"";
        numberText=@"";
        suffixText=@"";
        numberValue=@0;
        size=CGSizeZero;
        position=CGPointZero;
        textRenderComponent=[[SGBtxeTextRender alloc] initWithGameObject:(SGGameObject*)self];
    }
    
    return self;
}

-(void)handleMessage:(SGMessageType)messageType
{
    
}

-(void)doUpdate:(ccTime)delta
{
    
}

-(NSString*)numberText
{
    return numberText;
}

-(void)setNumberText:(NSString *)theNumberText
{
    numberText=theNumberText;
    
    NSNumberFormatter *nf=[[NSNumberFormatter alloc] init];
    [nf setNumberStyle:NSNumberFormatterDecimalStyle];
    numberValue=[nf numberFromString:numberText];
    [nf release];
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
    numberValue=[nf numberFromString:numberText];
    [nf release];
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

-(void)setWorldPosition:(CGPoint)worldPosition
{
    self.position=[renderBase convertToNodeSpace:worldPosition];
}

-(void)setPosition:(CGPoint)thePosition
{
    position=thePosition;
    
    [self.textRenderComponent updatePosition:position];
}

-(void)fadeInElementsFrom:(float)startTime andIncrement:(float)incrTime
{
    [textRenderComponent fadeInElementsFrom:startTime andIncrement:incrTime];
}

-(void)attachToRenderBase:(CCNode*)theRenderBase;
{
    renderBase=theRenderBase;
    
    [renderBase addChild:textRenderComponent.label0];
    [renderBase addChild:textRenderComponent.label];
}

-(void)setupDraw
{
    // text mode
    self.textRenderComponent.useAlternateFont=YES;
    [self.textRenderComponent setupDraw];
    self.size=self.textRenderComponent.label.contentSize;
    
}

-(void)dealloc
{
    self.text=nil;
    self.textRenderComponent=nil;
    
    self.prefixText=nil;
    self.numberText=nil;
    self.suffixText=nil;

    [numberValue release];
    
    [super dealloc];
}

@end
