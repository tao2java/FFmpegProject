//
//  CaptureData.m
//  Test
//
//  Created by lanqiang on 15/9/23.
//  Copyright © 2015年 lianqiang. All rights reserved.
//

#import "CaptureData.h"
#import "avcodec.h"
#import "swscale.h"

@interface CaptureData ()
{
    
}
@property(nonatomic,strong) NSMutableArray *dataArray;

@end

@implementation CaptureData
{
    long _lastTime;
    int fps;
    NSArray *datas;
}



@synthesize avCaptureSession;
@synthesize labelState;



-(id)init
{
    if(self= [super init])
    {
        producerFps= 50;
        
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
        [labelState setText:@"Already capturing"];
        return;
    }
    
    if((self->avCaptureDevice = [self getFrontCamera]) == nil)
    {
        [labelState setText:@"Failed to get valide capture device"];
        return;
    }
    
    NSError *error = nil;
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:self->avCaptureDevice error:&error];
    if (!videoInput)
    {
        [labelState setText:@"Failed to get video input"];
        self->avCaptureDevice= nil;
        return;
    }
    
    self->avCaptureSession = [[AVCaptureSession alloc] init];
    self->avCaptureSession.sessionPreset = AVCaptureSessionPresetLow;
    [self->avCaptureSession addInput:videoInput];
    
    // Currently, the only supported key is kCVPixelBufferPixelFormatTypeKey. Recommended pixel format choices are
    // kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange or kCVPixelFormatType_32BGRA.
    // On iPhone 3G, the recommended pixel format choices are kCVPixelFormatType_422YpCbCr8 or kCVPixelFormatType_32BGRA.
    //
    AVCaptureVideoDataOutput *avCaptureVideoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    NSDictionary*settings = [NSDictionary dictionaryWithObject:
                             [NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange]
                                                        forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    
//    [self->avCaptureDevice setActiveVideoMinFrameDuration:CMTimeMake(1, self->producerFps)];
    avCaptureVideoDataOutput.videoSettings = settings;
    avCaptureVideoDataOutput.minFrameDuration = CMTimeMake(1, self->producerFps);
    /*We create a serial queue to handle the processing of our frames*/
    dispatch_queue_t queue = dispatch_queue_create("org.doubango.idoubs", NULL);
    [avCaptureVideoDataOutput setSampleBufferDelegate:self queue:queue];
    [self->avCaptureSession addOutput:avCaptureVideoDataOutput];
    
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
}

#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    //捕捉数据输出 要怎么处理虽你便
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    /*帧数处理*/
    //是为了防止程序在向顶点缓冲区中写入顶点数据或修改缓冲区中顶点数据时，显示卡不等待程序输入或修改完毕便直接将这些尚未完成的数据显示到屏幕中的问题（显示卡硬件刷新的速度很多时候会快于程序刷写顶点缓存的速度，也就是说当程序还未完成顶点数据写入时，显卡硬件可能早已经完成了前一帧画面的输出，又回过头来重复操作了），这样会造成图像输出错误等。
    //see http://zhidao.baidu.com/link?url=8vMlKBs5CzQgaIsqzxWeB3crWqdlYIvyEjNElonB9bK48zTNVE3LonDyFhtM_b3DhbzRfponadhGAW7CyC9DsrjMWHtzLUNQbiatnfVViLy
    if(CVPixelBufferLockBaseAddress(pixelBuffer, 0) == kCVReturnSuccess)
    {

        NSDateComponents *model=[self getNowTimeModel];
        long currTime=[model second];
        if(currTime!=_lastTime){
            _lastTime=currTime;
            NSLog(@"=====> fps:%d",fps);
            fps=0;
        }else {
            fps++;
    }
       AVFrame *avFrame=[self convertToFFMpegFrame:sampleBuffer];
        int width = CVPixelBufferGetWidth(pixelBuffer);
        int height = CVPixelBufferGetHeight(pixelBuffer);
        [self encodeh264:avFrame with:width andHeight:height];
        
    //        UInt8 *bufferPtr = (UInt8 *)CVPixelBufferGetBaseAddress(pixelBuffer);
//        size_t buffeSize = CVPixelBufferGetDataSize(pixelBuffer);
        
                int pixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer);
                switch (pixelFormat) {
                    case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:
                        //TMEDIA_PRODUCER(producer)->video.chroma = tmedia_nv12; // iPhone 3GS or 4
//                        NSLog(@"Capture pixel format=NV12");
                        break;
                    case kCVPixelFormatType_422YpCbCr8:
                        //TMEDIA_PRODUCER(producer)->video.chroma = tmedia_uyvy422; // iPhone 3
//                        NSLog(@"Capture pixel format=UYUY422");
                        break;
                    default:
                        //TMEDIA_PRODUCER(producer)->video.chroma = tmedia_rgb32;
//                        NSLog(@"Capture pixel format=RGB32");
                        break;
                }
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    }
}


