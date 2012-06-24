//
//  LogginService.m
//  belugapad
//
//  Created by Nicholas Cartwright on 23/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LoggingService.h"
#import "UserSession.h"
#import "ProblemAttempt.h"
#import "AFNetworking.h"
#import <zlib.h>
#import <CommonCrypto/CommonDigest.h>

NSString * const kLoggingWebServiceBaseURL = @"http://192.168.1.68:3000";
NSString * const kLoggingWebServicePath = @"/app-logging/upload";

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
    NSMutableDictionary *journeyMapVisitDoc;
    NSMutableDictionary *problemAttemptDoc;
}
-(void)startDeviceSession;
-(void)sendCurrBatch;
-(void)sendPrevBatches;
-(NSMutableURLRequest*)generateURLRequestWithData:(NSData*)logData;
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
        
        [self startDeviceSession];
        
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
            [fm createDirectoryAtPath:prevDir withIntermediateDirectories:YES attributes:nil error:nil];    }
    return self;
}

-(NSString*)currentProblemAttemptID
{
    if (BL_PROBLEM_ATTEMPT_CONTEXT != currentContext) return nil;
    if (!problemAttemptDoc) return nil; // error
    return [problemAttemptDoc objectForKey:@"_id"];
}

-(void)onUpdateObjectOfContext:(BL_LOGGING_CONTEXT)context
{
    switch (context) {
        case BL_DEVICE_LOGGING_CONTEXT:
            break;
        case BL_USER_SESSION_CONTEXT:
            /*if (currentUserSession)
            {
                // TODO - should call [self logEvent]...
                currentUserSession.dateEnd = [NSDate date];
                [[currentUserSession save] wait];
                [currentUserSession release];
                currentUserSession = nil;
            }
            
            if (ur)
             {    
             currentUserSession = [[UserSession alloc] initWithNewDocumentInDatabase:loggingDatabase
             AndStartSessionForUser:ur
             onDevice:device
             withContentSource:contentSource];
             }*/
            break;
        case BL_JOURNEY_MAP_CONTEXT:
            break;
        case BL_PROBLEM_ATTEMPT_CONTEXT:
            break;
    }
}

-(void)logEvent:(NSString*)event withAdditionalData:(NSObject*)additionalData
{
    // TODO: DELETE THIS LINE AS SOON AS NON-PA LOGGING SUPPORTED
    if (BL_PROBLEM_ATTEMPT_CONTEXT != currentContext) return;
    
    if (BL_PROBLEM_ATTEMPT_CONTEXT == currentContext &&
        BL_LOGGING_DISABLED == problemAttemptLoggingSetting) return;
    
    /*
     NSNumber *now = [NSNumber numberWithInt:[[NSDate date] timeIntervalSince1970]];
     NSMutableDictionary *event = [NSMutableDictionary dictionaryWithObjectsAndKeys:
     eventType, @"eventType"
     , now, @"date"
     , additionalData, @"additionalData", nil];
     [events addObject:event];
     
     NSData *docData = [doc JSONData];
     if (!docData)
     {
     [event setObject:@"JSON_SERIALIZATION_ERROR" forKey:@"additionalData"];
     docData = [doc JSONData];
     }
     
     NSError *error = nil;
     [docData writeToFile:docPath options:NSDataWritingAtomic error:&error];
     // TODO: Do something better with error
     if (error) NSLog(@"ERROR WRITING LOG FILE:%@", [error debugDescription]);
     */
}

