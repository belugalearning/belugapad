//
//  ToolTemplateSG.m
//  belugapad
//
//  Created by Gareth Jenkins on 23/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ExprBuilder.h"

#import "UsersService.h"
#import "LoggingService.h"
#import "ToolHost.h"

#import "global.h"
#import "BLMath.h"

#import "AppDelegate.h"

#import "SGGameWorld.h"

#import "SGBtxeRow.h"
#import "SGBtxeText.h"
#import "SGBtxeObjectText.h"
#import "SGBtxeMissingVar.h"
#import "SGBtxeContainerMgr.h"
#import "SGBtxeObjectNumber.h"
#import "SGBtxeProtocols.h"
#import "SGBtxeObjectOperator.h"
#import "SGBtxePlaceholder.h"
#import "BAExpressionHeaders.h"
#import "BAExpressionTree.h"
#import "BATQuery.h"
#import "SimpleAudioEngine.h"
#import "NumberWheel.h"

#define AUTO_LARGE_ROW_X_MAX 5
#define AUTO_LARGE_ROW_Y_MAX 3

@interface ExprBuilder()
{
@private
    LoggingService *loggingService;
    ContentService *contentService;
    
    UsersService *usersService;
    
    //game world
    SGGameWorld *gw;

}

@end

@implementation ExprBuilder

#pragma mark - scene setup
-(id)initWithToolHost:(ToolHost *)host andProblemDef:(NSDictionary *)pdef
{
    toolHost=host;
    
    if(self=[super init])
    {
        //this will force override parent setting
        //TODO: is multitouch actually required on this tool?
        [[CCDirector sharedDirector] view].multipleTouchEnabled=NO;
        
        CGSize winsize=[[CCDirector sharedDirector] winSize];
        winL=CGPointMake(winsize.width, winsize.height);
        lx=winsize.width;
        ly=winsize.height;
        cx=lx / 2.0f;
        cy=ly / 2.0f;

        self.BkgLayer=[[[CCLayer alloc]init] autorelease];
        self.ForeLayer=[[[CCLayer alloc]init] autorelease];
        
        [toolHost addToolBackLayer:self.BkgLayer];
        [toolHost addToolForeLayer:self.ForeLayer];
        
        renderLayer = [[CCLayer alloc] init];
        [self.ForeLayer addChild:renderLayer];

        gw = [[SGGameWorld alloc] initWithGameScene:renderLayer];
        gw.Blackboard.inProblemSetup = YES;
        
        expressionStringCache=[[NSMutableArray alloc] init];
        
        AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
        contentService = ac.contentService;
        usersService = ac.usersService;
        loggingService = ac.loggingService;
        
        rows=[[NSMutableArray alloc]init];
        
        [self readPlist:pdef];
        [self populateGW];
        
        
        gw.Blackboard.inProblemSetup = NO;
        
    }
    
    return self;
}

#pragma mark - loops

-(void)doUpdate:(ccTime)delta
{
    if(autoMoveToNextProblem)
    {
        timeToAutoMoveToNextProblem+=delta;
        if(timeToAutoMoveToNextProblem>=kTimeToAutoMove)
        {
            self.ProblemComplete=YES;
            autoMoveToNextProblem=NO;
            timeToAutoMoveToNextProblem=0.0f;
        }
    }   
}

-(void)draw
{
    
}

#pragma mark - gameworld setup and population
-(void)readPlist:(NSDictionary*)pdef
{
    
    // All our stuff needs to go into vars to read later
    
    evalMode=[[pdef objectForKey:EVAL_MODE] intValue];
    rejectType = [[pdef objectForKey:REJECT_TYPE] intValue];
    evalType=[[pdef objectForKey:EVAL_TYPE]retain];
    
    if([pdef objectForKey:@"EXPR_STAGES"])
    {
        exprStages=[[pdef objectForKey:@"EXPR_STAGES"] copy];
    }
    else
    {
        @throw [NSException exceptionWithName:@"expr plist read exception" reason:@"EXPR_STAGES not found" userInfo:nil];
    }
    
    if([evalType isEqualToString:@"SEQUENCE_ASC"] || [evalType isEqualToString:@"SEQUENCE_DESC"])
        isSequencing=YES;
    else
        isSequencing=NO;
    
    NSNumber *rrow2=[pdef objectForKey:@"REPEAT_ROW2_X"];
    if(rrow2)repeatRow2Count=[rrow2 intValue];
    
    NSNumber *urowmax=[pdef objectForKey:@"USER_REPEAT_ROW2_TOMAX_X"];
    if(urowmax)userRepeatRow2Max=[rrow2 intValue];
    
    NSNumber *ncardmin=[pdef objectForKey:@"NUMBER_CARD_ROW_MIN"];
    NSNumber *ncardmax=[pdef objectForKey:@"NUMBER_CARD_ROW_MAX"];
    NSNumber *ncardint=[pdef objectForKey:@"NUMBER_CARD_INTERVAL"];
    
    excludedEvalRows=[pdef objectForKey:@"EVAL_EXCLUDE_ROWS"];
    
    if([pdef objectForKey:@"NUMBER_PICKER_COLUMNS"])
        numberPickerColumns=[[pdef objectForKey:@"NUMBER_PICKER_COLUMNS"]intValue];
    else
        numberPickerColumns=3;
    
    [toolHost setPickerColumnCount:numberPickerColumns];
    
    if(ncardmax && ncardmin && ncardint)
    {
        presentNumberCardRow=YES;
        numberCardRowInterval=[ncardint intValue];
        numberCardRowMax=[ncardmax intValue];
        numberCardRowMin=[ncardmin intValue];
        
        NSNumber *ncardrandomise=[pdef objectForKey:@"NUMBER_CARD_RANDOMISE"];
        if(ncardrandomise)numberCardRandomOrder=[ncardrandomise boolValue];
        
        NSNumber *ncardselectionof=[pdef objectForKey:@"NUMBER_CARD_PICK_RANDOM_SELECTION_OF"];
        if(ncardselectionof)numberCardRandomSelectionOf=[ncardselectionof intValue];
    }
    
    if([evalType isEqualToString:@"SEQUENCE_ASC"] || [evalType isEqualToString:@"SEQUENCE_DESC"])
    {
        expressionRowsAreLarge=YES;
    }
    
    if([pdef objectForKey:@"NUMBER_MODE"])
        numberMode=[pdef objectForKey:@"NUMBER_MODE"];
    else
        numberMode=@"numeral";
}

