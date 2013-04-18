//
//  RecordAudio.h
//  JuuJuu
//
//  Created by xiaoguang huang on 11-12-19.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>


@interface RecordAudio : NSObject <AVAudioPlayerDelegate>
{
    // 播放的过程的错误提示
	NSError * playerError;

    // 播放器对象
    AVAudioPlayer * avPlayer;
}

-(void) play:(NSData*) data;
-(void) stopPlay;
+(NSTimeInterval) getAudioTime:(NSData *) data;
@end
