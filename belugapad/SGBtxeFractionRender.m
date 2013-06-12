#import "SGBtxeFractionRender.h"
#import "SGBtxeObjectNumber.h"
#import "global.h"

//this somewhat breaks the independent render model of the other text, background etc components
//... i.e. it'll only work with a SGBtxeObjectNumber parent, and that's not done through protocols

@implementation SGBtxeFractionRender

@synthesize label, label0;
@synthesize useAlternateFont;
@synthesize useTheseAssets;

-(SGBtxeFractionRender*)initWithGameObject:(id<Bounding, Text>)aGameObject
{
    if(self=[super initWithGameObject:(SGGameObject*)aGameObject])
    {
        ParentGO=(SGBtxeObjectNumber*)aGameObject;
        self.label=nil;
        self.label0=nil;
        self.useAlternateFont=NO;
        self.useTheseAssets=@"Small";
    }
    return self;
    
}

-(void)fadeInElementsFrom:(float)startTime andIncrement:(float)incrTime
{
//    [self.label0 setOpacity:0];
//    [label0 runAction:[CCSequence actions:[CCDelayTime actionWithDuration:startTime + 0.25f], [CCFadeTo actionWithDuration:0.2f opacity:178], nil]];
//    
//    [self.label setOpacity:0];
//    [label runAction:[CCSequence actions:[CCDelayTime actionWithDuration:startTime], [CCFadeTo actionWithDuration:0.2f opacity:255], nil]];
    
    [self fadeInThing:self.numLabel withStartTime:startTime andIncrement:incrTime];
    [self fadeInThing:self.denomLabel withStartTime:startTime andIncrement:incrTime];
    [self fadeInThing:self.intLabel withStartTime:startTime andIncrement:incrTime];
    [self fadeInThing:self.divLine withStartTime:startTime andIncrement:incrTime];

    [self fadeInThing:self.numLabel0 withStartTime:startTime andIncrement:incrTime];
    [self fadeInThing:self.denomLabel0 withStartTime:startTime andIncrement:incrTime];
    [self fadeInThing:self.intLabel0 withStartTime:startTime andIncrement:incrTime];
    [self fadeInThing:self.divLine0 withStartTime:startTime andIncrement:incrTime];
}

-(void)fadeInThing:(id)thing withStartTime:(float)startTime andIncrement:(float)incrTime
{
    [thing setOpacity:0];
    [thing runAction:[CCSequence actions:[CCDelayTime actionWithDuration:startTime], [CCFadeTo actionWithDuration:0.2f opacity:255], nil]];
    
}

-(void)setupDraw
{
    int modtop=[ParentGO.numerator intValue];
    whole=0;
    
    if(ParentGO.showAsMixedFraction && ParentGO.numerator && ParentGO.denominator)
    {
        whole=(int)([ParentGO.numerator integerValue] / [ParentGO.denominator integerValue]);
        modtop=[ParentGO.numerator integerValue] - (whole * [ParentGO.denominator integerValue]);
    }

    
    self.label=[CCNode node];
    self.label0=[CCNode node];
    
    NSString *fontName=@"Source Sans Pro";
    float fontSize=24.0f;
    if(self.useAlternateFont) fontName=@"Chango";
    if([self.useTheseAssets isEqualToString:@"Medium"])
        fontSize=36.0f;
    else if([self.useTheseAssets isEqualToString:@"Large"])
        fontSize=48.0f;

    fontSize*=0.6f;
    
    self.numLabel=[CCLabelTTF labelWithString:[self getNumString] fontName:fontName fontSize:fontSize];
    self.denomLabel=[CCLabelTTF labelWithString:[self getDenomString] fontName:fontName fontSize:fontSize];
    
    //shift these away from centre by 60% of their height
    float vshiftup=self.numLabel.contentSize.height * 0.55f;
    float vshiftdown=self.denomLabel.contentSize.height * -0.48f;
    
    self.numLabel.position=ccp(0, vshiftup);
    [self.label addChild:self.numLabel];
    
    self.denomLabel.position=ccp(0, vshiftdown);
    [self.label addChild:self.denomLabel];
    
    self.divLine=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/btxe/fracsep.png")];
    [self.label addChild:self.divLine];
    
    self.maxw=self.numLabel.contentSize.width;
    if(self.denomLabel.contentSize.width > self.maxw) self.maxw=self.denomLabel.contentSize.width;
    
    self.fractionw=self.maxw;
    
    self.divLine.scaleX=self.maxw/self.divLine.contentSize.width;
    self.divLine.scaleY=0.5f;
    
    
    self.maxh=self.numLabel.contentSize.height + self.denomLabel.contentSize.height * 1.1f;
    //artifically inflate this to fit the fraction
    self.maxh=self.maxh*1.25f;
    
    if(ParentGO.showAsMixedFraction)
    {
        self.intLabel=[CCLabelTTF labelWithString:[self getWholeString] fontName:fontName fontSize:fontSize * 1.6f];
        [self.label addChild:self.intLabel];
        
        float leftw=self.intLabel.contentSize.width *1.4f;
        float rightw=self.fractionw *1.4f;
        
        float totalw=leftw+rightw;
        self.intLabel.position=ccp(self.intLabel.position.x - totalw*0.5f + leftw*0.5f, self.intLabel.position.y);
        
        float rightshift=totalw*0.5f - rightw*0.5f;
        self.numLabel.position=ccp(self.numLabel.position.x + rightshift, self.numLabel.position.y);
        self.denomLabel.position=ccp(self.denomLabel.position.x + rightshift, self.denomLabel.position.y);
        self.divLine.position=ccp(self.divLine.position.x + rightshift, self.divLine.position.y);
        
        
        //set total width
        self.maxw=totalw;
    }
    
    
    //make label0 copies of everything :(
    self.numLabel0=[self zeroclone:self.numLabel];
    [self.label0 addChild:self.numLabel0];
    self.denomLabel0=[self zeroclone:self.denomLabel];
    [self.label0 addChild:self.denomLabel0];
    
    if(ParentGO.showAsMixedFraction)
    {
        self.intLabel0=[self zeroclone:self.intLabel];
        [self.label0 addChild:self.intLabel0];
    }
    
    self.divLine0=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/btxe/fracsep.png")];
    self.divLine0.position=ccp(self.divLine.position.x, self.divLine.position.y-0.5f);
    self.divLine0.color=ccc3(0,0,0);
    self.divLine0.opacity=178;
    self.divLine0.scaleX=self.divLine.scaleX;
    self.divLine0.scaleY=self.divLine.scaleY;
    [self.label0 addChild:self.divLine0];
    
//    self.label0=[CCLabelTTF labelWithString:ParentGO.text fontName:fontName fontSize:fontSize];
//    self.label0.position=ccp(0, -1);
//    self.label0.color=ccc3(0, 0, 0);
//    self.label0.opacity=178;
//    
//    self.label=[CCLabelTTF labelWithString:ParentGO.text fontName:fontName fontSize:fontSize];
    
}

