//
//  RecordAudio.m
//  JuuJuu
//
//  Created by xiaoguang huang on 11-12-19.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "RecordAudio.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "amrFileCodec.h"

@implementation RecordAudio

- (void)dealloc {
    [avPlayer stop];
    [avPlayer release];
    avPlayer = nil;
    [super dealloc];
}

-(id)init {
    self = [super init];
    if (self) {
        //Instanciate an instance of the AVAudioSession object.
        AVAudioSession * audioSession = [AVAudioSession sharedInstance];
        //Setup the audioSession for playback and record. 
        //We could just use record and then switch it to playback leter, but
        //since we are going to do both lets set it up once.
        [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error: &playerError];
        
        UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
        AudioSessionSetProperty (kAudioSessionProperty_OverrideAudioRoute,
								 sizeof (audioRouteOverride),
								 &audioRouteOverride);
        
        //Activate the session
        [audioSession setActive:YES error: &playerError];
    }
    return self;
}


+(NSTimeInterval) getAudioTime:(NSData *) data {
    NSError * error;
    AVAudioPlayer*play = [[AVAudioPlayer alloc] initWithData:data error:&error];
    NSTimeInterval n = [play duration];
    [play release];
    return n;
}

//0 播放 1 播放完成 2出错
-(void)sendStatus:(int)status {
    if (status!=0) {
        if (avPlayer!=nil) {
            [avPlayer stop];
            [avPlayer release];
            avPlayer = nil;
        }
    }
}

-(void) stopPlay {
    if (avPlayer!=nil) {
        [avPlayer stop];
        [avPlayer release];
        avPlayer = nil;
        [self sendStatus:1];
    }
}

-(NSData *)decodeAmr:(NSData *)data{
    if (!data) {
        return data;
    }

    return DecodeAMRToWAVE(data);
}

-(void) play:(NSData*) data{
	//Setup the AVAudioPlayer to play the file that we just recorded.
    //在播放时，只停止
    if (avPlayer!=nil) {
        [self stopPlay];
        return;
    } 
    NSLog(@"start decode");
    NSData* o = [self decodeAmr:data];
        NSLog(@"end decode");
    avPlayer = [[AVAudioPlayer alloc] initWithData:o error:&playerError];
    avPlayer.delegate = self;
	[avPlayer prepareToPlay];
    [avPlayer setVolume:1.0];
	if(![avPlayer play]){
        [self sendStatus:1];
    } else {
        [self sendStatus:0];
    }
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    [self sendStatus:1];
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error{
    [self sendStatus:2];
}

@end
