//
//  TokenKeyInputView.m
//  belugapad
//
//  Created by Nicholas Cartwright on 21/04/2013.
//
//

#import "TokenKeyInputView.h"

@interface TokenKeyInputView()
{
    NSArray *labels;
    NSMutableString *text;
    uint currentIndex;
    UIView *cursor;
    NSRegularExpression *validTokenMatch;
    NSRegularExpression *validCharsMatch;
}
@end

@implementation TokenKeyInputView

static const uint numLabels = 10;
static const uint groupends[] = { 2, 6 };
static const uint labelWidth = 36;
static const uint labelSpacing = 4;
static const uint groupSpacing = 34;
static const uint fontSize = 24;
static NSString *const kValidCharGroup = @"[A-Z0-9]"; // N.B. insertText transforms text to uppercase

#pragma mark -
#pragma mark Init
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = [UIColor blackColor];
        
        labels = [NSMutableArray array];
        
        uint x = 0;
        const uint *grpend = groupends;
        
        NSLog(@"%ld %ld", sizeof(groupends), sizeof(groupends[0]));
        
        for (uint i=0; i<numLabels; i++)
        {
            UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(x, 0, labelWidth, fontSize)] autorelease];
            [label setTextColor:[UIColor whiteColor]];
            [label setBackgroundColor:[UIColor clearColor]];
            [label setFont:[UIFont fontWithName:@"Chango" size:fontSize]];
            label.textAlignment = NSTextAlignmentCenter;
            [self addSubview:label];
            [(NSMutableArray*)labels addObject:label];

            x += labelWidth + labelSpacing;
            
            if (grpend < groupends + sizeof(groupends) && i == *grpend)
            {
                x += groupSpacing;
                ++grpend;
            }
        }
        labels = [labels copy];
        
        [NSTimer scheduledTimerWithTimeInterval:0.6 target:self selector:@selector(cursorTick:) userInfo:nil repeats:YES];
        cursor = [[UIView alloc] init];
        cursor.userInteractionEnabled = NO;
        cursor.backgroundColor = [UIColor whiteColor];
        [self addSubview:cursor];
        
        text = [[NSMutableString alloc] init];
        [self clearText];
        
        validTokenMatch = [[NSRegularExpression alloc] initWithPattern:[NSString stringWithFormat:@"^%@{%d}$", kValidCharGroup, numLabels] options:0 error:nil];
        validCharsMatch = [[NSRegularExpression alloc] initWithPattern:[NSString stringWithFormat:@"^%@+$", kValidCharGroup] options:0 error:nil];
    }
    return self;
}

#pragma mark -
#pragma mark dealloc
-(void)dealloc
{
    self.delegate = nil;
    if (cursor) [cursor release];
    if (text) [text release];
    if (labels) [labels release];
    if (validTokenMatch) [validTokenMatch release];
    if (validCharsMatch) [validCharsMatch release];
    [super dealloc];
}

#pragma mark -
#pragma mark Class Public Property Accessors
-(NSString*)text
{
    return [NSString stringWithString:text];
}

-(BOOL)isValid
{
    return [text length] == numLabels && [validTokenMatch numberOfMatchesInString:text options:NSMatchingWithoutAnchoringBounds range:NSMakeRange(0,numLabels)] == 1;
}

#pragma mark -
#pragma mark Class Public Methods
-(void)clearText
{
    BOOL validBefore = self.isValid;
    
    [text setString:[@"" stringByPaddingToLength:numLabels withString:@" " startingAtIndex:0]];
    [self setNeedsDisplay];
    
    currentIndex = 0;
    [self positionCursor];
    
    if (validBefore && self.delegate) [self.delegate tokenBecameInvalid:self];
}

# pragma mark -
# pragma mark UIKeyInput Protocol Methods
- (BOOL)hasText
{
    return YES;
}

-(void)insertText:(NSString *)s
{
    // lose focus if key was return
    if ([s isEqualToString:@"\n"])
    {
        [self resignFirstResponder];
        return;
    }
    
    // validate insertion text
    if (currentIndex + [s length] > numLabels) return;
    if ([validCharsMatch numberOfMatchesInString:[s uppercaseString] options:NSMatchingWithoutAnchoringBounds range:NSMakeRange(0, [s length])] != 1) return;
    
    // insert text
    BOOL validBeforeInsert = self.isValid;
    [text replaceCharactersInRange:NSMakeRange(currentIndex, [s length]) withString:[s uppercaseString]];
    BOOL validAfterInsert = self.isValid;
    
    // set currentIndex, lose focus if appropriate
    currentIndex += [s length];
    if (currentIndex >= numLabels)
    {
        currentIndex = 0;
        [self resignFirstResponder];
    }
    
    // redraw
    [self positionCursor];
    [self setNeedsDisplay];
    
    // call delegate methods
    if (self.delegate)
    {
        [self.delegate tokenWasEdited:self];
        if (validAfterInsert != validBeforeInsert)
        {
            validAfterInsert ? [self.delegate tokenBecameValid:self] : [self.delegate tokenBecameInvalid:self];
        }
    }
}

-(void)deleteBackward
{
    [text replaceCharactersInRange:NSMakeRange(currentIndex, 1) withString:@" "];
    currentIndex && --currentIndex;
    [self positionCursor];
    [self setNeedsDisplay];
}

# pragma mark -
# pragma mark UIResponder
-(BOOL)canBecomeFirstResponder
{
    return YES;
}

#pragma mark -
#pragma mark UIView
-(void)drawRect:(CGRect)rect
{
    for (uint i=0; i<numLabels; i++)
    {
        NSRange r = NSMakeRange(i,1);
        UILabel *l = [labels objectAtIndex:i];
        if ([[text substringWithRange:r] isEqualToString:@" "])
        {
            l.text = @"?";
            l.textColor = [UIColor lightGrayColor];
        }
        else
        {
            l.text = [text substringWithRange:r];
            l.textColor = [UIColor whiteColor];
        }
    }
}

-(void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
    [self becomeFirstResponder];
    
    // set current index and position cursor according to label closest to touch
    
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
#pragma mark private methods

-(void)cursorTick:(NSTimer*)timer
{
    [cursor setAlpha:(self.isFirstResponder && !cursor.alpha ? 1 : 0)];
}

-(void)positionCursor
{
    [cursor setAlpha:0]; // start with cursor off. N.B. also ensures that after char entered for last space, there isn't a momentary flash of the cursor back in the first space.
    UILabel *currIndexLabel = labels[currentIndex];
    [cursor setFrame:CGRectMake(currIndexLabel.frame.origin.x, fontSize + 2, labelWidth, 3)];
}

@end
