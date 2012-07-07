//
//  LogginService.m
//  belugapad
//
//  Created by Nicholas Cartwright on 23/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LoggingService.h"
#import "global.h"
#import "AppDelegate.h"
#import "UsersService.h"
#import "ContentService.h"
#import "Problem.h"
#import "AFNetworking.h"
#import <zlib.h>
#import <CommonCrypto/CommonDigest.h>
#import "JSONKit.h"


NSString * const kLoggingWebServiceBaseURL = @"http://log.zubi.me:3000";
NSString * const kLoggingWebServicePath = @"app-logging/upload";
uint const kMaxConsecutiveSendFails = 3;


@interface LoggingService()
{
@private 
    NSString *currDir;
    NSString *prevDir;
    
    AFHTTPClient *httpClient; 
    NSOperationQueue *opQueue;
    NSFileManager *fm;
    
    BL_LOGGING_SETTING problemAttemptLoggingSetting;
    BL_LOGGING_CONTEXT currentContext;
    
    NSMutableDictionary *deviceSessionDoc;
    NSMutableDictionary *userSessionDoc;
    NSMutableDictionary *problemAttemptDoc;
    
    uint consecutiveSendFails;
    __block BOOL isSending;
}
-(void)sendCurrBatch;
-(void)sendPrevBatches;
-(void)sendBatchData:(NSData*)batchData withCompletionBlock:(void (^)(BL_SEND_LOG_STATUS status))onComplete;
-(BL_SEND_LOG_STATUS)validateResponse:(id)result
                        forClientData:(NSData*)cData;
-(NSString*)generateUUID;
@end


@implementation LoggingService

-(id)initWithProblemAttemptLoggingSetting:(BL_LOGGING_SETTING)paLogSetting
{
    self = [super init];
    if (self)
    {
        problemAttemptLoggingSetting = paLogSetting;
        isSending = NO;
        
        httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:kLoggingWebServiceBaseURL]];
        opQueue = [[[NSOperationQueue alloc] init] retain];
        fm = [NSFileManager defaultManager];
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *baseDir = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"logging"];
        currDir = [[NSString stringWithFormat:@"%@/%@", baseDir, @"current-batch"] retain];
        prevDir = [[NSString stringWithFormat:@"%@/%@", baseDir, @"prev-batches"] retain];
        
        if (![fm fileExistsAtPath:currDir])
            [fm createDirectoryAtPath:currDir withIntermediateDirectories:YES attributes:nil error:nil];        
        if (![fm fileExistsAtPath:prevDir])
            [fm createDirectoryAtPath:prevDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return self;
}

-(NSString*)currentProblemAttemptID
{
    if (BL_PROBLEM_ATTEMPT_CONTEXT != currentContext) return nil;
    if (!problemAttemptDoc) return nil; // error
    return [problemAttemptDoc objectForKey:@"_id"];
}

