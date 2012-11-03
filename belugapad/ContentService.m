 //
//  ContentService.m
//  belugapad
//
//  Created by Nicholas Cartwright on 17/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ContentService.h"
#import "UsersService.h"
#import "LoggingService.h"
#import "global.h"
#import "AppDelegate.h"
#import "BAExpressionHeaders.h"
#import "BATio.h"
#import "Problem.h"
#import "ConceptNode.h"
#import "Pipeline.h"
#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"
#import "JSONKit.h"
#import "SSZipArchive.h"
#import "BLFiles.h"
#import "AdpInserter.h"

@interface ContentService()
{
@private
    BOOL useTestPipeline;
    
    // local test pipeline
    NSArray *testProblemList;
    NSUInteger currentPIndex;
    
    // kcm database pipelines
    FMDatabase *contentDatabase;
    
    // ref to current user service -- convenience, is also on app delegate
    // currently set (retreived from app delegate) on creation of an episode
    UsersService *usersService;
    
    // progression tracking
    int pipelineIndex;              //the index of the last inserted-into-episode problem
    int episodeIndex;               //the index of the user's position in the currently-populated episode
    
    NSString *episodeId;            //the id of this episode (generated by this class on episode start)
    
    NSString *currentPipelineId;    //the current tracking pipeline
    
    NSFileManager *fm;
    NSString *contentDir;
    
    //set repetition
    NSString *lastRepeatSet;
    NSMutableArray *repeatBuffer;
}
@property (nonatomic, readwrite, retain) NSURL *kcmServerBaseURL;
@property (nonatomic, readwrite, retain) Problem *currentProblem;
@property (nonatomic, readwrite, retain) NSDictionary *currentPDef;
@property (nonatomic, readwrite, retain) NSString *pathToTestDef;
@property (nonatomic, readwrite, retain) NSArray *currentPipeline;
@property (readwrite) float pipelineProblemAttemptBaseScore;
@end

@implementation ContentService

@synthesize kcmServerBaseURL;
@synthesize currentProblem;
@synthesize currentPDef;
@synthesize currentStaticPdef;
@synthesize pathToTestDef;
@synthesize fullRedraw;
@synthesize currentPipeline;
@synthesize currentEpisode;
@synthesize pipelineProblemAttemptBaseScore;

@synthesize resetPositionAfterTH;
@synthesize lastMapLayerPosition;

@synthesize lightUpProgressFromLastNode;
@synthesize currentNode;

#pragma mark - init and setup

// Designated initializer
-(id)initWithLocalSettings:(NSDictionary*)settings
{
    self = [super init];
    if (self)
    {
        self.kcmServerBaseURL = [NSURL URLWithString:@"http://authoring.zubi.me:3001/kcm/"];
        
        fm = [NSFileManager defaultManager];
        
        NSString *libraryDir=[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        
        contentDir = [[libraryDir stringByAppendingPathComponent:@"content"] retain];
        
        NSString *source = [settings objectForKey:@"PROBLEM_PIPELINE"];
        useTestPipeline = ![@"DATABASE" isEqualToString:source];
        
        if (useTestPipeline)
        {
            if([source rangeOfString:@".plist"].location!=NSNotFound)
            {
                //load from this array
                currentPIndex = NSUIntegerMax;
                testProblemList = [[NSArray arrayWithContentsOfFile:BUNDLE_FULL_PATH(source)] retain];
            } else {
                //build an array from this location
                currentPIndex = NSUIntegerMax;
                NSString *pathOfProblems=BUNDLE_FULL_PATH(source);
                NSArray *files=[[NSFileManager defaultManager] contentsOfDirectoryAtPath:pathOfProblems error:nil];
                
                NSMutableArray *allFilePaths=[[NSMutableArray alloc] init];
                
                for (int i=0; i<files.count; i++) {
                    [allFilePaths addObject:[pathOfProblems stringByAppendingPathComponent:[files objectAtIndex:i]]];
                }
                
                testProblemList=[NSArray arrayWithArray:allFilePaths];
                [testProblemList retain];
                
                [allFilePaths release];
            }

        } else {
            [self updateContentDatabaseWithSettings:settings];
        }
    }
    return self;
}

-(void)updateContentDatabaseWithSettings:(NSDictionary*)settings
{
    NSNumber *importContent = [settings objectForKey:@"IMPORT_CONTENT_ON_LAUNCH"];
    NSString *kcmLoginName = [settings objectForKey:@"KCM_LOGIN_NAME"];
    
    if (contentDatabase)
    {
        if (importContent && [importContent boolValue] && kcmLoginName)
        {
            [contentDatabase close];
            [contentDatabase release];
        } else {
            return; // no point continuing as this function was already called at init & would now def be replacing bundled database with itself
        }
    }
    
    NSError *error = nil;
    
    if (importContent && [importContent boolValue] && kcmLoginName)
    {
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"app-import-content/%@", kcmLoginName] relativeToURL:self.kcmServerBaseURL];
        NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
        NSHTTPURLResponse *response = nil;
        NSData *result = [NSURLConnection sendSynchronousRequest:req returningResponse:&response error:&error];
        
        if (error || !response || [response statusCode] != 200)
        {
            NSString *resultString = [[[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding] autorelease];
            NSLog(@"Failed to retrieve content from database. (Use Alert Box?) -- %@", resultString);
        } else {
            NSString *libDir = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
            NSString *zipPath = [libDir stringByAppendingPathComponent:@"/canned-content.zip"];
            [result writeToFile:zipPath atomically:YES];
            [SSZipArchive unzipFileAtPath:zipPath toDestination:contentDir];
        }
    }
    
    if (![fm fileExistsAtPath:contentDir])
    {
        error = nil;
        NSString *bundledContentDir = BUNDLE_FULL_PATH(@"/canned-dbs/canned-content");
        [fm copyItemAtPath:bundledContentDir toPath:contentDir error:&error];
    }

    //tested without import
//    NSError *error=nil;
//    NSString *bundledContentDir = BUNDLE_FULL_PATH(@"/canned-dbs/canned-content");
//    [fm copyItemAtPath:bundledContentDir toPath:contentDir error:&error];
    
    contentDatabase = [FMDatabase databaseWithPath:[contentDir stringByAppendingString:@"/content.db"]];
    [contentDatabase retain];    
}

