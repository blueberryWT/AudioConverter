//
// Created by BlueBerry on 13-2-19.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#define kVoiceSourceDir @"/Documents/dpSourceVoice/"

@interface RecorderManager : NSObject <AVAudioRecorderDelegate> {
    // 录音设置选项
    NSMutableDictionary *_recordSetting;

    // 录音控制器
    AVAudioRecorder *_recorder;

    // 文件路径
    NSString *_filePath;

    // 录音分贝强度监听计时器
    NSTimer *_levelTimer;

    // 语音文件缓存路径
    NSString *_voiceCacheLib;

    // 临时记录时间差的
    NSDate *_recorderStartTime;

    // 记录一下录音的语音时长
    NSUInteger _recorderTime;

    // 当前声音分贝数
    CGFloat _currentSoundDecibels;

    BOOL _isCancelRecord;

}
@property(nonatomic, retain) NSTimer *levelTimer;
@property(nonatomic, copy) NSString *filePath;
@property(nonatomic, retain) AVAudioRecorder *recorder;
@property(nonatomic, retain) NSMutableDictionary *recordSetting;
@property(nonatomic, copy) NSString *voiceCacheLib;
@property (nonatomic, assign) NSUInteger recorderTime;
@property (nonatomic, assign) CGFloat currentSoundDecibels;

@property(nonatomic) CGFloat currentAudioTime;

@property(nonatomic, retain) NSTimer *statisticsAudioTimer;

@property(nonatomic) BOOL isRecording;

-(void) startRecorder:(id) sender;
-(void) stopRecorder:(id) sender;
-(void) cancelRecorder:(id) sender;
-(NSData* ) getVoiceFileFormLocation:(NSString *) path;

-(void) saveVoiceFileToLocation:(NSData *) data forKey:(NSString*) key;


+(RecorderManager* )sharedInstance;
@end