-(void)populateGW
{
    gw.Blackboard.RenderLayer = renderLayer;
    
    //TODO test for description and insert at first row (0), and increate rowOffset
    
    //number of expression stages
    int rowcount=[exprStages count];
    
    //repeat number of expressions stages
    if(repeatRow2Count>0 && rowcount==2) rowcount=repeatRow2Count+1;
    
    float row0base=2*cy;
    float rowSpace=row0base / (rowcount+1);
    
    // iterate and create rows
    for(int i=0; i<rowcount; i++)
    {
        SGBtxeRow *row=[[SGBtxeRow alloc] initWithGameWorld:gw andRenderLayer:self.ForeLayer];
        [rows addObject:row];
        
        if(i==0)
            row.myAssetType=@"Small";
        else
            row.myAssetType=@"Medium";
        
        
        if([evalType isEqualToString:@"SEQUENCE_ASC"] || [evalType isEqualToString:@"SEQUENCE_DESC"])
        {
            row.backgroundType=@"Card";
            row.tintMyChildren=NO;
        }
        
        if(numberMode)
            row.defaultNumbermode=numberMode;
        
        if(i==0 || repeatRow2Count==0)
        {
            [row parseXML:[exprStages objectAtIndex:i]];
        }
        else if (repeatRow2Count>0)
        {
            [row parseXML:[exprStages objectAtIndex:1]];
        }
        
        if([evalType isEqualToString:@"SEQUENCE_ASC"] || [evalType isEqualToString:@"SEQUENCE_DESC"])
        {
            //limit row to even division of cards
            if(row.children.count>5 && i>0)
            {
                if(row.children.count==9 || row.children.count==18) row.maxChildrenPerLine=3;
                else if(row.children.count==8) row.maxChildrenPerLine=4;
                else if(row.children.count==10 || row.children.count==15) row.maxChildrenPerLine=5;
                else if (row.children.count==11) row.maxChildrenPerLine=6;
                else if(row.children.count==12)row.maxChildrenPerLine=6;
            }
        }
        
        if(i>0 && rowcount<=AUTO_LARGE_ROW_Y_MAX && [row.children count]<=AUTO_LARGE_ROW_X_MAX)
            row.myAssetType = @"Large";
        
//        if(i>0 && expressionRowsAreLarge)
//            row.myAssetType = @"Large";
        
        
        if(i==0)
        {
            descRow=row;
            //position at top, top aligned, with spacer underneath
            row.position=ccp(cx, (cy*2) - 115);
            row.forceVAlignTop=YES;
            
            //question separator bar -- flow with bottom of row 0
            CCSprite *questionSeparatorSprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/menu/Question_Separator.png")];
            [self.ForeLayer addChild:questionSeparatorSprite];
            [questionSeparatorSprite setVisible:NO];
            
            sepYpos=row.position.y - row.size.height / 2.0f - (QUESTION_SEPARATOR_PADDING * 2.0f);
            
            row0base=sepYpos;
            rowSpace=row0base / (rowcount + 1);
        }
        else
        {
            //distribute in available space
            row.position = ccp(cx, row0base - (i*rowSpace));
        }
        
        
        [row setupDraw];

        if(i==0)
        {
            sepYpos=row.position.y - row.size.height - (QUESTION_SEPARATOR_PADDING * 2.0f);
            
            row0base=sepYpos;
            rowSpace=row0base / (rowcount + 1);
        }
        
        
        //build the ncard row if we have one
        if(presentNumberCardRow && i==0)
        {
            //this ivar is released in dealloc, but only if set
            //should really be property based -- this assumes this is the only place it's alloc'd
            ncardRow=[[SGBtxeRow alloc] initWithGameWorld:gw andRenderLayer:self.ForeLayer];
            ncardRow.maxChildrenPerLine=10;
            
            if([evalType isEqualToString:@"SEQUENCE_ASC"] || [evalType isEqualToString:@"SEQUENCE_DESC"])
            {
                ncardRow.backgroundType=@"Card";
                ncardRow.tintMyChildren=NO;
            }
            
            NSMutableArray *cardAddBuffer=[[NSMutableArray alloc] init];
            
            //add the cards
            for(int icard=numberCardRowMin; icard<=numberCardRowMax; icard+=numberCardRowInterval)
            {
                SGBtxeObjectNumber *n=[[SGBtxeObjectNumber alloc] initWithGameWorld:gw];
                n.numberText=[NSString stringWithFormat:@"%d", icard];
                n.enabled=YES;
                
                [cardAddBuffer addObject:n];
                [n release];
            }
            
            if(numberCardRandomOrder || numberCardRandomSelectionOf>0)
            {
                int selmax=numberCardRandomSelectionOf>0? numberCardRandomSelectionOf : cardAddBuffer.count;
                int added=0;
                
                while(cardAddBuffer.count>0 && added<selmax)
                {
                    int i=(arc4random()%cardAddBuffer.count);
                    [ncardRow.containerMgrComponent addObjectToContainer:[cardAddBuffer objectAtIndex:i]];
                    [cardAddBuffer removeObjectAtIndex:i];
                    
                    added++;
                }
            }
            else
            {
                for(SGBtxeObjectNumber *n in cardAddBuffer)
                    [ncardRow.containerMgrComponent addObjectToContainer:n];
            }
            
            //let go of the buffer
            [cardAddBuffer release];
            
            [ncardRow setupDraw];
            
            id<Bounding> row0=[rows objectAtIndex:0];
            float hoffset=row0.size.height;
            
            ncardRow.position=ccp(cx, ((cy*2) - 110) - hoffset - ncardRow.size.height / 2.0f);
            
            sepYpos= ncardRow.position.y-ncardRow.size.height / 2.0f - (QUESTION_SEPARATOR_PADDING * 3.0f);
            
            row0base=sepYpos-QUESTION_SEPARATOR_PADDING;
            rowSpace=row0base / (rowcount + 1);
        }
        
        [row release];
    }
    
    [descRow fadeInElementsFrom:1.0f andIncrement:0.1f];
    [self readOutProblemDescription];
    
    //if we have ncardrow, then add it to rows (at end for now?)
    if(ncardRow) [rows addObject:ncardRow];
    
    if([evalType isEqualToString:@"SEQUENCE_ASC"]||[evalType isEqualToString:@"SEQUENCE_DESC"])
    {
        [usersService notifyStartingFeatureKey:@"EXPRBUILDER_SEQUENCING_1"];
        [usersService notifyStartingFeatureKey:@"EXPRBUILDER_SEQUENCING_2"];
    }
    else{
        [usersService notifyStartingFeatureKey:@"EXPRBUILDER_SENTENCEBUILDER"];
    }
    
    
    for(id<MovingInteractive, NSObject> o in gw.AllGameObjects)
    {
        if([o conformsToProtocol:@protocol(MovingInteractive)])
        {
            
            if(o.enabled)
            {
                if([o conformsToProtocol:@protocol(NumberPicker)]) {
                    
                    id<NumberPicker,Text> opicker=(id<NumberPicker,Text>)o;
                    
                    if(opicker.usePicker){
                        [usersService notifyStartingFeatureKey:@"EXPRBUILDER_NUMBERPICKER"];
                        break;
                    }
                    
                }
                
            }
        }
    }
}

