//
//  CoreService.h
//  Test
//
//  Created by shikee_app03 on 16/3/10.
//  Copyright © 2016年 lianqiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

@interface CoreService : NSObject
- (void)encoderToH264:(CMSampleBufferRef)sampleBuffer;
- (void)freeX264Resource;
@end