-(void)logEvent:(NSString*)eventType withAdditionalData:(NSObject*)additionalData
{
    if (BL_APP_START == eventType)
    {
        currentContext = BL_DEVICE_CONTEXT;
        
        NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
        NSString *installationId = [standardUserDefaults objectForKey:@"installationUUID"];
        if (!installationId)
        {
            installationId = [self generateUUID];
            [standardUserDefaults setObject:installationId forKey:@"installationUUID"];
        }
        
        deviceSessionDoc = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                            [self generateUUID], @"_id"
                            , [NSMutableArray array], @"events"
                            , @"DeviceSession", @"type"
                            , installationId, @"device"
                            , nil];
    }
    else if (BL_SUVC_LOAD == eventType)
    {
        currentContext = BL_DEVICE_CONTEXT;
    }
    else if (BL_USER_LOGIN == eventType)
    {
        currentContext = BL_USER_CONTEXT;
        if (userSessionDoc) [userSessionDoc release];
        
        if (!deviceSessionDoc) return; // error!
        
        AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
        
        userSessionDoc = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                          [self generateUUID], @"_id"
                          , [NSMutableArray array], @"events"
                          , @"UserSession", @"type"
                          , [deviceSessionDoc objectForKey:@"device"], @"device"
                          , [deviceSessionDoc objectForKey:@"_id"], @"deviceSession"
                          , [ac.usersService.currentUserClone objectForKey:@"id"], @"user"
                          , nil];
    }
    else if (BL_JS_INIT == eventType)
    {
        currentContext = BL_USER_CONTEXT;
    }
    else if (BL_PA_START == eventType)
    {
        currentContext = BL_PROBLEM_ATTEMPT_CONTEXT;
        if (BL_LOGGING_DISABLED == problemAttemptLoggingSetting) return;
        
        AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
        Problem *p = ac.contentService.currentProblem;
        
        if (!p) return; // error!
        if (!deviceSessionDoc) return; // error!
        if (!userSessionDoc) return; // error!
        
        problemAttemptDoc = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                             [self generateUUID], @"_id"
                             , [NSMutableArray array], @"events"
                             , @"ProblemAttempt", @"type"
                             , [deviceSessionDoc objectForKey:@"device"], @"device"
                             , [deviceSessionDoc objectForKey:@"_id"], @"deviceSession"
                             , [userSessionDoc objectForKey:@"user"], @"user"
                             , [userSessionDoc objectForKey:@"_id"], @"userSession"
                             , p._id, @"problemId"
                             , p._rev, @"problemRev"
                             , nil];
    }
    
    if (BL_PROBLEM_ATTEMPT_CONTEXT == currentContext && BL_LOGGING_DISABLED == problemAttemptLoggingSetting) return;
    
    NSMutableDictionary *doc = nil;
    switch (currentContext) {
        case BL_DEVICE_CONTEXT:
            doc = deviceSessionDoc;
            break;
        case BL_USER_CONTEXT:
            doc = userSessionDoc;
            break;
        case BL_PROBLEM_ATTEMPT_CONTEXT:
            doc = problemAttemptDoc;
            break;
    }
    
    if (!doc) return; // error!
    
    if (additionalData)
    {
        NSData *jsonData = nil;
        if ([additionalData isKindOfClass:[NSDictionary class]]) jsonData = [(NSDictionary*)additionalData JSONData];
        if ([additionalData isKindOfClass:[NSArray class]]) jsonData = [(NSArray*)additionalData JSONData];        
        if (!jsonData && ![additionalData isKindOfClass:[NSString class]]) additionalData = @"JSON_SERIALIZATION_ERROR";
    }
    
    NSMutableDictionary *event = [NSMutableDictionary dictionary];
    [event setValue:eventType forKey:@"eventType"];
    [event setValue:[NSNumber numberWithInt:[[NSDate date] timeIntervalSince1970]] forKey:@"date"];
    [event setValue:additionalData forKey:@"additionalData"];
    
    NSMutableArray *events = [doc objectForKey:@"events"];
    [events addObject:event];
     
    NSData *docData = [doc JSONData];
    if (!docData) return; //error !
    
    [docData writeToFile:[NSString stringWithFormat:@"%@/%@", currDir, [doc objectForKey:@"_id"]]
                 options:NSAtomicWrite
                   error:nil];
}

-(NSString*)generateUUID
{
    CFUUIDRef UUIDRef = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef UUIDSRef = CFUUIDCreateString(kCFAllocatorDefault, UUIDRef);
    NSString *uuid = [NSString stringWithFormat:@"%@", UUIDSRef];
    
    CFRelease(UUIDRef);
    CFRelease(UUIDSRef);
    
    return uuid;
}

-(void)sendData
{
    consecutiveSendFails = 0;
    [self sendCurrBatch];
}