-(SGBtxeRow*)descRow
{
    return descRow;
}

-(float)getRowPosY
{
    return descRow.position.y;
}

-(float)getDescriptionAreaHeight
{
    if(isContracted)
        return (((cy*2) - 110) - sepYpos + 20.0f);
    else
        return (((cy*2) - 110) - sepYpos);
}

-(void)readOutProblemDescription
{
    SGBtxeRow *descRow2=[rows objectAtIndex:0];
    toolHost.thisProblemDescription=[descRow2 returnRowStringForSpeech];
    
//    [toolHost readOutProblemDescription];
}

-(void)contractDescAndCardRows
{
    isContracted=YES;
    [descRow animateAndMoveToPosition:ccp(345.0f, (cy*2)-115)];
    [descRow relayoutChildrenToWidth:600];
    float hoffset=descRow.size.height;
    [ncardRow animateAndMoveToPosition:ccp(345, ((cy*2) - 115) - hoffset - ncardRow.size.height / 2.0f)];
    [ncardRow relayoutChildrenToWidth:[toolHost questionTrayWidth]];
    
    [toolHost sizeQuestionDescription];
    [toolHost setReadProblemPosWithScale:0.65f];
}

-(void)expandDescAndCardRows
{
    isContracted=NO;
    float hoffset=descRow.size.height;
    
    if(descRow){
        [descRow animateAndMoveToPosition:ccp(cx, (cy*2) - 115)];
        [descRow relayoutChildrenToWidth:BTXE_ROW_DEFAULT_MAX_WIDTH];
    }
    if(ncardRow){
        [ncardRow animateAndMoveToPosition:ccp(cx, ((cy*2) - 115) - hoffset - ncardRow.size.height / 2.0f)];
        [ncardRow relayoutChildrenToWidth:[toolHost questionTrayWidth]];
    }
    
    [toolHost sizeQuestionDescription];
    [toolHost setReadProblemPosWithScale:1.0f];
}