-(CCLabelTTF*) zeroclone:(CCLabelTTF*)oflabel
{
    CCLabelTTF *l0=[CCLabelTTF labelWithString:oflabel.string fontName:oflabel.fontName fontSize:oflabel.fontSize];
    l0.color=ccc3(0,0,0);
    l0.opacity=178;
    l0.position=ccp(oflabel.position.x, oflabel.position.y-0.5f);
    return l0;
}

-(NSString*) getWholeString
{
    if(ParentGO.pickerTargetNumerator && !ParentGO.numerator) return @"?";
    
    else if (ParentGO.pickerTargetNumerator) ParentGO.pickedFractionWholeExplicit ? [NSString stringWithFormat:@"%d", [ParentGO.pickedFractionWholeExplicit intValue]] : @"0";
    
    return [NSString stringWithFormat:@"%d", whole];
}

-(NSString*) getNumString
{
    int modtop=[ParentGO.numerator intValue];
    int denom=[ParentGO.denominator intValue];
    
    if(ParentGO.showAsMixedFraction && modtop>denom)
    {
        modtop=modtop%denom;
    }
    
    if(ParentGO.pickerTargetNumerator)
    {
        if(ParentGO.numerator) return [NSString stringWithFormat:@"%d", modtop];
        else return @"?";
    }
    else return [NSString stringWithFormat:@"%d", modtop];
}
-(NSString*) getDenomString
{
    if(ParentGO.pickerTargetDenominator)
    {
        if(ParentGO.denominator) return [ParentGO.denominator stringValue];
        else return @"?";
    }
    else return [ParentGO.denominator stringValue];
}

-(void)updateLabel
{
    [self.numLabel setString:[self getNumString]];
    [self.numLabel0 setString:[self getNumString]];
    
    [self.denomLabel setString:[self getDenomString]];
    [self.denomLabel0 setString:[self getDenomString]];
    
    [self.intLabel setString:[self getWholeString]];
    [self.intLabel0 setString:[self getWholeString]];
}

-(void)tagMyChildrenForIntro
{
    [self.numLabel setTag:3];
    [self.numLabel setOpacity:0];
    [self.denomLabel setTag:3];
    [self.denomLabel setOpacity:0];
    [self.intLabel setTag:3];
    [self.intLabel setOpacity:0];
    [self.divLine setTag:3];
    [self.divLine setOpacity:0];
    
    [self.numLabel0 setTag:3];
    [self.numLabel0 setOpacity:0];
    [self.denomLabel0 setTag:3];
    [self.denomLabel0 setOpacity:0];
    [self.intLabel0 setTag:3];
    [self.intLabel0 setOpacity:0];
    [self.divLine0 setTag:3];
    [self.divLine0 setOpacity:0];
}

-(void)updatePosition:(CGPoint)position
{
    self.label.position=position;
    self.label0.position=ccpAdd(position, ccp(0, -1));
}

-(void)inflateZindex
{
    self.label0.zOrder=99;
    self.label.zOrder=99;
}
-(void)deflateZindex
{
    self.label0.zOrder=0;
    self.label.zOrder=0;
}

-(void)changeVisibility:(BOOL)visibility
{
    [self.label setVisible:visibility];
}

-(void)dealloc
{
    self.label=nil;
    self.label0=nil;
    
    [super dealloc];
}

@end