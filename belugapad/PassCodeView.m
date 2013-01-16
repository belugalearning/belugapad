//
//  PassCodeInput.m
//  belugapad
//
//  Created by Nicholas Cartwright on 13/11/2012.
//
//

#import "PassCodeView.h"
#import "NumpadInputController.h"

@interface PassCodeView()
{
    NSArray *labels;
    NSMutableString *text;
    uint currentIndex;
    UIView *cursor;
    
    NumpadInputController *numpadInputView;
    NSRegularExpression *singleDigitMatch;
    NSRegularExpression *validMatch;
}
@end

@implementation PassCodeView

const uint numLabels = 4;
const NSString *placeholderText = @"CODE";
const uint firstLabelX = 12;
const uint labelSpacing = 67;

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        self.backgroundColor = [UIColor clearColor];
        
        labels = [NSMutableArray array];
        for (uint i=0; i<numLabels; i++)
        {
            UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(firstLabelX + i * labelSpacing, 11, 24, 24)] autorelease];
            [label setTextColor:[UIColor whiteColor]];
            [label setBackgroundColor:[UIColor clearColor]];
            [label setFont:[UIFont fontWithName:@"Chango" size:24]];
            [self addSubview:label];
            [(NSMutableArray*)labels addObject:label];
        }
        labels = [labels copy];
        
        cursor = [[UIView alloc] init];
        cursor.userInteractionEnabled = NO;
        cursor.backgroundColor = [UIColor whiteColor];
        //cursor.backgroundColor = [UIColor colorWithRed:0.26f green:0.42f blue:0.95f alpha:1]; // this is the colour of the iOS cursor (insertion point) for white text on clear bg.
        [self addSubview:cursor];
        
        text = [[NSMutableString alloc] init];
        [self clearText];
        
        [NSTimer scheduledTimerWithTimeInterval:0.6 target:self selector:@selector(cursorTick:) userInfo:nil repeats:YES];
        
        singleDigitMatch = [[NSRegularExpression alloc] initWithPattern:@"^\\d$" options:0 error:nil];
        validMatch = [[NSRegularExpression alloc] initWithPattern:[NSString stringWithFormat:@"^\\d{%d}$", numLabels] options:0 error:nil];
    }
    return self;
}

#pragma mark -
#pragma mark Property Accessors
-(NSString*)text
{
    return [NSString stringWithString:text];
}

-(BOOL)isValid
{
    return [text length] == numLabels && [validMatch numberOfMatchesInString:text options:NSMatchingWithoutAnchoringBounds range:NSMakeRange(0,numLabels)] == 1;
}

#pragma mark -
#pragma mark public interface
-(void)clearText
{
    BOOL validBefore = self.isValid;
    
    [text setString:[@"" stringByPaddingToLength:numLabels withString:@" " startingAtIndex:0]];
    [self setNeedsDisplay];
    
    currentIndex = 0;
    [self positionCursor];
    
    if (validBefore && self.delegate) [self.delegate passCodeBecameInvalid:self];
}

#pragma mark -
#pragma mark Responder / UIView overrides

-(BOOL)canBecomeFirstResponder
{
    return YES;
}

-(UIView*)inputView
{
    if (!numpadInputView)
    {
        numpadInputView = [[NumpadInputController alloc] initWithNibName:@"NumpadInputController" bundle:[NSBundle mainBundle]];
        numpadInputView.delegate = self;
    }
    return numpadInputView.view;
}

-(void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
    [self becomeFirstResponder];
    
    // what's closest slot to touch?
    CGPoint touchPos = [(UITouch*)[touches anyObject] locationInView:self];
    float closestDistance = NSUIntegerMax;
    uint labelIx=0;
    
    for (uint i=0; i<[labels count]; i++)
    {
        UILabel *l = labels[i];
        CGPoint lCentre = CGPointMake(l.frame.origin.x + 0.5 * l.frame.size.width, l.frame.origin.y + 0.5 * l.frame.size.height);
        float dist = sqrtf( powf(lCentre.x - touchPos.x, 2) + powf(lCentre.y - touchPos.y, 2) );
        
        if (dist < closestDistance)
        {
            closestDistance = dist;
            labelIx = i;
        }
    }
    
    currentIndex = labelIx;
    [self positionCursor];
}

#pragma mark -
#pragma mark NumpadInputControllerDelegate
-(void)buttonTappedWithText:(NSString*)buttonText
{
    BOOL validBefore = self.isValid;
    BOOL isDigitButton = [singleDigitMatch numberOfMatchesInString:buttonText options:NSMatchingWithoutAnchoringBounds range:NSMakeRange(0,[buttonText length])] == 1;
    
    if (isDigitButton)
    {
        [text replaceCharactersInRange:NSMakeRange(currentIndex, 1) withString:buttonText];// either move to next char, or if we're on last char, lose focus
        if (++currentIndex >= numLabels)
        {
            currentIndex = 0;
            [self resignFirstResponder];
        }
        [self positionCursor];
    }
    else if ([buttonText isEqualToString:@"⌫"])
    {
        [text replaceCharactersInRange:NSMakeRange(currentIndex, 1) withString:@" "];
        if (currentIndex)
        {
            currentIndex--;
            [self positionCursor];
        }
    }
    else
    {
        // done/save/return
        [self resignFirstResponder];
    }
    
    [self setNeedsDisplay];
    
    if (self.delegate)
    {
        [self.delegate passCodeWasEdited:self];
        
        if (!validBefore)   
        {
            if (self.isValid) [self.delegate passCodeBecameValid:self];
        }
        else
        {
            if (!self.isValid) [self.delegate passCodeBecameInvalid:self];
        }
    }
}

#pragma mark -
#pragma mark Drawing

-(void)drawRect:(CGRect)rect
{
    for (uint i=0; i<numLabels; i++)
    {
        NSRange r = NSMakeRange(i,1);
        UILabel *l = [labels objectAtIndex:i];
        if ([[text substringWithRange:r] isEqualToString:@" "])
        {
            l.text = [placeholderText substringWithRange:r];
            l.textColor = [UIColor lightGrayColor];
        }
        else
        {
            l.text = [text substringWithRange:r];
            l.textColor = [UIColor whiteColor];
        }
    }
}

-(void)cursorTick:(NSTimer*)timer
{
    [cursor setAlpha:(self.isFirstResponder && !cursor.alpha ? 1 : 0)];
}

-(void)positionCursor
{
    [cursor setAlpha:0]; // start with cursor off. N.B. also ensures that after char entered for last space, there isn't a momentary flash of the cursor back in the first space.
    UILabel *currIndexLabel = labels[currentIndex];
    [cursor setFrame:CGRectMake(currIndexLabel.frame.origin.x - 4, 36, 29, 3)];
}

-(void)dealloc
{
    self.delegate = nil;
    if (numpadInputView) [numpadInputView release];
    if (cursor) [cursor release];
    if (text) [text release];
    if (labels) [labels release];
    if (singleDigitMatch) [singleDigitMatch release];
    if (validMatch) [validMatch release];
    [super dealloc];
}

@end
