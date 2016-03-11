//
//  CoreService.m
//  Test
//
//  Created by shikee_app03 on 16/3/10.
//  Copyright © 2016年 lianqiang. All rights reserved.
//

#import "CoreService.h"
#import "avformat.h"
#import "avcodec.h"

@implementation CoreService
{
    AVFormatContext *_pformatCtx;
    AVOutputFormat *_outFmt;//输出格式
    char *_fileName;
    char *_outUrl;
    AVStream *_video_st;
    AVCodecContext *_pCodecCtx;
    AVCodec *_pCodec;
    AVFrame *_pFrame;
    int in_w,in_h,_picture_size,_y_size;
    uint8_t* _picture_buf;
    AVPacket pkt;
    int64_t index;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initConfig];
    }
    return self;
}

-(void)initConfig
{
    _fileName="fuck.h264";
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachePath = [NSString stringWithFormat:@"%@/%s",[paths objectAtIndex:0],"bk.mp4"];
    const char *outUrl=[cachePath UTF8String];
    av_register_all();//注册FFmpeg所有编解码器。
    _pformatCtx=avformat_alloc_context();
    _outFmt=av_guess_format(NULL, _fileName, NULL);
    _pformatCtx->oformat=_outFmt;
    if (avio_open(&_pformatCtx->pb,outUrl, AVIO_FLAG_READ_WRITE) < 0){
        printf("Failed to open output file! \n");
        return ;
    }
    _video_st=avformat_new_stream(_pformatCtx, 0);
    _video_st->time_base.num=1;
    _video_st->time_base.den=25;
    
    if(!_video_st){
        printf("dog! your _video_st is empty! \n");
        return;
    }
    in_w=192;//480
    in_h=144;//360
    //这些参数必须设置
    _pCodecCtx = _video_st->codec;
    _pCodecCtx->codec_id = _outFmt->video_codec;
    _pCodecCtx->codec_type = AVMEDIA_TYPE_VIDEO;
    _pCodecCtx->pix_fmt = AV_PIX_FMT_YUV420P;
    _pCodecCtx->width = in_w;
    _pCodecCtx->height = in_h;//
    _pCodecCtx->time_base.num = _video_st->time_base.num;//时间基 分子
    _pCodecCtx->time_base.den = _video_st->time_base.den;//分母
    _pCodecCtx->bit_rate = 400000;//平均比特率
    _pCodecCtx->gop_size=250;
    _pCodecCtx->qmin = 10;
    _pCodecCtx->qmax = 51;
    _pCodecCtx->max_b_frames=3;
    AVDictionary *param = 0;
    //H.264
    if(_pCodecCtx->codec_id == AV_CODEC_ID_H264) {
        av_dict_set(& param, "preset", "slow", 0);
        av_dict_set(& param, "tune", "zerolatency", 0);
        //av_dict_set(& param, "profile", "main", 0);
    }else{
        printf("不是h264，编个毛啊 \n");
        return;
    }
    av_dump_format(_pformatCtx, 0, outUrl, 1);
    _pCodec = avcodec_find_encoder(_pCodecCtx->codec_id);
    if(!_pCodec){
        printf("_pCodec open failed");
        return;
    }
    //打开解码器
    if (avcodec_open2(_pCodecCtx, _pCodec,&param) < 0){
        printf("Failed to open encoder! \n");
        return ;
    }
    _pFrame = av_frame_alloc();
//    _picture_size = avpicture_get_size(_pCodecCtx->pix_fmt, _pCodecCtx->width, _pCodecCtx->height);
//    _picture_buf = (uint8_t *)av_malloc(_picture_size);
    avpicture_fill((AVPicture *)_pFrame, _picture_buf, _pCodecCtx->pix_fmt, _pCodecCtx->width,_pCodecCtx->height);
    //写入头文件
    avformat_write_header(_pformatCtx,NULL);
    av_new_packet(&pkt,_picture_size);
    /*
     3/2== 1+1/4+1/4==1+1/2==3/2
     一帧YUV420P像素数据一共占用w*h*3/2 Byte的数据。其中前w*h Byte存储Y，接着的w*h*1/4 Byte存储U，最后w*h*1/4 Byte存储V。
     
     av_new_packet()里面的y_size*3是预先分配的内存的大小，这里实际上是随意分配了一个比较大的内存空间（足以存下包括3个分量的1帧数据）。
     y_size*3/2是一帧YUV数据的大小。y+u+v
     y_size*5/4是V数据的起始点。 1+1/4
     
     @see http://blog.csdn.net/leixiaohua1020/article/details/50534150
     */
    _y_size=_pCodecCtx->width * _pCodecCtx->height;
   
}

