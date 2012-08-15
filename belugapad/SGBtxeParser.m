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
    NSString *fullxml=[NSString stringWithFormat:@"<?xml version='1.0'?><root>%@</root>", xmlString];
    
    CXMLDocument *doc=[[[CXMLDocument alloc] initWithXMLString:fullxml options:0 error:nil] autorelease];

    NSDictionary *nsmap=@{ @"" : MML_NAMESPACE, @"b" : BTXE_NAMESPACE };
    
    for (CXMLElement *e in doc.rootElement.children)
    {
        [self parseElement:e withNSMap:nsmap];
    }
}

-(void)parseElement:(CXMLElement*)element withNSMap:(NSDictionary*)nsmap
{
    NSLog(@"parsing element %@", element.name);
    
    if([element.name isEqualToString:BTXE_T])
    {
        SGBtxeText *t=[[SGBtxeText alloc] initWithGameWorld:gameWorld];
        t.text=[element stringValue];
        [ParentGO.containerMgrComponent addObjectToContainer:t];
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
    else if ([element.name isEqualToString:BTXE_OP])
    {
        //this isn't long term -- create as text for now
        
        SGBtxeText *t=[[SGBtxeText alloc] initWithGameWorld:gameWorld];
        t.text=[[element attributeForName:@"op"] stringValue];
        [ParentGO.containerMgrComponent addObjectToContainer:t];
    }
}

-(BOOL)enabledBoolFor:(CXMLElement *)e
{
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
