//
// Created by apple on 13-2-21.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>
#import "AVFoundation/AVFoundation.h"
@class AVAudioPlayer;


@interface PlayAMR : NSObject <AVAudioPlayerDelegate> {
    AVAudioPlayer* _player;
    NSString* _resourcePath;

    void(^block_PlayFinish)(id);

}
@property (nonatomic, retain) AVAudioPlayer* player;
@property (nonatomic, copy) NSString* resourcePath;
@property(nonatomic) BOOL isPlaying;

-(void) playAMR:(NSString *) path;
-(void) stopCurrentPlayAMRFile;

-(void) finishPlay:(void(^)(id))block;

@end