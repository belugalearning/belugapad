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
}
@end

@implementation PassCodeView

const uint numLabels = 4;
const uint firstLabelX = 11;
const uint labelSpacing = 67;

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        text = [[NSMutableString alloc] init];        
        self.backgroundColor = [UIColor clearColor];
        
        labels = [NSMutableArray array];
        for (uint i=0; i<numLabels; i++)
        {
            UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(firstLabelX + i * labelSpacing, 9, 24, 24)] autorelease];
            [label setTextColor:[UIColor whiteColor]];
            [label setBackgroundColor:[UIColor clearColor]];
            [label setFont:[UIFont fontWithName:@"Chango" size:24]];
            [self addSubview:label];
            [(NSMutableArray*)labels addObject:label];
        }
        labels = [labels copy];
        [self clearText];
        
        cursor = [[UIView alloc] init];
        cursor.userInteractionEnabled = NO;
        cursor.backgroundColor = [UIColor colorWithRed:0.26f green:0.42f blue:0.95f alpha:1];
        [cursor setAlpha:0];
        [self addSubview:cursor];
        
        [NSTimer scheduledTimerWithTimeInterval:0.6 target:self selector:@selector(cursorTick:) userInfo:nil repeats:YES];
        
        singleDigitMatch = [[NSRegularExpression alloc] initWithPattern:@"^\\d$" options:0 error:nil];
    }
    return self;
}

#pragma mark -
#pragma mark Property Accessors
-(NSString*)text
{
    return [NSString stringWithString:text];
}

#pragma mark -
#pragma mark public interface
-(void)clearText
{
    [text setString:[@"" stringByPaddingToLength:numLabels withString:@" " startingAtIndex:0]];
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
    uint labelIx;
    
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
    [self editAtCurrentIndex];
}

#pragma mark -
#pragma mark NumpadInputControllerDelegate
-(void)buttonTappedWithText:(NSString*)buttonText
{
    BOOL isDigitButton = [singleDigitMatch numberOfMatchesInString:buttonText options:NSMatchingWithoutAnchoringBounds range:NSMakeRange(0,[buttonText length])] == 1;
    
    if (isDigitButton)
    {
        [text replaceCharactersInRange:NSMakeRange(currentIndex, 1) withString:buttonText];
    }
    else if ([buttonText isEqualToString:@"⌫"])
    {
        [text replaceCharactersInRange:NSMakeRange(currentIndex, 1) withString:@" "];
    }
    
    [self setNeedsDisplay];
}

#pragma mark -
#pragma mark Drawing

-(void)drawRect:(CGRect)rect
{
    for (uint i=0; i<numLabels; i++)
    {
        ((UILabel*)[labels objectAtIndex:i]).text = [text substringWithRange:NSMakeRange(i,1)];
    }
}

-(void)cursorTick:(NSTimer*)timer
{
    [cursor setAlpha:(self.isFirstResponder && !cursor.alpha ? 1 : 0)];
}

#pragma mark - 
#pragma mark nktf
-(void)editAtCurrentIndex
{
    UILabel *currIndexLabel = labels[currentIndex];
    [cursor setFrame:CGRectMake(currIndexLabel.frame.origin.x - 4, 36, 29, 3)];
    
    /*
    CGRect frame = currIndexLabel.frame;
    frame.origin.y -= 3;
    
    nktf.frame = frame;
    nktf.userInteractionEnabled = YES;
    
    NSString *character = [text substringWithRange:NSMakeRange(currentIndex, 1)];
    if ([character isEqualToString:@" "])
    {
        nktf.text = @"";
        [nktf becomeFirstResponder];
    }
    else
    {
        nktf.text = character;
        [nktf becomeFirstResponder];
        [nktf selectAll:self];
        //[nktf setValue:[NSValue valueWithRange:NSMakeRange(0,1)] forKey:@"selectionRange"];
    }
    
    for (UILabel *l in labels)
    {
        l.textColor = l == labels[currentIndex] ? [UIColor clearColor] : [UIColor whiteColor];
    }
     */
}
/*
-(void)endEdit
{
    nktf.userInteractionEnabled = NO;
    [nktf resignFirstResponder];
    nktf.text = @"";
    for (UILabel *l in labels) l.textColor = [UIColor whiteColor];
}
-(void)onEdit
{
    // char has either been added or removed - which one?
    if ([nktf.text length])
    {
        [text replaceCharactersInRange:NSMakeRange(currentIndex, 1) withString:nktf.text];
        
        // either move to next char, or if we're on last char, lose focus
        if (++currentIndex < numLabels) [self editAtCurrentIndex];
        else [self endEdit];
    }
    else
    {
        // removed a char
        [text replaceCharactersInRange:NSMakeRange(currentIndex, 1) withString:@" "];
        if (currentIndex)
        {
            currentIndex--;
            [self editAtCurrentIndex];
        }
    }
}

-(void)numericKeypadDeleteButtonWasPressed:(UITextField*)tf
{
    //if (![nktf.text length]) [self onEdit]; // nktfDidChange won't fire if text field empty when delete button pressed
}

-(void)nktfDidChange:(NSNotification*)notification
{
    [self onEdit];
}
//*/
-(void)dealloc
{
    if (numpadInputView) [numpadInputView release];
    if (cursor) [cursor release];
    if (text) [text release];
    if (labels) [labels release];
    if (singleDigitMatch) [singleDigitMatch release];
    [super dealloc];
}

@end