#pragma mark - dynamic pipeline creation

-(BOOL) createAndStartFunnelForNode:(NSString*)nodeId
{
    //get node by id
    ConceptNode *n=[self conceptNodeForId:nodeId];
    
    if(n.mastery)
    {
        UsersService *us = ((AppController*)[[UIApplication sharedApplication] delegate]).usersService;    
        
        //step over child nodes and look for one that's not completed, if found start it's pipeline
        NSMutableArray *children=[self childNodesForMasteryWithId:nodeId];
        
        if(children.count==0)
        {
            NSLog(@"there are no children here");
            return NO;
        }
        
        for (ConceptNode *child in children) {
            if(![us hasCompletedNodeId:child._id])
            {
                if(child.pipelines.count>0)
                {
                    [self startPipelineWithId:[child.pipelines objectAtIndex:0] forNode:child];
                    
                    return YES;
                }
            }
        }
        
        //pick random child
        int ip=arc4random()%children.count;
        
        
        ConceptNode *child=[children objectAtIndex:ip];
    
        if(child.pipelines.count>0)
        {
            [self startPipelineWithId:[child.pipelines objectAtIndex:0] forNode:child];
            return YES;
        }
        else {
            NSLog(@"selected child doesn't have a pipeline");
        }
        
        return NO;
    }
    
    else {
        //if node (incomplete) do same
        
        //if node (and that node is complete) funnel is that node's pipeline
    
        //todo: fake it -- direct to node for now
        if(n.pipelines.count>0)
        {
            [self startPipelineWithId:[n.pipelines objectAtIndex:0] forNode:n];
            return YES;
        }
        else {
            NSLog(@"no pipeline found for node %@", nodeId);
            return NO;
        }
    }
}


#pragma mark - data access

-(NSArray*)allConceptNodes
{
    NSMutableArray *nodes=[[[NSMutableArray alloc] init] autorelease];
    [contentDatabase open];
    FMResultSet *rs = [contentDatabase executeQuery:@"select * from ConceptNodes"];
    while([rs next])
    {
        ConceptNode *n = [[[ConceptNode alloc] initWithFMResultSetRow:rs] autorelease];
        [nodes addObject:n];
    }
    [rs close];
    [contentDatabase close];
    return nodes;
}

-(ConceptNode*)conceptNodeForId:(NSString*)nodeId
{
    [contentDatabase open];
    ConceptNode *returnNode=nil;
    FMResultSet *rs=[contentDatabase executeQuery:@"select * from ConceptNodes where id=?", nodeId];
    if([rs next])
    {
        returnNode=[[[ConceptNode alloc] initWithFMResultSetRow:rs] autorelease];
    }
    else {
        NSLog(@"ConceptNode with id %@ not found", nodeId);
    }
    [rs close];
    [contentDatabase close];
    return returnNode;
}

-(NSArray*)relationMembersForName:(NSString *)name
{
    [contentDatabase open];
    FMResultSet *rs = [contentDatabase executeQuery:@"select members from BinaryRelations where name=?", name];
    NSArray *pairs = nil;
    if ([rs next])
    {
        pairs = [[rs stringForColumn:@"members"] objectFromJSONString];
    }
    [rs close];
    [contentDatabase close];
    return pairs;
}

