//
//  CaptureData.m
//  Test
//
//  Created by lanqiang on 15/9/23.
//  Copyright © 2015年 lianqiang. All rights reserved.
//

#import "CaptureData.h"
#import "CoreService.h"

@interface CaptureData ()
{
    CoreService *service;
    AVCaptureConnection             *videoCaptureConnection;
}
@property(nonatomic,strong) NSMutableArray *dataArray;

@end

@implementation CaptureData
{
}



@synthesize avCaptureSession;
@synthesize labelState;


-(void)dealloc
{
   
}

-(id)init
{
    if(self= [super init])
    {
        service=[CoreService new];
    }
    return self;
}


- (void)loadView {
    [super loadView];
    [self createControl];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


- (void)viewDidUnload {
    [super viewDidUnload];
}






#pragma mark -
#pragma mark createControl
- (void)createControl
{
    //UI展示
    self.view.backgroundColor= [UIColor grayColor];
    labelState= [[UILabel alloc] initWithFrame:CGRectMake(10, 20, 220, 30)];
    labelState.backgroundColor= [UIColor clearColor];
    [self.view addSubview:labelState];
    
    btnStartVideo= [[UIButton alloc] initWithFrame:CGRectMake(20, 350, 80, 50)];
    [btnStartVideo setTitle:@"Star"forState:UIControlStateNormal];
    
    
    [btnStartVideo setBackgroundImage:[UIImage imageNamed:@"Images/button.png"] forState:UIControlStateNormal];
    [btnStartVideo addTarget:self action:@selector(startVideoCapture) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnStartVideo];
    
    UIButton* stop = [[UIButton alloc] initWithFrame:CGRectMake(120, 350, 80, 50)];
    [stop setTitle:@"Stop"forState:UIControlStateNormal];
    
    [stop setBackgroundImage:[UIImage imageNamed:@"Images/button.png"] forState:UIControlStateNormal];
    [stop addTarget:self action:@selector(stopVideoCapture:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:stop];
    
    localView= [[UIView alloc] initWithFrame:CGRectMake(40, 50, 200, 300)];
    [self.view addSubview:localView];
    
    
}
#pragma mark -
#pragma mark VideoCapture
- (AVCaptureDevice *)getFrontCamera
{
    //获取前置摄像头设备
    NSArray *cameras = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in cameras)
    {
        if (device.position == AVCaptureDevicePositionBack)
            return device;
    }
    return [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
}
- (void)startVideoCapture
{
    //打开摄像设备，并开始捕抓图像
    [labelState setText:@"Starting Video stream"];
    if(self->avCaptureDevice|| self->avCaptureSession)
    {
        [labelState setText:@"摄像头正在运行"];
        return;
    }
    
    if((self->avCaptureDevice = [self getFrontCamera]) == nil)
    {
        [labelState setText:@"获取摄像头失败"];
        return;
    }
    
    NSError *error = nil;
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:self->avCaptureDevice error:&error];
    if (!videoInput)
    {
        [labelState setText:@"获取视频输入失败"];
        self->avCaptureDevice= nil;
        return;
    }
    
    self->avCaptureSession = [[AVCaptureSession alloc] init];
    self->avCaptureSession.sessionPreset = AVCaptureSessionPresetLow;//适用于3G传输
    [self->avCaptureSession addInput:videoInput];//添加输入设备
    
    // Currently, the only supported key is kCVPixelBufferPixelFormatTypeKey. Recommended pixel format choices are
    // kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange or kCVPixelFormatType_32BGRA.
    // On iPhone 3G, the recommended pixel format choices are kCVPixelFormatType_422YpCbCr8 or kCVPixelFormatType_32BGRA.
    //
    AVCaptureVideoDataOutput *avCaptureVideoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
//    NSDictionary*settings = [NSDictionary dictionaryWithObject:
//                             [NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange]
//                                                        forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    NSDictionary *settings = [[NSDictionary alloc] initWithObjectsAndKeys:
                              [NSNumber numberWithUnsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange],
                              kCVPixelBufferPixelFormatTypeKey,
                              nil]; // X264_CSP_NV12
    
//    [self->avCaptureDevice setActiveVideoMinFrameDuration:CMTimeMake(1, 25)];
    avCaptureVideoDataOutput.videoSettings = settings;
    avCaptureVideoDataOutput.alwaysDiscardsLateVideoFrames = YES;
//    [avCaptureDevice setActiveVideoMinFrameDuration:CMTimeMake(1, self->producerFps)];
    avCaptureVideoDataOutput.minFrameDuration = CMTimeMake(1, 25);
    /*创建一个并行队列绑定到帧数进程上去*/
    dispatch_queue_t queue = dispatch_queue_create("com.bigkiang.shangjiang", NULL);
    [avCaptureVideoDataOutput setSampleBufferDelegate:self queue:queue];
    [self->avCaptureSession addOutput:avCaptureVideoDataOutput];
    // 保存Connection，用于在SampleBufferDelegate中判断数据来源（是Video/Audio？）
//    if(videoCaptureConnection==nil){
        videoCaptureConnection = [avCaptureVideoDataOutput connectionWithMediaType:AVMediaTypeVideo];
//    }
    //视频捕捉预览
    AVCaptureVideoPreviewLayer* previewLayer = [AVCaptureVideoPreviewLayer layerWithSession: self->avCaptureSession];
    previewLayer.frame = localView.bounds;
    previewLayer.videoGravity= AVLayerVideoGravityResizeAspectFill;
    
    [self->localView.layer addSublayer: previewLayer];
    
    [self->avCaptureSession startRunning];
    
    [labelState setText:@"Video capture started"];
    
}
- (void)stopVideoCapture:(id)arg
{
    //停止摄像头捕抓
    
    if(self->avCaptureSession){
        [self->avCaptureSession stopRunning];
        self->avCaptureSession= nil;
        [labelState setText:@"Video capture stopped"];
    }
    self->avCaptureDevice= nil;
    //移除localView里面的内容
    for(UIView*view in self->localView.subviews) {
        [view removeFromSuperview];
    }
    videoCaptureConnection=nil;
    [service freeX264Resource];
}

