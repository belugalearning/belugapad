//
//  NSArray_BAAdditions.m
//  Beluga
//
//  Created by Cathy Shive on 12/21/10.
//  Copyright 2010 Heritage World Press. All rights reserved.
//

#import "NSArray_BAAdditions.h"


@implementation NSArray (BAAdditions)
+(NSArray*)arrayByRandomizingObjectsInArray:(NSArray*)theArray
{
	NSMutableArray * aMutableCopy = [NSMutableArray arrayWithArray:theArray];
	NSInteger aCount = [theArray count];
	for(NSInteger i = aCount-1; i>=0; i--)
	{
		// pick a random object from the ones we haven't reached 
		// yet to exchange with this one
		NSInteger aRandomIndex = arc4random() % (i+1);
		id anObjectA = [aMutableCopy objectAtIndex:aRandomIndex];
		id anObjectB = [aMutableCopy objectAtIndex:i];
		[aMutableCopy replaceObjectAtIndex:i withObject:anObjectA];
		[aMutableCopy replaceObjectAtIndex:aRandomIndex withObject:anObjectB];
	}
	
	// return a non-mutable copy
	return [[aMutableCopy copy] autorelease];
}

+ (id)randomObjectFromArray:(NSArray*)theArray
{
	if([theArray count] > 0)
	{
		NSInteger aRandomIndex = (arc4random() % [theArray count]);
		return [theArray objectAtIndex:aRandomIndex];
	}
	return nil;
}
- (BOOL)indexIsValid:(NSInteger)theIndex
{
	return (theIndex >= 0 && theIndex < [self count]);
}

- (BOOL)hasFiveInARow
{
    if ([self count] < 5)
    {
        return NO;
    }
    else
    {
        NSInteger inarow = 0;
        
        for (int i = 0; i < [self count]; i++)
        {
            if ([[self objectAtIndex:i] boolValue])
            {
                inarow++;
                
                if (inarow >= 5)
                {
                    return YES;
                }
            }
            else
            {
                inarow = 0;
            }
        }
    }
    
    return NO;
}

@end