-(Pipeline*)pipelineWithId:(NSString*)plId
{
    Pipeline *pl = nil;
    [contentDatabase open];
    FMResultSet *rs = [contentDatabase executeQuery:@"select * from Pipelines where id=?", plId];
    if ([rs next])
    {
        pl = [[[Pipeline alloc] initWithFMResultSetRow:rs] autorelease];
    }
    [rs close];
    [contentDatabase close];
    return pl;
}

-(NSMutableArray*)childNodesForMasteryWithId:(NSString*)masteryId
{
    NSMutableArray *ret=[[[NSMutableArray alloc] init] autorelease];
    
    NSArray *rel=[self relationMembersForName:@"Mastery"];
    
    for (NSArray *pair in rel) {
        if ([[pair objectAtIndex:1] isEqualToString:masteryId]) {
            [ret addObject:[self conceptNodeForId:[pair objectAtIndex:0]]];
        }
    }
    
    return ret;
}

-(NSArray*)allRegions
{
    [contentDatabase open];
    NSMutableArray *regions=[[NSMutableArray alloc] init];
    
    FMResultSet *rs=[contentDatabase executeQuery:@"select distinct region from conceptnodes"];
    
    while ([rs next]) {
        NSArray *rlist=[[rs stringForColumn:@"region"] objectFromJSONString];
        if(rlist.count>0)
            if(![[rlist objectAtIndex:0] isEqualToString:@""])
                [regions addObject:[rlist objectAtIndex:0]];
    }
    
    [rs close];
    [contentDatabase close];

    NSArray *ret=[NSArray arrayWithArray:regions];
    [regions release];
    return ret;
}

-(NSDictionary*)currentPDef
{
    if (useTestPipeline) return currentPDef;
    else return self.currentProblem ? self.currentProblem.pdef : nil;
}


#pragma mark - the rest

-(float) pipelineProblemAttemptMaxScore
{
    return self.pipelineProblemAttemptBaseScore * pow(SCORE_STAGE_MULTIPLIER, SCORE_STAGE_CAP-1);
}

-(NSString*)contentDir
{
    return contentDir;
}

-(void)setCurrentStaticPdef:(NSMutableDictionary*)pdef
{
    NSLog(@"setting currentStaticPdef");
    if (pdef) [pdef retain];
    //if (currentStaticPdef) [currentStaticPdef release];
    currentStaticPdef = pdef;
}

-(BOOL)isUsingTestPipeline
{
    return useTestPipeline;
}

-(void)startPipelineWithId:(NSString*)pipelineid forNode:(ConceptNode*)node
{
    if (![node.pipelines containsObject:pipelineid])
    {
        NSMutableDictionary *d = [NSMutableDictionary dictionary];
        [d setValue:BL_APP_ERROR_TYPE_BAD_ARG forKey:@"type"];
        [d setValue:@"ContentService#startPipelineWithId" forKey:@"method"];
        [d setValue:node._id forKey:@"nodeId"];
        [d setValue:pipelineid forKey:@"pipelineId"];
        [d setValue:@"node does contain pipelineid" forKey:@"description"];        
        AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
        [ac.loggingService logEvent:BL_APP_ERROR withAdditionalData:d];
    }
    
    [contentDatabase open];
    FMResultSet *rs = [contentDatabase executeQuery:@"select * from Pipelines where id=?", pipelineid];
    if (![rs next])
    {
        NSMutableDictionary *d = [NSMutableDictionary dictionary];
        [d setValue:BL_APP_ERROR_TYPE_DB_TABLE_MISSING_ROW forKey:@"type"];
        [d setValue:@"Pipelines" forKey:@"table"];
        [d setValue:pipelineid forKey:@"key"];        
        AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
        [ac.loggingService logEvent:BL_APP_ERROR withAdditionalData:d];
    }
    Pipeline *rawPipeline=[[[Pipeline alloc] initWithFMResultSetRow:rs] autorelease];
    [rs close];
    [contentDatabase close];
    
    //set local pipeline to flattened version of same
    self.currentPipeline=[self flattenPipeline:rawPipeline.problems];
    
    //rembmer the current pipeline's id
    currentPipelineId=pipelineid;
    
    //start indexes before their contents -- ready to increment into their respective sequences
    pipelineIndex=-1;
    episodeIndex=-1;
    
    //initialize the episode -- only here (in start node) if not working from a test pipeline
    [self createEpisode];
    
    // set problem attempt base score for pipeline    
    int minEpisodeLength = [self.currentPipeline count];
    int availableBaseScoreUnits = 0;
    for (int i=0; i<minEpisodeLength && i<SCORE_STAGE_CAP; i++)
    {
        availableBaseScoreUnits += pow(SCORE_STAGE_MULTIPLIER, i);
    }
    if (minEpisodeLength > SCORE_STAGE_CAP)
    {
        availableBaseScoreUnits += (minEpisodeLength-SCORE_STAGE_CAP) * pow(SCORE_STAGE_MULTIPLIER, SCORE_STAGE_CAP-1);
    }
    self.pipelineProblemAttemptBaseScore = SCORE_EPISODE_MAX / availableBaseScoreUnits;    
    
        
    self.currentNode=node;
}