-(void)sendCurrBatch
{
    // -----  combine date and log files into NSMutableData: combinedFiles    
    const Byte pu1[] = { 0xc2, 0x91 }; // utf-8 private use one
    const Byte pu2[] = { 0xc2, 0x92 }; // utf-8 private use two
    NSData *interSep = [NSData dataWithBytes:pu1 length:2];
    NSData *intraSep = [NSData dataWithBytes:pu2 length:2];
    
    NSArray *files = [fm contentsOfDirectoryAtPath:currDir error:nil];
    
    if (0 == [files count])
    {
        [self sendPrevBatches];
        return;
    }
    
    NSMutableData *combinedFiles = [NSMutableData data];
    
    BOOL firstFile = YES;
    for (NSString *file in files)
    {
        firstFile ? firstFile = NO : [combinedFiles appendData:interSep];
        [combinedFiles appendData:[file dataUsingEncoding:NSUTF8StringEncoding]];
        [combinedFiles appendData:intraSep];
        [combinedFiles appendData:[NSData dataWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", currDir, file]]];            
    }    
    
    // -----  Deflate Compress combinedFiles into NSMutableData: compressedData
    z_stream strm;
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    strm.opaque = Z_NULL;
    strm.total_out = 0;
    strm.next_in=(Bytef *) [combinedFiles bytes];
    strm.avail_in = [combinedFiles length];
    
    deflateInit2(&strm, Z_DEFAULT_COMPRESSION, Z_DEFLATED, (15+16), 8, Z_DEFAULT_STRATEGY);    
    uint k16 = 16384;
    
    NSMutableData *compressedData = [NSMutableData dataWithLength:k16];        
    do
    {
        if (strm.total_out >= [compressedData length]) [compressedData increaseLengthBy:k16];            
        strm.next_out = [compressedData mutableBytes] + strm.total_out;
        strm.avail_out = [compressedData length] - strm.total_out;            
        deflate(&strm, Z_FINISH);  
    }
    while (strm.avail_out == 0);
    
    deflateEnd(&strm);            
    [compressedData setLength: strm.total_out];
    
    
    // ----- create batchData by preprending current date to compressedData
    uint batchDate = (uint)[[NSDate date] timeIntervalSince1970];
    Byte batchDateBytes[4] =  { batchDate & 0xFF, batchDate>>8 & 0xFF, batchDate>>16 & 0xFF, batchDate>>24 & 0xFF,  };
    
    NSMutableData *batchData = [NSMutableData dataWithBytes:batchDateBytes length:4];
    [batchData appendData:compressedData];
    
    
    // ----- HTTPRequest Completion Handler
    __block typeof(self) bself = self;
    void (^onComplete)() = ^(BL_SEND_LOG_STATUS status)
    {
        BOOL queuedBatch = NO;
        
        if (status != BL_SLS_SUCCESS)
        {
            // ---- store the compressed data in prevDir for future repeat attempt at saving
            NSString *filePath = [NSString stringWithFormat:@"%@/%d", bself->prevDir, (int)[[NSDate date] timeIntervalSince1970]];
            queuedBatch = [bself->fm createFileAtPath:filePath contents:batchData attributes:nil];            
            if (!queuedBatch) NSLog(@"Errr.... "); // TODO handle? !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        }
        
        // delete files from currDir if they've either been successfully sent to server or have been saved in compressed form in prevDir
        if (BL_SLS_SUCCESS == status || queuedBatch)
        {
            [bself->fm removeItemAtPath:bself->currDir error:nil];
            [bself->fm createDirectoryAtPath:bself->currDir withIntermediateDirectories:NO attributes:nil error:nil];
            [bself sendPrevBatches];
        }
    };    
    
    // ----- Send batchData in body of HTTPRequest
    [self sendBatchData:batchData withCompletionBlock:onComplete];
}

-(void)sendPrevBatches
{
    NSArray *files = [[fm contentsOfDirectoryAtPath:prevDir error:nil] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];

    if (0 == [files count]) return; // nothing outstanding to be sent

    // ---- batches alphabetically ordered by time last sent, i.e. first item sent longest ago
    NSString *batchPath = [NSString stringWithFormat:@"%@/%@", prevDir, [files objectAtIndex:0]];
    NSData *batch = [NSData dataWithContentsOfFile:batchPath];
    
    // ----- HTTPRequest Completion Handler
    __block typeof(self) bself = self;    
    void (^onComplete)() = ^(BL_SEND_LOG_STATUS status)
    {
        BOOL requeued = NO;
        
        if (status != BL_SLS_SUCCESS)
        {
            // ---- store the compressed data in prevDir for future repeat attempt at saving
            NSString *filePath = [NSString stringWithFormat:@"%@/%d", bself->prevDir, (int)[[NSDate date] timeIntervalSince1970]];
            requeued = [bself->fm createFileAtPath:filePath contents:batch attributes:nil];            
            if (!requeued) NSLog(@"Errr.... "); // TODO handle? !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        }
        
        // delete files from currDir if they've either been successfully sent to server or have been saved in compressed form in prevDir
        if (BL_SLS_SUCCESS == status || requeued)
        {
            [bself->fm removeItemAtPath:batchPath error:NULL];
            if (bself->consecutiveSendFails < kMaxConsecutiveSendFails) [bself sendPrevBatches];
        }
    };
    
    // -----  Send batch in body of HTTPRequest    
    [self sendBatchData:batch withCompletionBlock:onComplete];
}

-(void)sendBatchData:(NSData*)batchData withCompletionBlock:(void (^)(BL_SEND_LOG_STATUS status))onComplete
{
    void (^bodyConstructor)(id) = ^(id<AFMultipartFormData>formData) {
        [formData appendPartWithFileData:batchData
                                    name:@"batchData"
                                fileName:@"batch-data.deflate"
                                mimeType:@"application/base64"];
    };
    NSMutableURLRequest *req = [httpClient multipartFormRequestWithMethod:@"POST"
                                                                     path:kLoggingWebServicePath
                                                               parameters:nil
                                                constructingBodyWithBlock:bodyConstructor];
    
    __block typeof(self) bself = self;
    
    void (^onCompleteWrapper)() = ^(AFHTTPRequestOperation *op, id res)
    {
        bself->isSending = NO;
        BL_SEND_LOG_STATUS status = [self validateResponse:res forClientData:batchData];
        if (BL_SLS_REQUEST_FAIL == status)
        {
            bself->consecutiveSendFails = status == BL_SLS_SUCCESS ? 0 : (bself->consecutiveSendFails + 1);
        }
        onComplete(status);
    };
    
    AFHTTPRequestOperation *reqOp = [[[AFHTTPRequestOperation alloc] initWithRequest:req] autorelease];
    [reqOp setCompletionBlockWithSuccess:onCompleteWrapper failure:onCompleteWrapper];
    [opQueue addOperation:reqOp];
    isSending = YES;
}    

-(BL_SEND_LOG_STATUS)validateResponse:(id)res
                        forClientData:(NSData*)cData
{
    if ([res isKindOfClass:[NSError class]]) return BL_SLS_REQUEST_FAIL;
    
    // md5 checksum generated by server
    NSString *serverChecksum = [[[NSString alloc] initWithData:res encoding:NSUTF8StringEncoding] autorelease];
    
    // ----- md5 checksum of sent client data
    unsigned char md5Data[16];
    CC_MD5(cData.bytes, cData.length, md5Data);    
    NSString *clientChecksum = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                                md5Data[0], md5Data[1], md5Data[2],  md5Data[3],  md5Data[4],  md5Data[5],  md5Data[6],  md5Data[7],
                                md5Data[8], md5Data[9], md5Data[10], md5Data[11], md5Data[12], md5Data[13], md5Data[14], md5Data[15]];
    
    return [serverChecksum isEqualToString:clientChecksum] ? BL_SLS_SUCCESS : BL_SLS_INVALID_CHECKSUM;
}

-(void)dealloc
{
    if (httpClient) [httpClient release];
    if (opQueue) [opQueue release];
    if (currDir) [currDir release];
    if (prevDir) [prevDir release];
    if (deviceSessionDoc) [deviceSessionDoc release];
    if (userSessionDoc) [userSessionDoc release];
    if (problemAttemptDoc) [problemAttemptDoc release];
    [super dealloc];
}

@end
