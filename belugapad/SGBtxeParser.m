//
//  SGBtxeParser.m
//  belugapad
//
//  Created by gareth on 15/08/2012.
//
//

#import "SGBtxeParser.h"
#import "global.h"
#import "TouchXML.h"
#import "MathMLConsts.h"

#import "SGBtxeRow.h"
#import "SGBtxeText.h"
#import "SGBtxeObjectText.h"
#import "SGBtxeMissingVar.h"
#import "SGBtxeContainerMgr.h"
#import "SGBtxeObjectNumber.h"
#import "SGBtxeObjectIcon.h"
#import "SGBtxePlaceholder.h"
#import "SGBtxeObjectOperator.h"

const NSString *matchNumbers=@"0123456789";

@implementation SGBtxeParser

-(SGBtxeParser*)initWithGameObject:(id<Parser, Container>)aGameObject
{
    if(self=[super initWithGameObject:(SGGameObject*)aGameObject])
    {
        ParentGO=aGameObject;
    }
    return self;
}

-(void)parseXML:(NSString*)xmlString
{
    NSString *fullxml=[NSString stringWithFormat:@"<?xml version='1.0'?><root xmlns:b='http://zubi.me/namespaces/2012/BTXE'>%@</root>", xmlString];
    
    CXMLDocument *doc=[[[CXMLDocument alloc] initWithXMLString:fullxml options:0 error:nil] autorelease];

    NSDictionary *nsmap=@{ @"" : MML_NAMESPACE, @"b" : BTXE_NAMESPACE };
    
    for (CXMLElement *e in doc.rootElement.children)
    {
        [self parseElement:e withNSMap:nsmap];
    }
}

-(BOOL)doesStringContainNumber:(NSString*)theString
{
    for(int i=0; i<theString.length; i++)
    {
        NSString *s=[theString substringWithRange:NSMakeRange(i, 1)];
        if([matchNumbers rangeOfString:s].location!=NSNotFound)
        {
            return YES;
        }
    }
    return NO;
}