-(void)startDeviceSession
{
    // device id, date
    /*
     deviceSessionDoc = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
     [self generateUUID], @"_id"
     , nil] retain];
     */
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
    BOOL first = YES;
    for (NSString *file in files)
    {
        first ? first = NO : [combinedFiles appendData:interSep];
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
    
    
    // ----- HTTPRequest Completion Handler
    void (^onComplete)() = ^(AFHTTPRequestOperation *op, id result)
    {
        BL_SEND_LOG_STATUS status = [self validateResponse:result forClientData:compressedData];
        BOOL queuedBatch = NO;
        
        if (status != BL_SLS_SUCCESS)
        {
            // ---- store the compressed data in prevDir for future repeat attempt at saving
            NSString *filePath = [NSString stringWithFormat:@"%@/%d", prevDir, (int)[[NSDate date] timeIntervalSince1970]];
            queuedBatch = [fm createFileAtPath:filePath contents:compressedData attributes:nil];            
            if (!queuedBatch) NSLog(@"Errr.... "); // TODO handle? !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        }
        
        // delete files from currDir if they've either been successfully sent to server or have been saved in compressed form in prevDir
        if (BL_SLS_SUCCESS == status || queuedBatch)
        {
            for (NSString *file in [fm contentsOfDirectoryAtPath:currDir error:nil])
            {
                // TODO: UNCOMMENT FOLLOWING LINE
                //[fm removeItemAtPath:[NSString stringWithFormat:@"%@/%@", currDir, file] error:NULL];
            }            
            [self sendPrevBatches];
        }
    };    
    
    // ----- Send compressedData in body of HTTPRequest
    NSMutableURLRequest *req = [self generateURLRequestWithData:compressedData];
    AFHTTPRequestOperation *reqOp = [[[AFHTTPRequestOperation alloc] initWithRequest:req] autorelease];
    [opQueue addOperation:reqOp];
    [reqOp setCompletionBlockWithSuccess:onComplete failure:onComplete];
}

-(void)sendPrevBatches
{
    NSArray *files = [[fm contentsOfDirectoryAtPath:prevDir error:nil] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];

    if (0 == [files count]) return; // nothing outstanding to be sent

    // ---- batches alphabetically ordered by time last sent, i.e. first item sent longest ago
    NSString *batchPath = [NSString stringWithFormat:@"%@/%@", prevDir, [files objectAtIndex:0]];
    NSData *batch = [NSData dataWithContentsOfFile:batchPath];
    
    // ----- HTTPRequest Completion Handler
    void (^onComplete)() = ^(AFHTTPRequestOperation *op, id result)
    {
        BL_SEND_LOG_STATUS status = [self validateResponse:result forClientData:batch];
        BOOL requeued = NO;
        
        if (status != BL_SLS_SUCCESS)
        {
            // ---- store the compressed data in prevDir for future repeat attempt at saving
            NSString *filePath = [NSString stringWithFormat:@"%@/%d", prevDir, (int)[[NSDate date] timeIntervalSince1970]];
            requeued = [fm createFileAtPath:filePath contents:batch attributes:nil];            
            if (!requeued) NSLog(@"Errr.... "); // TODO handle? !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        }
        
        // delete files from currDir if they've either been successfully sent to server or have been saved in compressed form in prevDir
        if (BL_SLS_SUCCESS == status || requeued)
        {
            [fm removeItemAtPath:batchPath error:NULL];
            [self sendPrevBatches];
        }
    };
    
    // -----  Send batch in body of HTTPRequest
    NSMutableURLRequest *req = [self generateURLRequestWithData:batch];
    AFHTTPRequestOperation *reqOp = [[[AFHTTPRequestOperation alloc] initWithRequest:req] autorelease];
    [opQueue addOperation:reqOp];
    [reqOp setCompletionBlockWithSuccess:onComplete failure:onComplete];
}

-(NSMutableURLRequest*)generateURLRequestWithData:(NSData*)logData
{
    void (^bodyConstructor)(id) = ^(id<AFMultipartFormData>formData) {
        [formData appendPartWithFileData:logData
                                    name:@"logData"
                                fileName:@"log-data.deflate"
                                mimeType:@"application/base64"];
    };
    
    NSNumber *date = [NSNumber numberWithInt:[[NSDate date] timeIntervalSince1970]];
    
    return [httpClient multipartFormRequestWithMethod:@"POST"
                                                 path:@"/app-logging/upload"
                                           parameters:[NSDictionary dictionaryWithObject:date forKey:@"date"]
                            constructingBodyWithBlock:bodyConstructor];
}

-(BL_SEND_LOG_STATUS)validateResponse:(id)result
                        forClientData:(NSData*)cData
{
    if ([result isKindOfClass:[NSError class]]) return BL_SLS_REQUEST_FAIL;
    
    // md5 checksum generated by server
    NSString *serverChecksum = [[[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding] autorelease];
    
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
    if (journeyMapVisitDoc) [journeyMapVisitDoc release];
    if (problemAttemptDoc) [problemAttemptDoc release];
    [super dealloc];
}

@end
