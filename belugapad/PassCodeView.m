//
//  PassCodeInput.m
//  belugapad
//
//  Created by Nicholas Cartwright on 13/11/2012.
//
//

#import "PassCodeView.h"

@interface PassCodeView()
{
    NSArray *labels;
    NSMutableString *text;
}

@end

@implementation PassCodeView

const uint numLabels = 4;
const uint firstLabelX = 12;
const uint labelSpacing = 68;

@synthesize text;

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        text = [[NSMutableString alloc] init];        
        self.backgroundColor = [UIColor clearColor];
        
        labels = [NSMutableArray array];
        for (uint i=0; i<numLabels; i++)
        {
            UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(firstLabelX + i * labelSpacing, 8.0f, 24.0f, 24.0f)] autorelease];
            [label setTextColor:[UIColor whiteColor]];
            [label setBackgroundColor:[UIColor clearColor]];
            [label setFont:[UIFont fontWithName:@"Chango" size:24]];
            [self addSubview:label];
            [(NSMutableArray*)labels addObject:label];
        }
        labels = [labels copy];
    }
    return self;
}

#pragma mark -
#pragma mark Custom Property Accessors
-(NSString*)text
{
    return [NSString stringWithString:text];
}
-(void)setText:(NSString*)val
{
    if (val && [val isEqualToString:text]) return;
    if (val && [val length]) [text setString:val];
    else [text setString:@""];
    [self setNeedsDisplay];
}

#pragma mark -
#pragma mark Respond to touch and become first responder.

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

-(void) touchesBegan: (NSSet *) touches withEvent: (UIEvent *) event
{
    [self becomeFirstResponder];
}

#pragma mark -
#pragma mark Drawing

- (void)drawRect:(CGRect)rect
{
    for (uint i=0; i<numLabels; i++)
    {
        ((UILabel*)[labels objectAtIndex:i]).text = [text length] > i ? [text substringWithRange:NSMakeRange(i,1)] : @"";
    }
}

#pragma mark -
#pragma mark UIKeyInput Protocol Methods

- (BOOL)hasText
{
    return self.text.length > 0;
}

- (void)insertText:(NSString*)theText
{
    if ([text length] >= numLabels || !theText || ![theText length]) return;
    [text appendString:[theText substringWithRange:NSMakeRange(0, MIN([theText length], numLabels - [theText length]))]];
    [self setNeedsDisplay];
}

- (void)deleteBackward
{
    if (![text length]) return;
    [text deleteCharactersInRange:NSMakeRange([text length]-1, 1)];
    [self setNeedsDisplay];
}

-(void)dealloc
{
    if (labels) [labels release];
    if (text) [text release];
    [super dealloc];
}

@end
