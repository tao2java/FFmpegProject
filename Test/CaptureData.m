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
#import "imgutils.h"
#import "avformat.h"
#import "opt.h"

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
    AVCodecContext *context;
    AVCodec *codec;
    NSInteger timestamp;
}



@synthesize avCaptureSession;
@synthesize labelState;


-(void)dealloc
{
    avcodec_close(context);
    av_free(context);
}

-(id)init
{
    if(self= [super init])
    {
        producerFps= 30;
        timestamp=0;
        avcodec_register_all();
        codec=avcodec_find_encoder(AV_CODEC_ID_H264);
        if (!codec) {
            fprintf(stderr, "h264 codec not found\n");
            exit(1);
        }
        context= avcodec_alloc_context3(codec);
        context->bit_rate = 240000;
        context->width = 352;//width;//352;
        context->height = 288;//height;//288;
        context->time_base= (AVRational){1,25};
        context->gop_size = 10;
        context->max_b_frames=1;
        context->pix_fmt = AV_PIX_FMT_YUV420P;
        context->thread_count = 1;
        AVDictionary * codec_options=NULL;
        av_dict_set( &codec_options, "preset", "superfast", 0 );
        av_dict_set(&codec_options, "tune", "zerolatency", 0);
        if (avcodec_open2(context, codec,&codec_options) < 0) {
            fprintf(stderr, "could not open codec\n");
            exit(1);
        }

        
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
    NSDictionary*settings = [NSDictionary dictionaryWithObject:
                             [NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange]
                                                        forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    
//    [self->avCaptureDevice setActiveVideoMinFrameDuration:CMTimeMake(1, self->producerFps)];
    avCaptureVideoDataOutput.videoSettings = settings;
//    [avCaptureDevice setActiveVideoMinFrameDuration:CMTimeMake(1, self->producerFps)];
    avCaptureVideoDataOutput.minFrameDuration = CMTimeMake(1, self->producerFps);
    /*创建一个并行队列绑定到帧数进程上去*/
    dispatch_queue_t queue = dispatch_queue_create("com.bigkiang.shangjiang", NULL);
    [avCaptureVideoDataOutput setSampleBufferDelegate:self queue:queue];
    [self->avCaptureSession addOutput:avCaptureVideoDataOutput];
    
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
}

#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    //捕捉数据输出 要怎么处理虽你便
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    /*帧数处理*/
    //锁定顶点缓冲区
    //是为了防止程序在向顶点缓冲区中写入顶点数据或修改缓冲区中顶点数据时，显示卡不等待程序输入或修改完毕便直接将这些尚未完成的数据显示到屏幕中的问题（显示卡硬件刷新的速度很多时候会快于程序刷写顶点缓存的速度，也就是说当程序还未完成顶点数据写入时，显卡硬件可能早已经完成了前一帧画面的输出，又回过头来重复操作了），这样会造成图像输出错误等。
    //see http://zhidao.baidu.com/link?url=8vMlKBs5CzQgaIsqzxWeB3crWqdlYIvyEjNElonB9bK48zTNVE3LonDyFhtM_b3DhbzRfponadhGAW7CyC9DsrjMWHtzLUNQbiatnfVViLy
    if(CVPixelBufferLockBaseAddress(pixelBuffer, 0) == kCVReturnSuccess)
    {
        [self encodeH264:sampleBuffer];
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    }
}

#pragma mark - Private Method

/**
 
 编码为h264
 
 */
-(void)encodeH264:(CMSampleBufferRef)sampleBuffer
{

    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // 访问数据
    int width = (int)CVPixelBufferGetWidth(pixelBuffer);
    int height = (int)CVPixelBufferGetHeight(pixelBuffer);
    int pixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer);
    enum AVPixelFormat pix_fmt;
    if (pixelFormat == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)
    {
        pix_fmt = AV_PIX_FMT_NV12;
    }
    else
    {
        pix_fmt = AV_PIX_FMT_BGR32;
    }
    
    AVFrame *pFrame=av_frame_alloc();
    pFrame->quality = 0;
    unsigned char *rawPixelBase = (unsigned char *)CVPixelBufferGetBaseAddress(pixelBuffer);
    av_image_fill_arrays(pFrame->data, pFrame->linesize, rawPixelBase, pix_fmt, width, height, 1);
    AVFrame* outFrame = av_frame_alloc();
    int  out_size, size, outbuf_size;
    uint8_t *outbuf;
    outbuf_size = 100000;
    outbuf = (uint8_t *)malloc(outbuf_size);
    size = context->width * context->height;
    AVPacket avpkt;//是存储压缩编码数据相关信息的结构体 data：压缩编码的数据。
//   int nbytes=av_image_get_buffer_size(AV_PIX_FMT_YUV420P, context->width, context->height, 1);
    int nbytes = avpicture_get_size(AV_PIX_FMT_YUV420P, context->width, context->height);
    uint8_t* outbuffer = (uint8_t*)av_malloc(nbytes);
    fflush(stdout);
    avpicture_fill((AVPicture*)outFrame, outbuffer, AV_PIX_FMT_YUV420P, context->width, context->height);
//    av_image_fill_arrays(outFrame->data, outFrame->linesize, outbuffer, AV_PIX_FMT_YUV420P, width, height, 1);
    struct SwsContext* fooContext = sws_getContext(width, height,
                                                   pix_fmt,
                                                   context->width, context->height,
                                                   AV_PIX_FMT_YUV420P,
                                                   SWS_POINT, NULL, NULL, NULL);
//    pFrame->data[0]  += pFrame->linesize[0] * (height - 1);
//    pFrame->linesize[0] *= -1;
//    pFrame->data[1]  += pFrame->linesize[1] * (height / 2 - 1);
//    pFrame->linesize[1] *= -1;
//    pFrame->data[2]  += pFrame->linesize[2] * (height / 2 - 1);
//    pFrame->linesize[2] *= -1;
    
    sws_scale(fooContext,(const uint8_t**)pFrame->data, pFrame->linesize, 0, height, outFrame->data, outFrame->linesize);
    // Here is where I try to convert to YUV
//    NSLog(@"xxxxx=====%d",xx);
    
    /* encode the image */
    int got_packet_ptr = 0;
    av_init_packet(&avpkt);
    avpkt.size = outbuf_size;
    avpkt.data = outbuf;
    outFrame->pts=timestamp;
    timestamp++;
    out_size = avcodec_encode_video2(context, &avpkt, outFrame, &got_packet_ptr);

    
//    printf("encoding frame (size=%5d)\n", out_size);
    printf("encoding frame %s\n", avpkt.data);
//    AVFormatContext *outFormatContext=avformat_alloc_context();
//    avp
    
    
//    NSLog(@"code end");
    
//    av_free(pFrame);
//    av_free(outFrame);
    av_frame_free(&pFrame);
    av_frame_free(&outFrame);
    av_packet_unref(&avpkt);
    sws_freeContext(fooContext);
    free(outbuf);
    free(outbuffer);
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
    int errorCode=avpicture_fill((AVPicture*)pFrame, rawPixelBase, AV_PIX_FMT_NV12, width, height);
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