#pragma mark - touches events
-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(isTouching)return;
    isTouching=YES;
    
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    //location=[self.ForeLayer convertToNodeSpace:location];
    lastTouch=location;
    
    BOOL gotPickerObject=NO;
    
    if(isHoldingObject) return;  // no multi-touch but let's be sure

    for(id<MovingInteractive, NSObject> o in gw.AllGameObjects)
    {
        if([o conformsToProtocol:@protocol(MovingInteractive)])
        {
            if(!o.interactive)continue;
            id<Bounding> obounding=(id<Bounding>)o;
            id<NumberPicker,Text> opicker=(id<NumberPicker,Text>)o;
            
            CGRect hitbox=CGRectMake(obounding.worldPosition.x - (BTXE_OTBKG_WIDTH_OVERDRAW_PAD + obounding.size.width) / 2.0f, obounding.worldPosition.y-BTXE_VPAD-(obounding.size.height / 2.0f), obounding.size.width + BTXE_OTBKG_WIDTH_OVERDRAW_PAD, obounding.size.height + 2*BTXE_VPAD);
            
            
            
            if(o.enabled && CGRectContainsPoint(hitbox, location))
            {
                NSLog(@"this hitbox = %@", NSStringFromCGRect(hitbox));
                [loggingService logEvent:BL_PA_EXPRBUILDER_TOUCH_START_PICKUP_CARD withAdditionalData:nil];
                heldObject=o;
                isHoldingObject=YES;
                if(isSequencing)
                    [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_sentence_builder_sequencing_sequencing_card_picked_up.wav")];
                else
                    [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_sentence_builder_sequencing_sentence_builder_object_picked_up.wav")];

                if([o conformsToProtocol:@protocol(NumberPicker)]) {
                
                    if(opicker.usePicker){
                        [loggingService logEvent:BL_PA_EXPRBUILDER_TOUCH_START_START_PICKER withAdditionalData:nil];
                        gotPickerObject=YES;
                        
                        if(toolHost.CurrentBTXE && toolHost.CurrentBTXE!=o){
                            
                            NSLog(@"returnedPickerNo %@, opicker.text %@", [toolHost returnPickerNumber], opicker.text);
                            
                            if(opicker.text&&[opicker.text isEqualToString:@"?"])
                                opicker.text=@"0";
                            
                                [toolHost updatePickerNumber:opicker.text];
 
                        }
                        
                        if(!opicker.pickerTargetNumerator)
                            toolHost.CurrentBTXE=o;
                        
                        if(opicker.pickerTargetNumerator)
                        {
                            if(!showingFractionPickers)
                            {
                                numberPickerColumns=3;
                                if(!pNumerator){
                                    pNumerator=[[NumberWheel alloc]init];
                                    pNumerator.RenderLayer=renderLayer;
                                    pNumerator.Components=numberPickerColumns;
                                    pNumerator.SpriteFileName=[NSString stringWithFormat:@"/images/numberwheel/NW_%d_ov.png",pNumerator.Components];
                                    pNumerator.UnderlaySpriteFileName=[NSString stringWithFormat:@"/images/numberwheel/NW_%d_ul.png", pNumerator.Components];
                                    pNumerator.Position=ccp(870,660);
                                    pNumerator.fractionPart=@"n";
                                    pNumerator.AssociatedObject=opicker;
                                    [pNumerator setupNumberWheel];
                                }
                                else
                                {
                                    pNumerator.AssociatedObject=opicker;
                                    [pNumerator showNumberWheel];
                                }
                                if(!pDenominator){
                                    pDenominator=[[NumberWheel alloc]init];
                                    pDenominator.RenderLayer=renderLayer;
                                    pDenominator.Components=numberPickerColumns;
                                    pDenominator.SpriteFileName=[NSString stringWithFormat:@"/images/numberwheel/NW_%d_ov.png",pDenominator.Components];
                                    pDenominator.UnderlaySpriteFileName=[NSString stringWithFormat:@"/images/numberwheel/NW_%d_ul.png", pDenominator.Components];
                                    pDenominator.Position=ccp(870,pNumerator.Position.y-170);
                                    pDenominator.fractionPart=@"d";
                                    pDenominator.AssociatedObject=opicker;
                                    pNumerator.fractionWheel=pDenominator;
                                    pDenominator.fractionWheel=pNumerator;
                                    [pDenominator setupNumberWheel];
                                }
                                else
                                {
                                    pDenominator.AssociatedObject=opicker;
                                    [pDenominator showNumberWheel];
                                }
                                
                                //do what parser does
                                //set numerator/denominator to numbers
                                // set value
                                // do math for value
                                // comparison
                                // text to return ?
                                
                                NSLog(@"show fraction picker");
                            }
                            else
                            {
                                [pNumerator hideNumberWheel];
                                [pDenominator hideNumberWheel];
                                NSLog(@"hide fraction picker");                               
                            }
                            showingFractionPickers=!showingFractionPickers;
                        }
                        
                        if(!toolHost.pickerView && toolHost.CurrentBTXE)
                        {
                            [self contractDescAndCardRows];
                            
                        }
                        
                        if(toolHost.pickerView && toolHost.CurrentBTXE)
                        {
                            
//                            if(!opicker.pickerTargetNumerator)
//                            {
                                [toolHost showWheel];
                                [toolHost showCornerTray];
//                            }
//                            else
//                            {
//                                NSLog(@"we dun has 2 wheels hawh");
//                            }
                            
                            [self contractDescAndCardRows];
                        }
                    }
                    else
                    {
                        if(toolHost.pickerView && toolHost.CurrentBTXE)
                        {
                            [toolHost tearDownNumberPicker];
                            [self expandDescAndCardRows];
                            [toolHost hideCornerTray];
                            toolHost.CurrentBTXE=nil;
                        }
                        if(showingFractionPickers)
                        {
                            [pNumerator hideNumberWheel];
                            [pDenominator hideNumberWheel];
                            showingFractionPickers=NO;
                        }
                    }
                }
                [(id<MovingInteractive>)o inflateZIndex];
                
                for(SGBtxeRow *r in rows)
                {
                    if([r containsObject:o]) [r inflateZindex];
                }
            }
        }
    }
    
    if(!showingFractionPickers && (!gotPickerObject || !isHoldingObject) && !CGRectContainsPoint(CGRectMake(650,480,374,328), location)){
        toolHost.CurrentBTXE=nil;

        if(toolHost.pickerView){
            [self expandDescAndCardRows];
            [toolHost disableWheel];
            [toolHost hideCornerTray];
            [loggingService logEvent:BL_PA_EXPRBUILDER_TOUCH_START_HIDE_PICKER withAdditionalData:nil];
        }
    }
    else if(showingFractionPickers && (!gotPickerObject || !isHoldingObject) && !CGRectContainsPoint(CGRectMake(650,380,374,388), location)){

            [pNumerator hideNumberWheel];
            [pDenominator hideNumberWheel];
            showingFractionPickers=NO;
    }
}

-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    location=[self.ForeLayer convertToNodeSpace:location];
    
    lastTouch=location;

    if(isHoldingObject && !toolHost.CurrentBTXE)
    {
        //track that object's position
        heldObject.worldPosition=location;
        hasMovedObject=YES;
    }
}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    location=[self.ForeLayer convertToNodeSpace:location];
    isTouching=NO;
    
    
    float pickupProximity=BTXE_PICKUP_PROXIMITY;
    
    if(expressionRowsAreLarge)pickupProximity*=3;
    
    if(hasMovedObject)
    {
        [loggingService logEvent:BL_PA_EXPRBUILDER_TOUCH_MOVE_MOVED_CARD withAdditionalData:nil];
        hasMovedObject=NO;
    }
    
    if(heldObject)
    {
        //test new location for target / drop
        for(id<Interactive, NSObject> o in [gw AllGameObjectsCopy])
        {
            if([o conformsToProtocol:@protocol(Interactive)])
            {
                if(!o.enabled
                   && [heldObject.tag isEqualToString:o.tag]
                   && [BLMath DistanceBetween:o.worldPosition and:location]<=pickupProximity)
                {
                    //this object is proximate, disabled and the same tag
                    [o activate];
                }
                
                if([o conformsToProtocol:@protocol(BtxeMount)])
                {
                    id<BtxeMount, Interactive> pho=(id<BtxeMount, Interactive>)o;
                    CGRect objRect=[pho returnBoundingBox];
                    
                    if(CGRectContainsPoint(objRect, location)){
                        if(!toolHost.CurrentBTXE){
                            [pho duplicateAndMountThisObject:(id<MovingInteractive, NSObject>)heldObject];
                            if(isSequencing)
                                [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_sentence_builder_sequencing_sentence_builder_object_dropped.wav")];
                            else
                                [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_sentence_builder_sequencing_sequencing_card_dropped.wav")];
                            [loggingService logEvent:BL_PA_EXPRBUILDER_TOUCH_END_DROP_CARD_PLACEHOLDER withAdditionalData:nil];
                        }
                    }
                    //mount the object on the place holder
                }
            }
        }

        if([heldObject.mount isKindOfClass:[SGBtxePlaceholder class]])
        {
            //[(SGBtxePlaceholder*)heldObject.mount setContainerVisible:YES];
            [heldObject destroy];
            
            if(isSequencing)
                [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_sentence_builder_sequencing_sentence_builder_object_fly_back.wav")];
            else
                [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_sentence_builder_sequencing_sequencing_card_flying_back_(on_replacement).wav")];
            
            [loggingService logEvent:BL_PA_EXPRBUILDER_TOUCH_END_DROP_CARD_EMPTY_SPACE withAdditionalData:nil];
        }
        else
        {
            [heldObject returnToBase];
        }
        [heldObject deflateZindex];
        for(SGBtxeRow *r in rows)
        {
            [r deflateZindex];
        }
        
        heldObject=nil;
        isHoldingObject=NO;
    }
}

-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    isTouching=NO;
    hasMovedObject=NO;
    toolHost.CurrentBTXE=nil;
    // empty selected objects
    
    if(heldObject)
        [heldObject deflateZindex];
    
    for(SGBtxeRow *r in rows)
    {
        [r deflateZindex];
    }
}

#pragma mark - evaluation
-(BOOL)evalExpression
{
    if([evalType isEqualToString:@"ALL_ENABLED"])
    {
        //check for interactive components that are disabled -- if in that mode
        for(SGGameObject *o in gw.AllGameObjects)
        {
            if([o conformsToProtocol:@protocol(Interactive)])
            {
                id<Interactive> io=(id<Interactive>)o;
                if(io.enabled==NO)
                {
                    //first disbled element fails the evaluation
                    return NO;
                }
            }
        }

        //none found, assume yes
        return YES;
    }
    
    if([evalType isEqualToString:@"ALL_PICKERS_CORRECT"])
    {
        //check for interactive components that are disabled -- if in that mode
        for(SGGameObject *o in gw.AllGameObjects)
        {
            if([o conformsToProtocol:@protocol(NumberPicker)])
            {
                id<NumberPicker, Value> io=(id<NumberPicker, Value>)o;
                if(io.usePicker)
                {
                    if(io.pickerTargetNumerator)
                    {
                        if([io.pickerTargetNumerator intValue] != [io.numerator intValue] ||
                           [io.pickerTargetDenominator intValue] != [io.pickerTargetDenominator intValue])
                        {
                            //as per int comparison, first non-matchin element fails evaluation
                            return NO;
                        }
                    }
                    else if((int)io.targetNumber != [io.value intValue])
                    {
                        //first non matching target element fails the evaluation
                        return NO;
                    }
                }
            }
        }
        
        //none found, assume yes
        return YES;
    }
    
    
    
    if([evalType isEqualToString:@"SEQUENCE_ASC"])
    {
        NSArray *vals=[self numbersFromRow:1];
        int phCount=[self getPlaceHolderCountOnRow:1];
        int popPhCount=[self getPopulatedPlaceholderCountOnRow:1];
        
        //fail if there are no numbers
        if(vals.count==0)return NO;
        
        //fail if not all of the placeholders have numbers
        if(phCount!=popPhCount) return NO;
        
        for(int i=1; i<vals.count; i++)
        {
            if ([[vals objectAtIndex:i-1] floatValue] >= [[vals objectAtIndex:i] floatValue]) {
                //last item was great than this item -- fail evaluation
                return NO;
            }
        }
        
        return YES;
    }

    if([evalType isEqualToString:@"SEQUENCE_DESC"])
    {
        NSArray *vals=[self numbersFromRow:1];
        int phCount=[self getPlaceHolderCountOnRow:1];
        int popPhCount=[self getPopulatedPlaceholderCountOnRow:1];
        
        //fail if there are no numbers
        if(vals.count==0)return NO;
        
        //fail if not all of the placeholders have numbers
        if(phCount!=popPhCount) return NO;
        
        for(int i=1; i<vals.count; i++)
        {
            if ([[vals objectAtIndex:i-1] floatValue] <= [[vals objectAtIndex:i] floatValue]) {
                //last item was less than this item -- fail evaluation
                return NO;
            }
        }
        
        return YES;
    }
    
    if([evalType isEqualToString:@"EXPRESSION_EQUALITIES"])
    {
        //check for an equality on all but the first expression
        for(int i=1; i<rows.count; i++)
        {
            BOOL doEval=YES;
            if(excludedEvalRows)
            {
                for(id row in excludedEvalRows)
                {
                    if([row isEqualToString:[NSString stringWithFormat:@"%d", i+1]])
                        doEval=NO;
                }
            }
            
            if(doEval)
            {
                SGBtxeRow *row=[rows objectAtIndex:i];
                if(row!=ncardRow)
                {
                    if([self parseContainerToEqualityAndEval:row]==NO) return NO;
                }
            }
        }
        
        return YES;
    };
    
    if([evalType isEqualToString:@"EXPRESSION_EQUALITIES_NOT_IDENTICAL"])
    {
        [expressionStringCache removeAllObjects];
        
        //check for equality on rows and check that the expressions are different
        for(int i=1; i<rows.count; i++)
        {
            BOOL doEval=YES;
            if(excludedEvalRows)
            {
                for(id row in excludedEvalRows)
                {
                    if([row isEqualToString:[NSString stringWithFormat:@"%d", i+1]])
                        doEval=NO;
                }
            }
            
            if(doEval)
            {
            
                SGBtxeRow *row=[rows objectAtIndex:i];
                if(row!=ncardRow)
                {
                    if([self parseContainerToEqualityAndEval:row]==NO) return NO;
                    NSLog(@"parsed row");
                }
            }
        }
        
        for(NSString *expr1 in expressionStringCache)
        {
            for(NSString *expr2 in expressionStringCache)
            {
                if(expr2!=expr1)
                {
                    if([expr2 isEqualToString:expr1])
                    {
                        return NO;
                    }
                }
            }
        }
        
        return YES;
    }
    
    else
    {
        return NO;
    }
}

-(BOOL)parseContainerToEqualityAndEval:(id<Container>)cont
{
    tokens=[[[NSMutableArray alloc]init] autorelease];
    
    curToken=nil;
    curTokenIdx=-1;
    
    for(id v in cont.children)
    {
        if([v conformsToProtocol:@protocol(MovingInteractive)])
        {
            id<MovingInteractive> vmountable=(id<MovingInteractive>)v;
            if(!vmountable.mount)
            {
                [self tokeniseObject:v];
            }
        }
        else if([v conformsToProtocol:@protocol(BtxeMount)])
        {
            id<BtxeMount> vc=(id<BtxeMount>)v;
            if(vc.mountedObject)
            {
                [self tokeniseObject:vc.mountedObject];
            }
            else
            {
                //fail the evaluation
                return NO;
            }
        }
        else
        {
            [self tokeniseObject:v];
        }
    }
    
    [self getNextToken];
//    NSString *res=[self computeExpr:0];
//    NSLog(@">>>>> result: %@", res);
    
    BAExpression *root=[self computeBaeExpr:0];
    BOOL ret=NO;
    
    //only try and evaluate if there's an equality at the top of the tree
    if([root isKindOfClass:[BAEqualsOperator class]])
    {
        BAExpressionTree *tree=[BAExpressionTree treeWithRoot:root];
        BATQuery *q=[[BATQuery alloc] initWithExpr:root andTree:tree];
        
        NSLog(@"evaluating equality for \n%@", [root xmlStringValueWithPad:@" "]);
        ret=[q assumeAndEvalEqualityAtRoot];
        
        [expressionStringCache addObject:[root xmlStringValueWithPad:@""]];
        
        [q release];
    }
    
//    [tokens release];
    
    return ret;
}

-(void)tokeniseObject:(id)v
{
    if([v conformsToProtocol:@protocol(Value)])
    {
        id<Value> vv=(id<Value>)v;
        [tokens addObject:@{@"token":@"NUMBER", @"value": [vv.value stringValue]}];
    }
    
    else if([v conformsToProtocol:@protocol(ValueOperator)])
    {
        id<ValueOperator> vop=(id<ValueOperator>)v;
        
        if([vop.valueOperator isEqualToString:@"="])
        {
            [tokens addObject:@{@"token":@"BINOP", @"value":@"="}];
        }
        else if([vop.valueOperator isEqualToString:@"*"] || [vop.valueOperator isEqualToString:@"x"])
        {
            [tokens addObject:@{@"token":@"BINOP", @"value":@"*"}];
        }
        else if([vop.valueOperator isEqualToString:@"/"])
        {
            [tokens addObject:@{@"token":@"BINOP", @"value":@"/"}];
        }
        else if([vop.valueOperator isEqualToString:@"+"])
        {
            [tokens addObject:@{@"token":@"BINOP", @"value":@"+"}];
        }
        else if([vop.valueOperator isEqualToString:@"-"])
        {
            [tokens addObject:@{@"token":@"BINOP", @"value":@"-"}];
        }
    }

}

-(NSString*)computeExpr:(int)minPrec
{
    NSString *atomLhs=[curToken objectForKey:@"value"];
    [self getNextToken];
    
    while(1)
    {
        NSDictionary *cur=curToken;
        
        if(!cur ||
           ![[cur objectForKey:@"token"] isEqualToString:@"BINOP"] ||
           [self getPrecendenceForToken:[cur objectForKey:@"value"]] < minPrec)
        {
            break;
        }
        
        NSString *op=[cur objectForKey:@"value"];
        int prec=[self getPrecendenceForToken:op];
        int nextminprec=prec+1;
        
        [self getNextToken];
        NSString *atomRhs=[self computeExpr:nextminprec];
        atomLhs=[NSString stringWithFormat:@"|%@%@%@|", atomLhs, op, atomRhs];
    }
    
    NSLog(@">> %@ >> %d", atomLhs, minPrec);
    
    return atomLhs;
}


-(BAExpression*)computeBaeExpr:(int)minPrec
{
    BAExpression *atomLeft=[BAInteger integerWithIntValue:[[curToken objectForKey:@"value"] intValue]];
    [self getNextToken];
    
    while(1)
    {
        NSDictionary *cur=curToken;
        
        if(!cur ||
           ![[cur objectForKey:@"token"] isEqualToString:@"BINOP"] ||
           [self getPrecendenceForToken:[cur objectForKey:@"value"]] < minPrec)
        {
            break;
        }
        
        NSString *op=[cur objectForKey:@"value"];
        int prec=[self getPrecendenceForToken:op];
        int nextminprec=prec+1;
        
        [self getNextToken];
        BAExpression *atomRight=[self computeBaeExpr:nextminprec];

        atomLeft=[self buildAtomFromLeft:atomLeft right:atomRight andOperator:op];
    }
    
    return atomLeft;
}

-(BAExpression*)buildAtomFromLeft:(BAExpression*)left right:(BAExpression*)right andOperator:(NSString *)op
{
    BAExpression *root;
    
    if([op isEqualToString:@"-"])
    {
        if([right isKindOfClass:[BAInteger class]])
        {
            int intright=-[((BAInteger*)right) intValue];
            BAInteger *newright=[BAInteger integerWithIntValue:intright];
            root=[BAAdditionOperator operator];
            [root addChild:left];
            [root addChild:newright];
        }
        else
        {
            BAMultiplicationOperator *mult=[BAMultiplicationOperator operator];
            [mult addChild:[BAInteger integerWithIntValue:-1]];
            [mult addChild:right];
            
            root=[BAAdditionOperator operator];
            [root addChild:left];
            [root addChild:mult];
        }
    }
    else
    {
        root=[self baeFromOpString:op];
        [root addChild:left];
        [root addChild:right];
    }
    return root;
}

-(BAExpression*)baeFromOpString:(NSString*)opString
{
    if([opString isEqualToString:@"="]) return [BAEqualsOperator operator];
    if([opString isEqualToString:@"*"]) return [BAMultiplicationOperator operator];
    if([opString isEqualToString:@"/"]) return [BADivisionOperator operator];
    if([opString isEqualToString:@"+"]) return [BAAdditionOperator operator];
    return nil;
}

-(void)getNextToken
{
    if(curTokenIdx<=((int)[tokens count]))
    {
        curTokenIdx++;
       
        if(curTokenIdx<[tokens count]) curToken=[tokens objectAtIndex:curTokenIdx];
        else curToken=nil;
    }
}

-(int)getPrecendenceForToken:(NSString *)token
{
    if([token isEqualToString:@"="]) return 1;
    if([token isEqualToString:@"*"]) return 3;
    if([token isEqualToString:@"/"]) return 4;
    if([token isEqualToString:@"+"]) return 2;
    if([token isEqualToString:@"-"]) return 2;
    return 0;
}

-(int)getPlaceHolderCountOnRow:(int)rowIdx
{
    SGBtxeRow *row=[rows objectAtIndex:rowIdx];
    
    int count=0;
    
    for(id<BtxeMount, NSObject> mount in row.children)
    {
        if([mount conformsToProtocol:@protocol(BtxeMount)])
        {
            count++;
        }
    }
    return count;
}

-(int)getPopulatedPlaceholderCountOnRow:(int)rowIdx
{
    SGBtxeRow *row=[rows objectAtIndex:rowIdx];
    
    int count=0;
    
    for(id<BtxeMount, NSObject> mount in row.children)
    {
        if([mount conformsToProtocol:@protocol(BtxeMount)])
        {
            id<BtxeMount> m=(id<BtxeMount>)mount;
            if(m.mountedObject) count++;
        }
    }
    return count;
}

-(NSArray*)numbersFromRow:(int)rowIdx
{
    SGBtxeRow *row=[rows objectAtIndex:rowIdx];
    NSMutableArray *values=[[NSMutableArray alloc] init];
    
    //todo: look at placeholders and their value
    
    for(id<NSObject> rowitem in row.children)
    {
        if([rowitem conformsToProtocol:@protocol(BtxeMount)])
        {
            id<BtxeMount> mount=(id<BtxeMount>)rowitem;

            if(mount.mountedObject)
            {
                if([mount.mountedObject conformsToProtocol:@protocol(Value)])
                {
                    id<Value>obj=(id<Value>)mount.mountedObject;
                    [values addObject:obj.value];
                }
            }
        }
        
        else if([rowitem conformsToProtocol:@protocol(Value)] && [rowitem conformsToProtocol:@protocol(MovingInteractive)])
        {
            id<Value, MovingInteractive>miv=(id<MovingInteractive, Value>)rowitem;
            
            if(!miv.mount)
            {
                [values addObject:miv.value];
            }
        }
    }
    
    
    NSArray *ret=[NSArray arrayWithArray:values];
    [values release];
    return ret;
}

-(void)evalProblem
{
    BOOL isWinning=[self evalExpression];
    
    if(isWinning){
        [toolHost doWinning];
    }else{
        [self expandDescAndCardRows];
        [self resetProblem];
    }
}

#pragma mark - problem state
-(void)resetProblem
{
    [toolHost doIncomplete];
    [toolHost resetProblem];
}

#pragma mark - meta question
-(float)metaQuestionTitleYLocation
{
    return kLabelTitleYOffsetHalfProp*cy;
}

-(float)metaQuestionAnswersYLocation
{
    return kMetaQuestionYOffsetPlaceValue*cy;
}

-(void)userDroppedBTXEObject:(id)thisObject atLocation:(CGPoint)thisLocation
{
    
}

#pragma mark - dealloc
-(void) dealloc
{
    [exprStages release];
    [evalType release];
    
    ///this is a managed ivar -- only set when used
    if(ncardRow)[ncardRow release];
    
    [rows release];
    
    //write log on problem switch
    
    [renderLayer release];
    
    [expressionStringCache release];
    
//    [self.ForeLayer removeAllChildrenWithCleanup:YES];
//    [self.BkgLayer removeAllChildrenWithCleanup:YES];
    
    //tear down
    [gw release];
    
    [super dealloc];
}
@end
