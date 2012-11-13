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
    UILabel *label0;
    UILabel *label1;
    UILabel *label2;
    UILabel *label3;
}

@end

@implementation PassCodeView

@synthesize text;

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        // Initialization code
        self.text = [NSMutableString string];        
        self.backgroundColor = [UIColor clearColor];
        
        label0 = [[UILabel alloc] initWithFrame:CGRectMake(12.0f, 8.0f, 24.0f, 24.0f)];
        [label0 setTextColor:[UIColor whiteColor]];
        [label0 setBackgroundColor:[UIColor clearColor]];
        [label0 setFont:[UIFont fontWithName:@"Chango" size:24]];
        [self addSubview:label0];
        
        label1 = [[UILabel alloc] initWithFrame:CGRectMake(78.0f, 8.0f, 24.0f, 24.0f)];
        [label1 setTextColor:[UIColor whiteColor]];
        [label1 setBackgroundColor:[UIColor clearColor]];
        [label1 setFont:[UIFont fontWithName:@"Chango" size:24]];
        [self addSubview:label1];
        
        label2 = [[UILabel alloc] initWithFrame:CGRectMake(145.0f, 8.0f, 24.0f, 24.0f)];
        [label2 setTextColor:[UIColor whiteColor]];
        [label2 setBackgroundColor:[UIColor clearColor]];
        [label2 setFont:[UIFont fontWithName:@"Chango" size:24]];
        [self addSubview:label2];
        
        label3 = [[UILabel alloc] initWithFrame:CGRectMake(212.0f, 8.0f, 24.0f, 24.0f)];
        [label3 setTextColor:[UIColor whiteColor]];
        [label3 setBackgroundColor:[UIColor clearColor]];
        [label3 setFont:[UIFont fontWithName:@"Chango" size:24]];
        [self addSubview:label3];
    }
    return self;
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
    label0.text = self.text.length ? [self.text substringWithRange:NSMakeRange(0,1)] : @"";
    label1.text = self.text.length > 1 ? [self.text substringWithRange:NSMakeRange(1,1)] : @"";
    label2.text = self.text.length > 2 ? [self.text substringWithRange:NSMakeRange(2,1)] : @"";
    label3.text = self.text.length > 3 ? [self.text substringWithRange:NSMakeRange(3,1)] : @"";
}

#pragma mark -
#pragma mark UIKeyInput Protocol Methods

- (BOOL)hasText
{
    return self.text.length > 0;
}

- (void)insertText:(NSString *)theText
{
    [self.text appendString:theText];
    if (self.text.length > 4) self.text = [NSMutableString stringWithString:[self.text substringToIndex:4]];
    [self setNeedsDisplay];
}

- (void)deleteBackward
{
    if (!self.text.length) return;
    NSRange theRange = NSMakeRange(self.text.length-1, 1);
    [self.text deleteCharactersInRange:theRange];
    [self setNeedsDisplay];
}

-(void)dealloc
{
    self.text = nil;
    if (label0)
    {
        [label0 removeFromSuperview];
        [label0 release];
    }
    if (label1)
    {
        [label1 removeFromSuperview];
        [label1 release];
    }
    if (label2)
    {
        [label2 removeFromSuperview];
        [label2 release];
    }
    if (label3)
    {
        [label3 removeFromSuperview];
        [label3 release];
    }
    [super dealloc];
}

@end
