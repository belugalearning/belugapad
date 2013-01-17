//
//  NumberLayout.m
//  belugapad
//
//  Created by gareth on 11/09/2012.
//
//

#import "NumberLayout.h"

@implementation NumberLayout

+(NSArray*)unitLayoutUpToNumber:(int)max
{
    //returns a set of logical (unit) offsets from the first number
    //continues past 10
    
    NSMutableArray *layout=[[NSMutableArray alloc] init];
    
    int x=0, y=0;
    
    for(int i=1; i<=max;i++)
    {
        CGPoint p=CGPointMake(x, y);
        
        if(y/-5)
        {
            p=CGPointMake(p.x, p.y-(0.33f * (float)(y/-5)));
        }
                
        [layout addObject:[NSValue valueWithCGPoint:p]];
        
        if (x==0) {
            x--;
        }
        else
        {
            y--;
            x=0;
        }
    }
    
    NSArray *ret=[NSArray arrayWithArray:layout];
    [layout release];
    return ret;
}

+(NSArray*)unitLayoutAcrossToNumber:(int)max
{
    NSMutableArray *layout=[NSMutableArray arrayWithArray:[self unitLayoutUpToNumber:max]];
    for(int i=0; i<[layout count]; i++)
    {
        CGPoint p1=[[layout objectAtIndex:i] CGPointValue];
        CGPoint p2=CGPointMake(p1.y, p1.x);
        [layout replaceObjectAtIndex:i withObject:[NSValue valueWithCGPoint:p2]];
    }
    NSArray *ret=[NSArray arrayWithArray:layout];
    return ret;
}

+(NSArray*)getPhysicalLayoutFrom:(NSArray*)unitLayout withSpace:(float)spacing
{
    NSMutableArray *layout=[NSMutableArray arrayWithArray:unitLayout];
    for(int i=0; i<[layout count]; i++)
    {
        CGPoint p1=[[layout objectAtIndex:i] CGPointValue];
        CGPoint p2=CGPointMake(p1.x * spacing, p1.y * spacing);
        
        [layout replaceObjectAtIndex:i withObject:[NSValue valueWithCGPoint:p2]];
    }
    NSArray *ret=[NSArray arrayWithArray:layout];
    return ret;
}

+(NSArray*)physicalLayoutUpToNumber:(int)max withSpacing:(float)spacing
{
    return [self getPhysicalLayoutFrom:[self unitLayoutUpToNumber:max] withSpace:spacing];
}

+(NSArray*)physicalLayoutAcrossToNumber:(int)max withSpacing:(float)spacing
{
    return [self getPhysicalLayoutFrom:[self unitLayoutAcrossToNumber:max] withSpace:spacing];
}

@end