-(void)parseElement:(CXMLElement*)element withNSMap:(NSDictionary*)nsmap
{
//    NSLog(@"parsing element %@", element.name);
    
    if([element.name isEqualToString:BTXE_T])
    {
        NSString *fulltext=[element stringValue];
        NSArray *strings=[fulltext componentsSeparatedByString:@" "];
        
        for(NSString *s in strings)
        {
            //is this word a number
            if([self doesStringContainNumber:s])
            {
                //create object number, have it parsed
                SGBtxeObjectNumber *on=[[[SGBtxeObjectNumber alloc] initWithGameWorld:gameWorld] autorelease];
                
                NSString *sepEndChar=@"?!.,:;";
                NSString *newNextT=nil;
                if([sepEndChar rangeOfString:[s substringFromIndex:s.length-1]].location!=NSNotFound)
                {
                    newNextT=[s substringFromIndex:s.length-1];
                    s=[s substringToIndex:s.length-1];
                }

                on.text=s;
                on.enabled=YES;
                on.interactive=NO;

                [ParentGO.containerMgrComponent addObjectToContainer:on];
                
                
                if(newNextT)
                {
                    //set no trailing space on number
                    on.disableTrailingPadding=YES;
                    
                    //create text
                    SGBtxeText *t=[[[SGBtxeText alloc] initWithGameWorld:gameWorld] autorelease];
                    t.text=newNextT;
                    [ParentGO.containerMgrComponent addObjectToContainer:t];
                }
            }
            else
            {
                //create text
                SGBtxeText *t=[[[SGBtxeText alloc] initWithGameWorld:gameWorld] autorelease];
                t.text=s;
                [ParentGO.containerMgrComponent addObjectToContainer:t];
            }
        }
    }
    else if([element.name isEqualToString:BTXE_OT])
    {
        SGBtxeObjectText *ot=[[[SGBtxeObjectText alloc] initWithGameWorld:gameWorld] autorelease];
        ot.text=[element stringValue];
        CXMLNode *tagNode=[element attributeForName:@"tag"];
        if(tagNode)ot.tag=tagNode.stringValue;
        
        ot.enabled=[self enabledBoolFor:element];
        
        CXMLNode *hidden=[element attributeForName:@"hidden"];
        if(hidden)ot.hidden=[[[hidden stringValue] lowercaseString] isEqualToString:@"yes"];
        
        //also disable if a number picker
        if([self boolFor:@"picker" on:element]) ot.enabled=NO;
        
        [ParentGO.containerMgrComponent addObjectToContainer:ot];
    }
    
    else if([element.name isEqualToString:BTXE_OBJ])
    {
        //create text
        SGBtxeText *t=[[[SGBtxeText alloc] initWithGameWorld:gameWorld] autorelease];
        t.text=@"object";
        
        CXMLNode *count=[element attributeForName:@"count"];
        if(count)
        {
            int c=[[count stringValue] intValue];
            if(c>1) t.text=@"objects";
        }
        
        [ParentGO.containerMgrComponent addObjectToContainer:t];
    }
    
    else if([element.name isEqualToString:BTXE_OO])
    {
        SGBtxeObjectOperator *oo=[[[SGBtxeObjectOperator alloc] initWithGameWorld:gameWorld] autorelease];
        CXMLNode *opNode=[element attributeForName:@"value"];
        if(opNode)oo.valueOperator=opNode.stringValue;
        
        CXMLNode *hidden=[element attributeForName:@"hidden"];
        if(hidden)oo.hidden=[[[hidden stringValue] lowercaseString] isEqualToString:@"yes"];
        
        oo.enabled=[self enabledBoolFor:element];
        [ParentGO.containerMgrComponent addObjectToContainer:oo];
    }
    
    else if([element.name isEqualToString:BTXE_OI])
    {
        SGBtxeObjectIcon *oi=[[[SGBtxeObjectIcon alloc] initWithGameWorld:gameWorld] autorelease];
        CXMLNode *tagNode=[element attributeForName:@"tag"];
        if(tagNode)oi.tag=tagNode.stringValue;
        CXMLNode *iconTagNode=[element attributeForName:@"icontag"];
        if(iconTagNode)oi.iconTag=iconTagNode.stringValue;
        
        CXMLNode *hidden=[element attributeForName:@"hidden"];
        if(hidden)oi.hidden=[[[hidden stringValue] lowercaseString] isEqualToString:@"yes"];
        
        oi.enabled=[self enabledBoolFor:element];
        
        [ParentGO.containerMgrComponent addObjectToContainer:oi];
    }
    
    else if([element.name isEqualToString:BTXE_COMMOT])
    {
        //for now parse commot to a regular ot, using the sample text and the preference tag
        
        SGBtxeObjectText *ot=[[[SGBtxeObjectText alloc] initWithGameWorld:gameWorld] autorelease];
        ot.text=[[element attributeForName:@"sample"] stringValue];
        
        CXMLNode *hidden=[element attributeForName:@"hidden"];
        if(hidden)ot.hidden=[[[hidden stringValue] lowercaseString] isEqualToString:@"yes"];
        
        CXMLNode *tagNode=[element attributeForName:@"preftag"];
        if(tagNode)ot.tag=tagNode.stringValue;
        
        ot.enabled=NO;

        [ParentGO.containerMgrComponent addObjectToContainer:ot];
    }
    
    else if ([element.name isEqualToString:BTXE_ON])
    {
        NSNumberFormatter *nf=[[NSNumberFormatter alloc] init];
        
        SGBtxeObjectNumber *on=[[[SGBtxeObjectNumber alloc] initWithGameWorld:gameWorld] autorelease];
        on.numberText=[[element attributeForName:@"number"] stringValue];
        on.prefixText=[[element attributeForName:@"prefix"] stringValue];
        on.suffixText=[[element attributeForName:@"suffix"] stringValue];
        
        CXMLNode *num=[element attributeForName:@"numerator"];
        if(num)
        {
            on.numerator=[nf numberFromString:[num stringValue]];
            on.denominator=[nf numberFromString:[[element attributeForName:@"denominator"] stringValue]];
            
            CXMLNode *value=[element attributeForName:@"value"];
            if(value) on.numberValue=[nf numberFromString:[value stringValue]];
            else on.numberValue=[NSNumber numberWithFloat:[on.numerator floatValue] / [on.denominator floatValue]];
            
            CXMLNode *showAsMF=[element attributeForName:@"showAsMixedFraction"];
            if(showAsMF)
            {
                on.showAsMixedFraction=[[[showAsMF stringValue] lowercaseString] isEqualToString:@"yes"];
            }
            else
            {
                on.showAsMixedFraction=NO;
            }
        }
        else
        {
            //value is also used for percentages (for example)
            CXMLNode *value=[element attributeForName:@"value"];
            if(value) on.numberValue=[nf numberFromString:[value stringValue]];
        }
        
        CXMLNode *pickerNumerator=[element attributeForName:@"pickerTargetNumerator"];
        if(pickerNumerator)
        {
            on.pickerTargetNumerator=[nf numberFromString:[pickerNumerator stringValue]];
            on.pickerTargetDenominator=[nf numberFromString:[[element attributeForName:@"pickerTargetDenominator"] stringValue]];
        }
        
        CXMLNode *hidden=[element attributeForName:@"hidden"];
        if(hidden)on.hidden=[[[hidden stringValue] lowercaseString] isEqualToString:@"yes"];
        
        CXMLNode *usepicker=[element attributeForName:@"usePicker"];
        if(usepicker)
        {
            on.usePicker=[[[usepicker stringValue] lowercaseString] isEqualToString:@"yes"];
        
            NSString *at=[[element attributeForName:@"pickerTarget"] stringValue];
            NSNumber *n=[nf numberFromString:at];
            on.targetNumber=[n floatValue];
        }
        
        if([element attributeForName:@"numbermode"])
            on.numberMode=[[element attributeForName:@"numbermode"] stringValue];
        else
            on.numberMode=ParentGO.defaultNumbermode;
    
        on.enabled=[self enabledBoolFor:element];
        
        [nf release];
        
        [ParentGO.containerMgrComponent addObjectToContainer:on];
    }
    
    else if([element.name isEqualToString:BTXE_PH])
    {
        SGBtxePlaceholder *ph=[[[SGBtxePlaceholder alloc] initWithGameWorld:gameWorld] autorelease];
        
        ph.targetTag=[[element attributeForName:@"targetTag"] stringValue];
        
        [ParentGO.containerMgrComponent addObjectToContainer:ph];
    }
}

-(BOOL)enabledBoolFor:(CXMLElement *)e
{
    //this assumes element is enabled, unless explicitly disabled
    
    CXMLNode *enabled=[e attributeForName:@"enabled"];
    if(enabled)
    {
        return [[enabled.stringValue lowercaseString] isEqualToString:@"yes"];
    }
    else
    {
        return YES;
    }
}

-(BOOL)boolFor:(NSString *)key on:(CXMLElement*)e
{
    CXMLNode *att=[e attributeForName:key];
    if(att)
    {
        return [[att.stringValue lowercaseString] isEqualToString:@"yes"];
    }
    else
    {
        return NO;
    }
}

@end