#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    //捕捉数据输出 要怎么处理虽你便
//    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    /*帧数处理*/
    //锁定顶点缓冲区
    //是为了防止程序在向顶点缓冲区中写入顶点数据或修改缓冲区中顶点数据时，显示卡不等待程序输入或修改完毕便直接将这些尚未完成的数据显示到屏幕中的问题（显示卡硬件刷新的速度很多时候会快于程序刷写顶点缓存的速度，也就是说当程序还未完成顶点数据写入时，显卡硬件可能早已经完成了前一帧画面的输出，又回过头来重复操作了），这样会造成图像输出错误等。
    //see http://zhidao.baidu.com/link?url=8vMlKBs5CzQgaIsqzxWeB3crWqdlYIvyEjNElonB9bK48zTNVE3LonDyFhtM_b3DhbzRfponadhGAW7CyC9DsrjMWHtzLUNQbiatnfVViLy
//    if(CVPixelBufferLockBaseAddress(pixelBuffer, 0) == kCVReturnSuccess)
//    {
    // 这里的sampleBuffer就是采集到的数据了，但它是Video还是Audio的数据，得根据connection来判断
    if (connection == videoCaptureConnection) {
        
        [self encodeH264:sampleBuffer];
        
    }
    

//        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
//    }
}

#pragma mark - Private Method

/**
 
 编码为h264
 
 */
-(void)encodeH264:(CMSampleBufferRef)sampleBuffer
{
    [service encoderToH264:sampleBuffer];
}



-(NSDateComponents *)getNowTimeModel
{
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDate *now;
    NSDateComponents *comps;
    NSInteger unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSWeekdayCalendarUnit |
    NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
    now=[NSDate date];
    comps = [calendar components:unitFlags fromDate:now];
    return comps ;
}
@end
