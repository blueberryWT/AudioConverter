//
// Created by BlueBerry on 13-2-19.
//
// To change the template use AppCode | Preferences | File Templates.
//





/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*
*
*                   常量定义
*
*
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#define kdBOffset       40
#define kMeterRefresh   0.1

#define kMaxRecordTime 60.0f
#import "RecorderManager.h"
#import "amrFileCodec.h"
#import <commoncrypto/CommonDigest.h>
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*
*
*                   单例定义
*
*
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
static RecorderManager *instance;



/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*
*
*                   做为一个私有方法定义使用
*
*
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
@interface RecorderManager(Private)

// 准备录音
-(void) prepareRecord;

// 监听以及更新当前输入音量的分贝
- (void)levelTimerCallback:(NSTimer*)sender;

// 延迟结束，这个方法主要是用来防止用户录音不完整的情况
- (void) delayStop;

// 监听当前的语音时长
-(void) statisticsAudioTimeEvent:(id) sender;
@end

@implementation RecorderManager
@synthesize levelTimer = _levelTimer;
@synthesize filePath = _filePath;
@synthesize recorder = _recorder;
@synthesize recordSetting = _recordSetting;
@synthesize voiceCacheLib = _voiceCacheLib;
@synthesize recorderTime = _recorderTime;
@synthesize currentSoundDecibels = _currentSoundDecibels;



/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*
*
*                   初始化函数
*
*
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
-(id) init {
    self = [super init];
    if (self) {
        // 创建默认语音文件夹
        [self setDefaultValues];
    }
    return self;
}



/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*
*
*                   设置默认存储路径等
*
*
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
-(void)setDefaultValues {
    if(!_voiceCacheLib)
    {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *cachesDirectory = [paths objectAtIndex:0];
        self.voiceCacheLib = [cachesDirectory stringByAppendingPathComponent:@"DPVoice"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:self.voiceCacheLib])
        {
            [fileManager createDirectoryAtPath:self.voiceCacheLib withIntermediateDirectories:YES attributes:nil error:nil];
        }
    }
}


/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*
*
*                   开始录音，建议录音前先将之前使用的计时器停止并销毁
*
*
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
- (void)startRecorder:(id)sender {
    [self prepareRecord];
    if (_recorder) {
        _recorderStartTime = [[NSDate date] retain];
        [_recorder record]; // 开始录音
        [_recorder updateMeters]; // 更新一下当前的录音信息

        // 创建一个计时器，用来刷新当前的分贝数
        if (_levelTimer) {
            [_levelTimer invalidate];
            [_levelTimer release];
            _levelTimer = nil;
        }
        _levelTimer = [[NSTimer scheduledTimerWithTimeInterval:kMeterRefresh target:self selector:@selector(levelTimerCallback:) userInfo:nil repeats:YES] retain];


        if (_statisticsAudioTimer) {
            [_statisticsAudioTimer invalidate];
            [_statisticsAudioTimer release];
            _statisticsAudioTimer = nil;
        }
        _statisticsAudioTimer = [[NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(statisticsAudioTimeEvent:) userInfo:nil repeats:YES] retain];
        _currentAudioTime = 0;

        _isCancelRecord = NO;
    }
}


/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*
*
*                   停止录音，这里采用了延迟录音的方式
*                   防止用户那一刹那还在说话的情况
*
*
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
- (void)stopRecorder:(id)sender {
    if (_recorder && _recorder.recording) {
        [self performSelector:@selector(delayStop) withObject:nil afterDelay:0.25];
    }
}


/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*
*
*                   取消录音的方式是做了一个取消标识
*                   然后仍然走录音停止的方法
*
*
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
- (void)cancelRecorder:(id)sender {
    if (_recorder && _recorder.recording) {
        _isCancelRecord = YES;
        [self stopRecorder:nil];
    }
}