#pragma mark - Private Method

-(void)encodeh264:(AVFrame*)avframe with:(int)with andHeight:(int)height
{
    AVCodec *pCodecH264; //编码器
    
    
    //查找h264编码器
    avcodec_register_all();
    pCodecH264 = avcodec_find_encoder(AV_CODEC_ID_H264);
    if(!pCodecH264)
    {
        fprintf(stderr, "h264 codec not found\n");
        exit(1);  
    }
    AVCodecContext *c= avcodec_alloc_context3(pCodecH264);
    c->bit_rate = 3000000;// put sample parameters
    c->width =with;//
    c->height = height;//
    
    // 帧数率
    AVRational rate;
    rate.num = 1;
    rate.den = 25;
    c->time_base= rate;//(AVRational){1,25};
    c->gop_size = 10; // emit one intra frame every ten frames
    c->max_b_frames=1;
    c->thread_count = 1;
    c->pix_fmt = AV_PIX_FMT_NV12;//PIX_FMT_RGB24;
    //打开编码器
    
    if(avcodec_open2(c,pCodecH264,NULL)<0)
    {
       NSLog(@"不能打开编码库");
        exit(1);
    }
    
    //初始化SwsContext
    AVFrame *dstFrame=av_frame_alloc();
    
    struct SwsContext * scxt = sws_getContext(c->width,c->height,AV_PIX_FMT_NV12,c->width,c->height,PIX_FMT_YUV420P,SWS_POINT,NULL,NULL,NULL);
    sws_scale(scxt, (const uint8_t**)avframe->data, avframe->linesize, 0, c->height, dstFrame->data, dstFrame->linesize);
    av_frame_free(&dstFrame);
    av_frame_free(&avframe);
    avcodec_free_context(&c);
    sws_freeContext(scxt);
}



/**
 CMSampleBufferRef 转换为NSData数据
 提示：此方法不提供缓冲地址锁定
 */
-(NSData*)imageToBuffer:(CMSampleBufferRef)source
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(source);
    
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
//    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    void *src_buff = CVPixelBufferGetBaseAddress(imageBuffer);
    NSData *data = [NSData dataWithBytes:src_buff length:bytesPerRow * height];
    return data;
}

/**
 CMSampleBufferRef 转换为FFMPEG的AVFrame数据
 提示：此方法不提供缓冲地址锁定
 */
-(AVFrame *)convertToFFMpegFrame:(CMSampleBufferRef)source
{
    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(source);
    // 访问数据
    int width = CVPixelBufferGetWidth(pixelBuffer);
    int height = CVPixelBufferGetHeight(pixelBuffer);
    unsigned char *rawPixelBase = (unsigned char *)CVPixelBufferGetBaseAddress(pixelBuffer);
    
    AVFrame *pFrame;
    pFrame = av_frame_alloc();
    avpicture_fill((AVPicture*)pFrame, rawPixelBase, AV_PIX_FMT_NV12, width, height);
    return pFrame;
}


-(NSDateComponents *)getNowTimeModel
{
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];//1 对于被autorelease的对象，Leak工具也会视其为泄露，自己知道没问题就行。
    NSDate *now;
    NSDateComponents *comps;
    NSInteger unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSWeekdayCalendarUnit |
    NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
    now=[NSDate date];
    comps = [calendar components:unitFlags fromDate:now];
    return comps ;
}

#pragma mark - InitVar
-(NSMutableArray *)dataArray
{
    if(!_dataArray)
    {
        _dataArray=[[NSMutableArray alloc]init];
    }
    return _dataArray;
}
@end