-(NSArray*)flattenPipeline:(NSArray*)srcPipeline
{
    NSMutableArray *flatPipeline=[[NSMutableArray alloc] init];
    
    for (NSString *prbId in srcPipeline) {
        Problem *p = [self loadProblemWithId:prbId];
        if (!p) continue;
        
        NSDictionary *pdef = p.pdef;
        
        NSNumber *rawRptAsIsMin=[pdef objectForKey:@"REPEAT_AS_IS_MIN"];
        NSNumber *rawRptScaffoldMin=[pdef objectForKey:@"REPEAT_AND_SCAFFOLD_MIN"];
        
        int rptMin=1;
        if(rawRptAsIsMin) rptMin=[rawRptAsIsMin integerValue];
        if(rawRptScaffoldMin) rptMin=[rawRptScaffoldMin integerValue];
        
        //insert to repeat count
        for(int i=0; i<rptMin; i++)
        {
            [flatPipeline addObject:[[prbId copy] autorelease]];
        }
        
        NSString *rptTag=[pdef objectForKey:@"REPEAT_SET"];
        if(rptTag)
        {
            if(!repeatBuffer)repeatBuffer=[[NSMutableArray alloc] init];
            
            if(lastRepeatSet!=nil)
            {
                if(![rptTag isEqualToString:lastRepeatSet])
                {
                    //clear out the buffer -- this is a new tag
                    [repeatBuffer removeAllObjects];
                }
            }
            
            //insert ourselves into the buffer
            [repeatBuffer addObject:[[prbId copy] autorelease]];
            
            //track this set tag for the next problem
            lastRepeatSet=rptTag;
            
            //see if we're ready for a repition of the set
            NSNumber *rawSetRptMin=[pdef objectForKey:@"REPEAT_MY_SET_MIN"];
            if(rawSetRptMin)
            {
                //insert the buffer min times, then empty it
                for(int i=0; i<[rawSetRptMin integerValue]; i++)
                {
                    [flatPipeline addObjectsFromArray:repeatBuffer];
                }
                
                [repeatBuffer removeAllObjects];
                lastRepeatSet=nil;
            }
        }
    }
    
    NSArray *ret=[NSArray arrayWithArray:flatPipeline];
    [flatPipeline release];
    return ret;
}

-(void)quitPipelineTracking
{
    self.currentProblem = nil;
    if (useTestPipeline) self.currentPDef = nil;
    self.currentStaticPdef = nil;
}

-(void)gotoNextProblemInPipeline
{
    [self gotoNextProblemInPipelineWithSkip:1];
}

-(void)gotoNextProblemInPipelineWithSkip:(int)skipby
{
    //callers (toolhost) to this method will presume the end of the pipeline if the current Pdef is set to nil
    // this method assumes that it's at the end of the pipeline and sets nil upfront (indirectly via self.currentProblem for db)
    self.currentProblem = nil; // nil anyway for test pipelines
    self.currentPDef = nil; // setter has no effect on database pipelines
    
    //test pipelines are handled separately from pipeline>episode (adaptive) pipelines
    if (useTestPipeline)
    {
        [self gotoNextProblemInTestPipeline];
    }
    
    //a normal adaptive pipeline -- progress using combination of epsiodeIndex and pipelineIndex
    else
    {        
        //to allow for debug skipping, loop the episode index increment and insertion (where required)
        for(int i=0; i<skipby; i++)
        {
            
            //increment the episode index (this is initialized as -1 so will work for moving into first problem)
            episodeIndex++;

            //if the user is at the episide head (also the case at start of pipeline), try and insert a problem into the episode
            if(self.isUserPastEpisodeHead) [self insertNextProblemIntoEpisode];
        }
        
        
        NSLog(@"count of episode %d, index incremented to %d", currentEpisode.count, episodeIndex);

        //if the user is at the episide head (also the case at start of pipeline), try and insert a problem into the episode
        if(self.isUserPastEpisodeHead)
        {
            //attempt to insert another problem from the pipeline into the episode
            if([self insertNextProblemIntoEpisode])
            {
                NSLog(@"inserting problem into episode");
                
                //a new problem was inserted into the episode, start it
                [self startProblemWithId:[currentEpisode lastObject]];
            }
        }
        
        //if the user isn't at the head of the episode, there are more problems to complete in the episode
        else
        {
            NSLog(@"moving to already queued problem");
            
            [self startProblemWithId:[currentEpisode objectAtIndex:episodeIndex]];
            
        }
    }
}

