//
//  AcapelaSetup.m
//  TTSDemo
//
//  Acapela Group
//
//

#if !(TARGET_IPHONE_SIMULATOR)

#import "AcapelaSetup.h"

@implementation AcapelaSetup
@synthesize Voices;
@synthesize CurrentVoice;
@synthesize CurrentVoiceName;
@synthesize AutoMode;

-(id)initialize
{
	AutoMode = FALSE;
	Voices = [[NSArray arrayWithArray:[AcapelaSpeech availableVoices]] retain];
	if (Voices.count > 0)
		CurrentVoiceName = [[self SetCurrentVoice:0] retain];
	else
		CurrentVoice = NULL;
	return self;
}

- (NSString*)SetCurrentVoice:(NSInteger)row
{
	CurrentVoice = [Voices objectAtIndex:row];
	NSDictionary *dic = [AcapelaSpeech attributesForVoice:CurrentVoice];
	CurrentVoiceName = [dic valueForKey:AcapelaVoiceName]; 
    //retain this value for GetCurrentVoiceName
    [CurrentVoiceName retain];
	return CurrentVoiceName;
}



- (NSString*)GetCurrentVoiceName
{
    return CurrentVoiceName;
}

- (void)dealloc {
	[Voices release];
	[CurrentVoice release];
	[CurrentVoiceName release];
	[super dealloc];
}

@end

#endif