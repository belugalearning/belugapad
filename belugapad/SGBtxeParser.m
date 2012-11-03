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
    NSLog(@"parsing element %@", element.name);
    
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
                SGBtxeObjectNumber *on=[[SGBtxeObjectNumber alloc] initWithGameWorld:gameWorld];
                on.text=s;
                
                [ParentGO.containerMgrComponent addObjectToContainer:on];
            }
            else
            {
                //create text
                SGBtxeText *t=[[SGBtxeText alloc] initWithGameWorld:gameWorld];
                t.text=s;
                [ParentGO.containerMgrComponent addObjectToContainer:t];
            }
        }
    }
    else if([element.name isEqualToString:BTXE_OT])
    {
        SGBtxeObjectText *ot=[[SGBtxeObjectText alloc] initWithGameWorld:gameWorld];
        ot.text=[element stringValue];
        CXMLNode *tagNode=[element attributeForName:@"tag"];
        if(tagNode)ot.tag=tagNode.stringValue;
        
        ot.enabled=[self enabledBoolFor:element];
        
        //also disable if a number picker
        if([self boolFor:@"picker" on:element]) ot.enabled=NO;
        
        [ParentGO.containerMgrComponent addObjectToContainer:ot];
    }
    
    else if([element.name isEqualToString:BTXE_OI])
    {
        SGBtxeObjectIcon *oi=[[SGBtxeObjectIcon alloc] initWithGameWorld:gameWorld];
        CXMLNode *tagNode=[element attributeForName:@"tag"];
        if(tagNode)oi.tag=tagNode.stringValue;
        CXMLNode *iconTagNode=[element attributeForName:@"icontag"];
        if(iconTagNode)oi.iconTag=iconTagNode.stringValue;
        
        oi.enabled=[self enabledBoolFor:element];
        
        [ParentGO.containerMgrComponent addObjectToContainer:oi];
    }
    
    else if([element.name isEqualToString:BTXE_COMMOT])
    {
        //for now parse commot to a regular ot, using the sample text and the preference tag
        
        SGBtxeObjectText *ot=[[SGBtxeObjectText alloc] initWithGameWorld:gameWorld];
        ot.text=[[element attributeForName:@"sample"] stringValue];
        
        CXMLNode *tagNode=[element attributeForName:@"preftag"];
        if(tagNode)ot.tag=tagNode.stringValue;
        
        ot.enabled=NO;

        [ParentGO.containerMgrComponent addObjectToContainer:ot];
    }
    
    else if ([element.name isEqualToString:BTXE_OP])
    {
        //this isn't long term -- create as text for now
        
        SGBtxeText *t=[[SGBtxeText alloc] initWithGameWorld:gameWorld];
        t.text=[[element attributeForName:@"op"] stringValue];
        [ParentGO.containerMgrComponent addObjectToContainer:t];
    }
    
    else if ([element.name isEqualToString:BTXE_ON])
    {
        SGBtxeObjectNumber *on=[[SGBtxeObjectNumber alloc] initWithGameWorld:gameWorld];
        on.numberText=[[element attributeForName:@"number"] stringValue];
        on.prefixText=[[element attributeForName:@"prefix"] stringValue];
        on.suffixText=[[element attributeForName:@"suffix"] stringValue];
        
        on.enabled=[self enabledBoolFor:element];
        
        [ParentGO.containerMgrComponent addObjectToContainer:on];
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