-(Problem*)loadProblemWithId:(NSString *)pid
{
    return [[[Problem alloc] initWithDatabase:contentDatabase andProblemId:pid] autorelease];
}

-(void)startProblemWithId:(NSString*)pId
{
    self.currentProblem = [self loadProblemWithId:pId];
}

-(void)gotoNextProblemInTestPipeline
{
    currentPIndex = (currentPIndex == NSUIntegerMax) ? 0 : (currentPIndex + 1) % [testProblemList count];
    
    NSString *problemPath=[testProblemList objectAtIndex:currentPIndex];
    
    if([problemPath rangeOfString:@".app"].location==NSNotFound)
        problemPath=BUNDLE_FULL_PATH(problemPath);
    
    self.currentPDef = [NSDictionary dictionaryWithContentsOfFile:problemPath];
    
    self.pathToTestDef=[testProblemList objectAtIndex:currentPIndex];
    NSLog(@"loaded test def: %@", self.pathToTestDef);
}

-(void)setPipelineNodeComplete
{
    if (useTestPipeline) return;
    
    NSLog(@"ContentService#setPipelineNodeComplete currentNode id=\"%@\"", currentNode._id);
    //effective placeholder for assessed complete -- e.g. lit on node
    UsersService *us = ((AppController*)[[UIApplication sharedApplication] delegate]).usersService;    
    [us addCompletedNodeId:self.currentNode._id];
}

-(void)setPipelineScore:(int)score
{
    //if this is greater than previous score for this pipeline, persist it as score for that pipeline / node
    
    
}

#pragma mark - epsiode management, progression

-(int)pipelineIndex
{
    return pipelineIndex;
}

-(int)episodeIndex
{
    return episodeIndex;
}

-(BOOL)isUserPastEpisodeHead
{
    //has the user progressed through all of the problems in the current episode
    BOOL head=(episodeIndex>=[currentEpisode count]) || [currentEpisode count]==0;
    
    return head;
}

-(BOOL)isUserAtEpisodeHead
{
    //is the user on the head problem -- e.g. the last (current) problem in the episode
    BOOL head=(episodeIndex>=[currentEpisode count]<1) || [currentEpisode count]==0;
    
    return head;
}

-(BOOL)isUsingInserters
{
    //currently direct from adpline-settings, but could be from subs on/off, or user profile
    AppController *ac=(AppController*)[UIApplication sharedApplication].delegate;
    return [(NSNumber*)[ac.AdplineSettings objectForKey:@"USE_INSERTERS"] boolValue];
}