- (NSData* )getVoiceFileFormLocation:(NSString *)path {
    if (nil == path || path.length <= 0) {
        return nil;
    }
    NSString *pathMD5 = [self md5:path];
    NSString *locationPath = [self.voiceCacheLib stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@.amr", pathMD5]];
    if (NO == [[NSFileManager defaultManager] fileExistsAtPath:locationPath]) {
        return nil;
    }
    NSData *data = [NSData dataWithContentsOfFile:locationPath];
    return data;
}

-(void) saveVoiceFileToLocation:(NSData *) data forKey:(NSString*) key {
    if (nil == data) {
        return;
    }

    if (nil == key || key.length <= 0) {
        return;
    }

    NSString *savePath = [self.voiceCacheLib stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@.amr", [self md5:key]]];
    if (nil == savePath) {
        return;
    }
    if (YES == [data writeToFile:savePath atomically:YES]) {
        NSLog(@"写入文件成功");
    }
}

+ (RecorderManager *)sharedInstance {
    if (nil == instance) {
        instance = [[RecorderManager alloc] init];
    }
    return instance;
}


// 准备开始录音
- (void)prepareRecord {

    // 这里是为了处理后台有音频播放时，停止后台的音频
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *err = nil;
    [audioSession setCategory :AVAudioSessionCategoryPlayAndRecord error:&err];
    if(err){
        NSLog(@"audioSession: %@ %d %@", [err domain], [err code], [[err userInfo] description]);
        return;
    }
    [audioSession setActive:YES error:&err];
    err = nil;
    if(err){
        NSLog(@"audioSession: %@ %d %@", [err domain], [err code], [[err userInfo] description]);
        return;
    }

    // 如果不为空，则先释放一次
    if (_recordSetting) {
        [_recordSetting release];
        _recordSetting = nil;
    }
    // 设置录音属性
    _recordSetting = [[NSMutableDictionary alloc] init];

    // 1 设置语音格式 目前使用PCM的消息格式，在播放PCM的时候，可以进行硬件加速，这个格式是IOS上最适合的格式
    [_recordSetting setObject:[NSNumber numberWithInt: kAudioFormatLinearPCM] forKey: AVFormatIDKey];

    // 2 设置采样率 采样率8000
    [_recordSetting setObject:[NSNumber numberWithFloat:8000.0] forKey: AVSampleRateKey];

    // 3 消息通道数目 目前只使用单通道进行录音
    [_recordSetting setObject:[NSNumber numberWithInt:1]forKey:AVNumberOfChannelsKey];

    // 4 采样位数 默认采用16BIT
    [_recordSetting setObject:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];

    // 设置录音源文件存放位置
    _filePath = [NSHomeDirectory() stringByAppendingPathComponent: @"Documents/recording.caf"];

    // 创建一个录音器
    err = nil;


    if (_recorder) {
        if (_recorder.recording) {
            [_recorder stop];
        }
        [_recorder release];
        _recorder = nil;
    }

    _recorder = [[ AVAudioRecorder alloc] initWithURL:[NSURL fileURLWithPath:_filePath] settings:_recordSetting error:&err];
    // 如果录音播放器创建成功
    if (!_recorder) {
        NSLog(@"录音失败");
        return;
    }

    // 设置代理，以及准备播放
    [_recorder setDelegate:self];
    [_recorder prepareToRecord];
    _recorder.meteringEnabled = YES; // 启用计量器 如果启用这个，则可以显示测试到当前的分贝数
    BOOL audioHWAvailable = audioSession.inputIsAvailable;
    if (!audioHWAvailable) {
        NSLog(@"音频硬件输入有问题");
    }
}

- (void)levelTimerCallback:(NSTimer*)sender {
    if (_recorder) {
        [_recorder updateMeters]; // 更新当前的信息
        CGFloat value = ([_recorder averagePowerForChannel:0]+kdBOffset)/kdBOffset; // 获取录音的分贝数
        NSLog(@"value = %f",value); // 现在只是打印了这个值
        self.currentSoundDecibels = value; // 在这里是每0.03" 就进行一次取样
    }
}

- (void)delayStop {
    // 延迟停止录音，防止后面的录不上
    // 停止录音
    [_recorder stop];
    // 释放这个录音播放器
    [_recorder release];
    _recorder = nil;

    // 如果后台有音乐播放，则需要进行恢复


    // 停止计时器
    if (_levelTimer) {
        [_levelTimer invalidate];
        [_levelTimer release];
        _levelTimer = nil;
    }

    // 停止计时器
    if (_statisticsAudioTimer) {
        [_statisticsAudioTimer invalidate];
        [_statisticsAudioTimer release];
        _statisticsAudioTimer = nil;
    }

}

- (void)statisticsAudioTimeEvent:(id)sender {
    _currentAudioTime += 1.0f;
    if (_currentAudioTime >= kMaxRecordTime) { // 这里可以设置一个最大的录音时长
        [self stopRecorder:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"recorderMaxTime" object:nil];
    }

}


-(BOOL)isRecording {
    return self.recorder.isRecording;
}



/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*
*
*                   录音完成的回调方法
*
*
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
#pragma mark 录音委托方法  录音完成
-(void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    // 这里一定要加上这句，这样如果是在后台有音乐的状态下录音，停止录音后可以恢复音乐播放
    [[AVAudioSession sharedInstance] setActive:NO error:nil];
    if (self.currentAudioTime < 1.0 && NO == _isCancelRecord) {
        NSLog(@"录音时长太短");
        return;
    }

    NSLog(@"录音成功");
    // 获取到存放录音源文件的路径
    _filePath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/recording.caf"];
    //录制完成把文件转成amr的再保存

    // 获取一个当前时间的MD5值 作为一个唯一的标识
    NSString *_currentDate = [self transDateToFormatString:[NSDate date] withFormat:@"yyyyMMddhhmmss"];
    NSString *amrFileName = [self md5:_currentDate];
    NSString *filePath2 = [NSString stringWithFormat:@"%@/%@.amr", self.voiceCacheLib, amrFileName];
    // 获取到录音源文件中的Data
    NSData *cafData = [NSData dataWithContentsOfFile:_filePath];
    // 打印录音源文件的总长度
    NSLog(@"音频源文件总长度 :%d \n", [cafData length]);
    // 将data转换为AMR的格式
    NSData *amrData = EncodeWAVEToAMR(cafData, 1, 16);
    // 将amr数据data写入到文件中
    [amrData writeToFile:filePath2 atomically:YES];
    // 打印转换后的AMR的长度
    NSLog(@"转换后的AMR文件总长度 :%d \n", [amrData length]);
    // 发送一个广播，将录音完成的消息发送出去

    if (NO == _isCancelRecord) {
        // 发送消息，通知录音结束
        [[NSNotificationCenter defaultCenter] postNotificationName:@"recordFinish" object:nil];
    }

}


-(NSString *) transDateToFormatString:(NSDate*) date withFormat:(NSString *) format{
    if (nil == date || nil == format) {
        return @"";
    }
    NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    [dateFormatter setDateFormat:format];
    NSString *resultDateString = [dateFormatter stringFromDate:date];
    return resultDateString;
}

-(NSString*) md5:(NSString*) str {
    const char *cStr = [str UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5( cStr, strlen(cStr), result );

    return [NSString stringWithFormat:
            @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
    ];
}


- (void)dealloc {
    [_recorderStartTime release],_recorderStartTime = nil;
    [_levelTimer invalidate],[_levelTimer release], _levelTimer = nil;
    [_filePath release],_filePath = nil;
    [_recorder release], _recorder = nil;
    [_recordSetting release], _recordSetting = nil;
    [_voiceCacheLib release], _voiceCacheLib = nil;
    [_statisticsAudioTimer release], _statisticsAudioTimer = nil;
    [super dealloc];
}


@end