- (void)encoderToH264:(CMSampleBufferRef)sampleBuffer
{
    CVPixelBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    if (CVPixelBufferLockBaseAddress(imageBuffer, 0) == kCVReturnSuccess) {
        
        //        int pixelFormat = CVPixelBufferGetPixelFormatType(imageBuffer);
        //        switch (pixelFormat) {
        //            case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:
        //                NSLog(@"Capture pixel format=NV12");
        //                break;
        //            case kCVPixelFormatType_422YpCbCr8:
        //                NSLog(@"Capture pixel format=UYUY422");
        //                break;
        //            default:
        //                NSLog(@"Capture pixel format=RGB32");
        //                break;
        //        }
        
        
//        UInt8 *bufferbasePtr = (UInt8 *)CVPixelBufferGetBaseAddress(imageBuffer);
        UInt8 *bufferPtr = (UInt8 *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer,0);
        UInt8 *bufferPtr1 = (UInt8 *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer,1);
//        size_t buffeSize = CVPixelBufferGetDataSize(imageBuffer);
        size_t width = CVPixelBufferGetWidth(imageBuffer);
        size_t height = CVPixelBufferGetHeight(imageBuffer);
//        size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
        size_t bytesrow0 = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer,0);//【平面】每行的大小bytes
        size_t bytesrow1  = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer,1);
//        size_t bytesrow2 = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer,2);
        UInt8 *yuv420_data = (UInt8 *)malloc(width * height *3/ 2); // buffer to store YUV with layout YYYYYYYYUUVV
        
        /* convert NV12 data to YUV420*/
        UInt8 *pY = bufferPtr ;
        UInt8 *pUV = bufferPtr1;
        UInt8 *pU = yuv420_data + width*height;
        UInt8 *pV = pU + width*height/4;
        for(int i =0;i<height;i++)
        {
            memcpy(yuv420_data+i*width,pY+i*bytesrow0,width);
        }
        for(int j = 0;j<height/2;j++)
        {
            for(int i =0;i<width/2;i++)
            {
                *(pU++) = pUV[i<<1];
                *(pV++) = pUV[(i<<1) + 1];
            }
            pUV+=bytesrow1;
        }
        
        // add code to push yuv420_data to video encoder here
        
        // scale
        // add code to scale image here
        // ...
        
        //Read raw YUV data 原始数据
        _picture_buf = yuv420_data;
        _pFrame->data[0] = _picture_buf;              // Y
        _pFrame->data[1] = _picture_buf+ _y_size;      // U
        _pFrame->data[2] = _picture_buf+ _y_size*5/4;  // V
        
        // PTS 时间戳
        _pFrame->pts = index;
        int got_picture = 0;
        
        // Encode
        _pFrame->width = in_w;
        _pFrame->height = in_h;
        _pFrame->format = AV_PIX_FMT_YUV420P;
        
        int ret = avcodec_encode_video2(_pCodecCtx, &pkt, _pFrame, &got_picture);
        if(ret < 0) {
            
            printf("Failed to encode! \n");
            
        }
        if (got_picture==1) {
            
            printf("Succeed to encode frame: %5lld\tsize:%5d\n", index, pkt.size);
            index++;
            pkt.stream_index = _video_st->index;
            ret = av_write_frame(_pformatCtx, &pkt);
//            av_free_packet(&pkt);
            av_packet_unref(&pkt);
        }
        
        free(yuv420_data);
    }
    
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
}

/*
 * 释放资源
 */
- (void)freeX264Resource
{
    //Flush Encoder
    int ret = flush_encoder(_pformatCtx,0);
    if (ret < 0) {
        
        printf("Flushing encoder failed\n");
    }
    
    //Write file trailer
    av_write_trailer(_pformatCtx);
    
    //Clean
    if (_video_st){
        avcodec_close(_video_st->codec);
        av_free(_pFrame);
        //        av_free(picture_buf);
    }
    avio_close(_pformatCtx->pb);
    avformat_free_context(_pformatCtx);
}

int flush_encoder(AVFormatContext *fmt_ctx,unsigned int stream_index)
{
    int ret;
    int got_frame;
    AVPacket enc_pkt;
    if (!(fmt_ctx->streams[stream_index]->codec->codec->capabilities &
          CODEC_CAP_DELAY))
        return 0;
    
    while (1) {
        enc_pkt.data = NULL;
        enc_pkt.size = 0;
        av_init_packet(&enc_pkt);
        ret = avcodec_encode_video2 (fmt_ctx->streams[stream_index]->codec, &enc_pkt,
                                     NULL, &got_frame);
        av_frame_free(NULL);
        if (ret < 0)
            break;
        if (!got_frame){
            ret=0;
            break;
        }
        printf("Flush Encoder: Succeed to encode 1 frame!\tsize:%5d\n",enc_pkt.size);
        /* mux encoded frame */
        ret = av_write_frame(fmt_ctx, &enc_pkt);
        if (ret < 0)
            break;
    }
    return ret;
}

@end