-(void)adaptPipelineByInsertingWithTriggerData:(NSDictionary*)triggerData
{
    //key insertion to pipeline method -- attempt to insert things using inserters + repeat of current problem
    //progression to the inserted problems isn't actually handled here - this just inserts stuff
 
    //get list of inserters
    AppController *ac=(AppController*)[UIApplication sharedApplication].delegate;
    NSArray *inserterNameList=[ac.AdplineSettings objectForKey:@"INSERTER_ORDER"];
    
    //build decision data -- ready to add as json to inserter row
    NSMutableArray *allDecisionsData=[[NSMutableArray alloc] init];
    NSMutableArray *inserters=[[NSMutableArray alloc] init];
    
    //initialize and build each, noting decision_data
    for(NSString *inserterName in inserterNameList)
    {
        //class from string
        AdpInserter *inserter=[[NSClassFromString(inserterName) alloc] init];
        
        //build
        [inserter buildInserts];
        
        //note decision data -- currently just number of potential problems + problem viability dicts -- ids and whatever else is there
        NSDictionary *ddata=@{ @"INSERTER_NAME" : inserterName,
            @"VIABLE_INSERTS" : inserter.viableInserts,
            @"INSERTER_INFORMATION" : inserter.decisionInformation};
        [allDecisionsData addObject:ddata];
        
        //add to list
        [inserters addObject:inserter];
        
        [inserter release];
    }
    
    //find first that hasn't been used for this problem (query on inserters w/ this problem_id & user episode_id) && that can insert more than 0 problems, building decision_data at the same time
    
    //already used inserters -- we don't re-insert something that's been used aready for this problem/episode
    NSArray *previousInserters=[self getInsertersUsedForProblemId:[currentEpisode objectAtIndex:episodeIndex] inEpisodeId:episodeId];
    
    AdpInserter *useThisInserter=nil;
    
    //we built viability data for all inserters -- let's look over it and...
    for(AdpInserter *inserter in inserters)
    {
        //... see if we can insert (>0 problems found) and it hasn't been used before
        if(inserter.viableInserts.count>0 && ![previousInserters containsObject:inserter.inserterName])
        {
            //indicate we want to use this inserter to adapt the pipeline
            useThisInserter=inserter;
            
            //bail here -- we found an inserter that had viable inserts and hadn't been used
            break;
        }
    }
    
    //if we found an inserter -- insert some stuff
    if(useThisInserter)
    {
        //open db for problem insert, inserter insert
        [usersService.usersDatabase open];
        
        //get an id for the episode insert we'll create in a bit
        NSString *episodeInsertId=[BLFiles generateUuidString];
        
        for(NSDictionary *insertdict in useThisInserter.viableInserts)
        {
            //get the pid
            NSString *pid=[insertdict objectForKey:@"PROBLEM_ID"];
            
            //insert this problem into the current episode -- there is some duplication here with inserting problems in general
            // pipeline progression, but this allows us to keep db open in a single batch and to do offset incrementing on episode indexes etc
            
            //put the problem id in the currentEpisode
            [currentEpisode addObject:pid];
            
            //create an id for the episode problem -- though this isn't used referentially or internally
            NSString *epid=[BLFiles generateUuidString];
            
            //index/sequence -- offset back from the count of the epsidoe (we're always inserting problems at the end of the episode
            // as the episode never contains more than the current problem from it's pipeline
            // though this would mean recusive insertion would insert after inserted problems
            // (e.g. if an inserted problem inserted more problems
            NSNumber *insertIndex=[NSNumber numberWithInt:currentEpisode.count-1];
            
            [usersService.usersDatabase executeUpdate:@"INSERT INTO EpisodeProblems (id, episode_index, episode_id, episodeinserts_id, problem_id, dvar_data) VALUES (?, ?, ?, ?, ?, NULL)", epid, insertIndex, episodeId, episodeInsertId, pid];
        }
        
        //now insert the a copy of the current problem
        
        //put the problem id in the currentEpisode
        [currentEpisode addObject:[currentEpisode objectAtIndex:episodeIndex]];
        
        //create an id for the episode problem -- though this isn't used referentially or internally
        NSString *epid=[BLFiles generateUuidString];
        
        //index/sequence -- offset back from the count of the epsidoe as above
        NSNumber *insertIndex=[NSNumber numberWithInt:currentEpisode.count-1];
        
        [usersService.usersDatabase executeUpdate:@"INSERT INTO EpisodeProblems (id, episode_index, episode_id, episodeinserts_id, problem_id, dvar_data) VALUES (?, ?, ?, ?, ?, NULL)", epid, insertIndex, episodeId, episodeInsertId, [currentEpisode objectAtIndex:episodeIndex]];
        
        [self insertIntoEpsiodeTheProblemWithId:[currentEpisode objectAtIndex:episodeIndex]];

        //insert inserter record -- inc current epproblem_id, problem_id and episode_id, decision_data, trigger_data
//        [usersService.usersDatabase executeUpdate:@"INSERT INTO EpisodeInserts (id, episode_id, inserter_type, trigger_data, decision_data) VALUES (?, ?, ?, ?, ?)", episodeInsertId, episodeId, useThisInserter.inserterName, [triggerData JSONString],[allDecisionsData JSONString]];
        
        [usersService.usersDatabase executeUpdate:@"INSERT INTO EpisodeInserts (id, episode_id, source_problem_id, inserter_type, trigger_data, decision_data) VALUES (?, ?, ?, ?, ?, ?)", episodeInsertId, episodeId, [currentEpisode objectAtIndex:episodeIndex], useThisInserter.inserterName, [triggerData JSONString],[allDecisionsData JSONString]];
        
        [usersService.usersDatabase close];
    }
    
    [allDecisionsData release];
    [inserters release];
}

-(NSArray*)getInsertersUsedForProblemId:(NSString*)seekProblemId inEpisodeId:(NSString*)seekEpisodeId
{
    NSMutableArray *insertersUsed=[[NSMutableArray alloc] init];
    
    [usersService.usersDatabase open];
    
    FMResultSet *rs=[usersService.usersDatabase executeQuery:@"SELECT * FROM EpisodeInserts WHERE episode_id=? AND source_problem_id=?", seekEpisodeId, seekProblemId];
    
    while ([rs next]) {
        NSString *iname=[rs stringForColumn:@"inserter_type"];
        if(![insertersUsed containsObject:iname]) [insertersUsed addObject:iname];
    }
    
    [rs close];
    [usersService.usersDatabase close];
    
    NSArray *reta=[NSArray arrayWithArray:insertersUsed];
    [insertersUsed release];
    return reta;
}

-(void)insertIntoEpsiodeTheProblemWithId:(NSString*)problemId
{
    
}

