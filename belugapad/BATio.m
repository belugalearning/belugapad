//
//  BATio.m
//  belugapad
//
//  Created by Gareth Jenkins on 13/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BATio.h"
#import "BAExpressionTree.h"
#import "BAExpressionHeaders.h"
#import "TouchXML.h"
#import "MathMLConsts.h"

@implementation BATio

+(BAExpressionTree *)loadTreeFromMathMLFile:(NSString*)filePath
{
    return [BATio loadTreeFromMathMLData:[NSData dataWithContentsOfFile:filePath]];
}

+(BAExpressionTree *)loadTreeFromMathMLData:(NSData*)xmlData
{
    CXMLDocument *doc=[[[CXMLDocument alloc] initWithData:xmlData options:0 error:nil] autorelease];
    
    NSDictionary *nsmap=[NSDictionary dictionaryWithObject:MML_NAMESPACE forKey:@""];
    
    CXMLElement *e1=[[[doc rootElement] nodesForXPath:@"*" namespaceMappings:nsmap error:nil] objectAtIndex:0];
    
    BAExpression *root=[self parseMathMLElement:(CXMLElement*)e1 withNSMap:nsmap];
    BAExpressionTree *tree=[BAExpressionTree treeWithRoot:root];
    
    return tree;
}

+(BAExpression *)parseMathMLElement:(CXMLElement*)element withNSMap:(NSDictionary*)nsmap
{
    BAExpression *expr=nil;

    if(element)
    {
        if([element.name isEqualToString:MML_APPLY])
        {
            //case the first child (the apply what / node type) and then add children (using nodes past the first)
            if([[element children] count]<1)
            {
//                DLog(@"no children found for apply");
            }
            else {
                NSArray *echildren=[element nodesForXPath:@"*" namespaceMappings:nsmap error:nil];
                CXMLElement *fchild=[echildren objectAtIndex:0];
                if([fchild.name isEqualToString:MML_EQ])
                {
                    expr=[BAEqualsOperator operator];
                }
                else if([fchild.name isEqualToString:MML_PLUS])
                {
                    expr=[BAAdditionOperator operator];
                }
                else if([fchild.name isEqualToString:MML_MINUS])
                {
//                    DLog(@"minus not currently supported in parser / engine");
                }
                else if([fchild.name isEqualToString:MML_TIMES])
                {
                    expr=[BAMultiplicationOperator operator];
                }
                else if([fchild.name isEqualToString:MML_DIVIDE])
                {
                    expr=[BADivisionOperator operator];
                }
                
                //parse and add children (past first)
                for (int i=1; i<[echildren count]; i++) {
                    [expr addChild:[self parseMathMLElement:[echildren objectAtIndex:i] withNSMap:nsmap]];
                }
            }
            
        }
        else if ([element.name isEqualToString:MML_CI])
        {
            //add a variable
            expr=[BAVariable variableWithName:element.stringValue];
            
        }
        else if ([element.name isEqualToString:MML_CN])
        {
            //add a number -- this is force casting to an integer regardless of defined type (e.g type="integer")
            expr=[BAInteger integerWithIntValue:[element.stringValue integerValue]];
        }
        else {
            //do nothing, we don't recognise or don't want this element
//            DLog(@"unrecognized element found in MathML parse: %@", element.name);
        }
    }
    
    return expr;
}

@end
