//
//  CaptureData.h
//  Test
//
//  Created by lanqiang on 15/9/23.
//  Copyright © 2015年 lianqiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface CaptureData : UIViewController<AVCaptureVideoDataOutputSampleBufferDelegate>
{
    //UI
    UILabel*labelState;
    UIButton*btnStartVideo;
    UIView*localView;
    
    AVCaptureSession* avCaptureSession;
    AVCaptureDevice *avCaptureDevice;
    int producerFps;
}

@property (nonatomic, retain) AVCaptureSession *avCaptureSession;
@property (nonatomic, retain) UILabel *labelState;


- (void)createControl;
- (AVCaptureDevice *)getFrontCamera;
- (void)startVideoCapture;
- (void)stopVideoCapture:(id)arg;

@end