-(BOOL)insertNextProblemIntoEpisode
{
    //increment the pipeline index
    pipelineIndex++;
    
    //if we're at the end of the pipeline, return NO
    if(pipelineIndex>=self.currentPipeline.count)
    {
        //write into database that we overflowed
        [usersService.usersDatabase open];
        [usersService.usersDatabase executeUpdate:@"UPDATE Episodes SET completed_by_overflow=1 WHERE id=?", episodeId];
        [usersService.usersDatabase close];
        
        return NO;
    }
    // there are more problems in the pipeline, put the next problem in the episode
    else
    {
        [currentEpisode addObject:[self.currentPipeline objectAtIndex:pipelineIndex]];
        
        //insert this into the EpisodeProblems table
        [usersService.usersDatabase open];
        
        //create an id for the episode problem -- though this isn't used referentially or internally
        NSString *epid=[BLFiles generateUuidString];
        
        //index/sequence -- we're only inserting one, so we can use the episode_index
        NSNumber *insertIndex=[NSNumber numberWithInt:episodeIndex];
        
        [usersService.usersDatabase executeUpdate:@"INSERT INTO EpisodeProblems (id, episode_index, episode_id, episodeinserts_id, problem_id, dvar_data) VALUES (?, ?, ?, NULL, ?, NULL)", epid, insertIndex, episodeId, [self.currentPipeline objectAtIndex:pipelineIndex]];
        
        [usersService.usersDatabase close];
    }
    
    //we get here if we inserted a problem
    return YES;
}

-(void) createEpisode
{
    //make sure we have the usersService locally
    if(!usersService) usersService=((AppController*)[[UIApplication sharedApplication] delegate]).usersService;
    
    //dispose of any previous episode
    if(currentEpisode) [currentEpisode release];
    
    //start new, empty, episode
    currentEpisode=[[NSMutableArray alloc] init];
    
    //get an id for this episode (for db primarily)
    episodeId=[[BLFiles generateUuidString] retain];
    
    [usersService.usersDatabase open];
    
    //check we have an episodes table to insert into
    [self queryCreateEpisodesTables];
    
    //insert details of this episode into the database
    [usersService.usersDatabase executeUpdate:@"INSERT INTO Episodes (id, pipeline_id, user_id, date_created, completed_by_overflow) VALUES (?, ?, ?, ?, 0)", episodeId, currentPipelineId, usersService.currentUserId, [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]]];
    
    [usersService.usersDatabase close];

}

-(void) queryCreateEpisodesTables
{
    //this expects the database to be open already
    
    //this will need expanding to support versioning (e.g. per column checks / db build diff)
    if(![usersService.usersDatabase tableExists:@"Episodes"])
    {
        [usersService.usersDatabase executeUpdate:@"CREATE TABLE Episodes (id TEXT PRIMARY KEY, pipeline_id TEXT, user_id TEXT, date_created INTEGER, completed_by_overflow INTEGER)"];
    }
    if(![usersService.usersDatabase tableExists:@"EpisodeInserts"])
    {
        [usersService.usersDatabase executeUpdate:@"CREATE TABLE EpisodeInserts (id TEXT PRIMARY_KEY, episode_id TEXT, source_problem_id TEXT, inserter_type TEXT, trigger_data TEXT, decision_data TEXT)"];
    }
    if(![usersService.usersDatabase tableExists:@"EpisodeProblems"])
    {
        [usersService.usersDatabase executeUpdate:@"CREATE TABLE EpisodeProblems (id TEXT PRIMARY_KEY, episode_index INTEGER, episode_id TEXT, episodeinserts_id TEXT, problem_id TEXT, dvar_data TEXT)"];
    }
}

#pragma mark - debug data

-(NSString*)debugPipelineString
{
    NSMutableString *html=[[NSMutableString alloc] init];
    
    [usersService.usersDatabase open];
    
    [html appendFormat:@"<h2>current episode problems</h2>"];
    
    NSString *lastEpInsId=nil;
    
    
    //for inserting "skip by" content service handler links
    BOOL countSkips=NO;
    int skipBy=1;
    
    //current problems in episode
    FMResultSet *rs=[usersService.usersDatabase executeQuery:@"select * from EpisodeProblems where episode_id=? order by episode_index", episodeId];
    while([rs next])
    {
        if(countSkips) skipBy++;
        
        NSString *style=@"";
        NSString *insertsection=@"";
        if([rs intForColumn:@"episode_index"]==episodeIndex)
        {
            //highlight the current problem
            style=@";font-weight:bold";
            
            //start counting from the current problem
            countSkips=YES;
        }
        
        if([rs stringForColumn:@"episodeinserts_id"] != nil)
        {
            //pad in
            style=[style stringByAppendingFormat:@"; border-left: 5px #4c86ce dotted; padding-left:20px; margin-left:20px"];
            
            //is this the first in an insertion (check by looking at the insertion id)
            NSString *thisInsId=[rs stringForColumn:@"episodeinserts_id"];
            if(![thisInsId isEqualToString:lastEpInsId])
            {
                insertsection=[NSString stringWithFormat:@"<p style='padding-left:20px; margin-left:20px; color:#4c86ce'>(insert %@)</p>", thisInsId];
            }
            lastEpInsId=thisInsId;
        }
        
        [html appendFormat:@"%@<p style='%@'>%03d: %@ -- <span style=''>%@</span></p>", insertsection, style, [rs intForColumn:@"episode_index"], [rs stringForColumn:@"problem_id"], [self debugProblemDescStringFor:[rs stringForColumn:@"problem_id"]]];
    }
    
    //remaining problems
    if(pipelineIndex<currentPipeline.count-1)
    {
        for(int i=pipelineIndex+1; i<currentPipeline.count; i++)
        {
            [html appendFormat:@"<p style='color:#bcbcbc'><a href='belugadebug://skip?%d'>*%02d: %@ -- <span style=''>%@</span></a></p>", skipBy, i, [currentPipeline objectAtIndex:i], [self debugProblemDescStringFor:[currentPipeline objectAtIndex:i]]];
            
            skipBy++;
        }
    }
    
    [html appendFormat:@"<h2>episode inserts</h2>"];
    
    //insert data
    FMResultSet *rsei=[usersService.usersDatabase executeQuery:@"select * from EpisodeInserts where episode_id=?", episodeId];
    while([rsei next])
    {
        [html appendFormat:@"<p style='font-size:9pt'>"];
        [html appendFormat:@"<b>id:</b>%@</br>", [rsei stringForColumn:@"id"]];
        [html appendFormat:@"<b>source problem id:</b>%@<br />", [rsei stringForColumn:@"source_problem_id"]];
        [html appendFormat:@"<b>inserter type:</b>%@<br />", [rsei stringForColumn:@"inserter_type"]];
        [html appendFormat:@"<b>trigger data:</b><br />%@<br />", [rsei stringForColumn:@"trigger_data"]];
        [html appendFormat:@"<b>decision data:</b><br />%@<br />", [[rsei stringForColumn:@"decision_data"] stringByReplacingOccurrencesOfString:@",{" withString:@",<br/>{"]];
        [html appendFormat:@"</p>"];
    }
    
    
    [html appendFormat:@"<h2>adpline settings</h2>"];
    AppController *ac=(AppController*)[[UIApplication sharedApplication] delegate];
    [html appendFormat:@"<pre>%@</pre>", [ac.AdplineSettings description]];
    
    [usersService.usersDatabase close];
    
    NSString *ret=[NSString stringWithString:html];
    [html release];
    return ret;
    
    
}

-(NSString*)debugProblemDescStringFor:(NSString*)pId
{
    Problem *p = [[[Problem alloc] initWithDatabase:contentDatabase andProblemId:pId] autorelease];
    if (!p) return [NSString stringWithFormat:@"Problem id =\"%@\" missing", pId];
    
    NSDictionary *pdef=p.pdef;
    
    NSString *tool=@"";
    NSString *title=@"";
    if([pdef objectForKey:@"TOOL_KEY"]) tool=[pdef objectForKey:@"TOOL_KEY"];
    
    if([pdef objectForKey:@"PROBLEM_DESCRIPTION"])
    {
        title= [pdef objectForKey:@"PROBLEM_DESCRIPTION"];
    }
    if([pdef objectForKey:@"META_QUESTION"])
    {
        title= [[pdef objectForKey:@"META_QUESTION"] objectForKey:@"META_QUESTION_TITLE"];
        tool=[tool stringByAppendingFormat:@" (MQ)"];
    }
    if([pdef objectForKey:@"NUMBER_PICKER"])
    {
        title= [[pdef objectForKey:@"NUMBER_PICKER"] objectForKey:@"NUMBER_PICKER_DESCRIPTION"];
        tool=[tool stringByAppendingFormat:@" (NP)"];
    }
    
    return [NSString stringWithFormat:@"%@ -- %@", tool, title];
}

#pragma mark - tear down

- (void)dealloc
{
    self.kcmServerBaseURL = nil;
    if (contentDatabase)
    {
        [contentDatabase close];
        [contentDatabase release];
    }
    if (contentDir) [contentDir release];
    self.currentProblem = nil;
    self.currentPDef = nil;
    if (testProblemList) [testProblemList release];
    
    if(repeatBuffer)[repeatBuffer release];
    
    if (currentEpisode) [currentEpisode release];
    
    [super dealloc];
}

@end
