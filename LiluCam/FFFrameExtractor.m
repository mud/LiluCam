//
//  FFFrameExtractor.m
//  LiluCam
//
//  Created by Takashi Okamoto on 12/15/13.
//  Copyright (c) 2013 Takashi Okamoto. All rights reserved.
//

#import "FFFrameExtractor.h"

#include <avcodec.h>
#include <avformat.h>
#include <swscale.h>


// http://stackoverflow.com/questions/18003034/installing-ffmpeg-ios-libraries-armv7-armv7s-i386-and-universal-on-mac-with-10/19370679#19370679
// http://dranger.com/ffmpeg/tutorial01.html

@interface FFFrameExtractor () {
    dispatch_queue_t backgroundQueue;
    
    AVFormatContext *pFormatContext;
    AVCodecContext *pCodecContext;
    AVCodecContext *pAudioCodecContext;
    AVPacket packet;
    int videoStream;
    int audioStream;
    
    AVFrame *pFrame;
    AVPicture picture;
    struct SwsContext *imageConvertContext;
}


// sets up audio/video contexts given a URL
int8_t SetupAVContextForURL(AVFormatContext **pFormatContext, AVCodecContext **pCodecContext, AVCodecContext **pAudioCodecContext, int *pVideoStream, int *pAudioStream, const char *rstpURL);

- (UIImage *)uiImageFromAVPicture:(AVPicture *)picture width:(int)width height:(int)height;

@end

@implementation FFFrameExtractor

- (id)initWithInputPath:(NSString *)path
{
    self = [super init];
    if (self) {
        avformat_network_init();
        avcodec_register_all();
        av_register_all();
        
        self.inputPath = path;
        
        // initialize format context and packet
        pFormatContext = avformat_alloc_context();
        av_init_packet(&packet);

        if (SetupAVContextForURL(&pFormatContext, &pCodecContext, &pAudioCodecContext, &videoStream, &audioStream, [self.inputPath UTF8String]) != 0) {
            NSLog(@"Couldn't initialize FFFrameExtractor.");
            return nil;
        }
        
        pFrame = avcodec_alloc_frame();
        int sourceWidth = pCodecContext->width;
        int sourceHeight = pCodecContext->height;
        
        // setup picture and swscaler
        imageConvertContext = sws_getContext(sourceWidth, sourceHeight, pCodecContext->pix_fmt, sourceWidth, sourceHeight, PIX_FMT_RGB24, SWS_FAST_BILINEAR, NULL, NULL, NULL);
        avpicture_alloc(&picture, PIX_FMT_RGB24, sourceWidth, sourceHeight);
        
        // create background queue
        backgroundQueue = dispatch_queue_create("com.buzamoto.FFFrameExtractor", NULL);
    }
    return self;
}

- (void)dealloc
{
    [self cleanup];
    avformat_network_deinit();
}

- (BOOL)nextFrame
{
    int frameFinished = 0;
    
    while (!frameFinished && av_read_frame(pFormatContext, &packet) >= 0) {
        // handle videoStream only for now
        if (packet.stream_index == videoStream) {
            // decode video frame
            int len = avcodec_decode_video2(pCodecContext, pFrame, &frameFinished, &packet);
            if (len < 0 || (packet.flags & AV_PKT_FLAG_CORRUPT)) {
                NSLog(@"Error decoding video");
                return NO;
            }
        }
        av_free_packet(&packet);
    }
    return frameFinished != 0;
}

- (BOOL)stop
{
    [self cleanup];
    return YES;
}

- (UIImage *)frameImage
{
    // convert image to RGB
    sws_scale(imageConvertContext, (const uint8_t * const *)pFrame->data, pFrame->linesize, 0, pCodecContext->height, picture.data, picture.linesize);
    // get picture
    return [self uiImageFromAVPicture:&picture width:pCodecContext->width height:pCodecContext->height];
}

- (void)processNextFrame
{
    dispatch_async(backgroundQueue, ^(void){
        BOOL nextFrame = [self nextFrame];
        if (nextFrame) {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                [self.delegate updateWithCurrentUIImage:[self frameImage]];
            });
        } else {
            NSLog(@"Error decoding next frame.");
        }
    });
}


#pragma mark Private Methods

- (void)cleanup
{
    NSLog(@"Cleanup FFFrameExtractor");
    sws_freeContext(imageConvertContext);
    avpicture_free(&picture);
    
    if (pFrame != NULL) {
        // need to clean pFrame buffer first
        avcodec_free_frame(&pFrame);
        pFrame = NULL;
    }
    
    if (pCodecContext != NULL) {
        avcodec_close(pCodecContext);
        pCodecContext = NULL;
    }
    
    if (pAudioCodecContext != NULL) {
        avcodec_close(pAudioCodecContext);
        pAudioCodecContext = NULL;
    }
    
    if (pFormatContext != NULL) {
        avformat_free_context(pFormatContext);
        pFormatContext = NULL;
    }
}

int8_t SetupAVContextForURL(AVFormatContext **pFormatContext, AVCodecContext **pCodecContext, AVCodecContext **pAudioCodecContext, int *pVideoStream, int *pAudioStream, const char *rstpURL) {
    AVCodec *pCodec;
    
    // Open video file
    int result = avformat_open_input(pFormatContext, rstpURL, NULL, NULL);
    if (result != 0) {
        NSLog(@"Couldn't open stream");
        return -1;
    }
    
    // dump stream info
    av_dump_format(*pFormatContext, 0, rstpURL, 0);
    
    // check for video stream
    int i = -1;
    int videoStream = i;
    int audioStream = i;
    for (i = 0; i < (*pFormatContext)->nb_streams; i++) {
        if ((*pFormatContext)->streams[i]->codec->codec_type == AVMEDIA_TYPE_VIDEO) {
            videoStream = i;
        } else if ((*pFormatContext)->streams[i]->codec->codec_type == AVMEDIA_TYPE_AUDIO) {
            audioStream = i;
        }
    }
    
    *pVideoStream = videoStream;
    *pAudioStream = audioStream;
    
    if (videoStream < 0) {
        NSLog(@"Couldn't get Video Stream");
        return -1;
    }
    
    if (audioStream < 0) {
        NSLog(@"Couldn't get Audio Stream");
        return -1;
    }
    
    NSLog(@"Got Streams: Video: %i, Audio: %i", videoStream, audioStream);
    
    // call stream info to fetch info
    if (avformat_find_stream_info(*pFormatContext, NULL) < 0) {
        NSLog(@"Couldn't get stream info");
        return -1;
    }
    
    // set video codec context and make sure codec exists
    *pCodecContext = (*pFormatContext)->streams[(unsigned int)videoStream]->codec;
    pCodec = avcodec_find_decoder((*pCodecContext)->codec_id);
    if (pCodec == NULL) {
        NSLog(@"Unsupported Video Codec");
        return -1;
    }
    if (avcodec_open2(*pCodecContext, pCodec, NULL) < 0) {
        NSLog(@"Couldn't open Video Codec");
        return -1;
    }
    
    // holy shit, turn this flag on and magically all the bad artifacts go away
    // source: http://lists.live555.com/pipermail/live-devel/2013-February/016561.html
    (*pCodecContext)->flags2 = CODEC_FLAG2_CHUNKS;
    
    // set audio codec context and make sure codec exists
    *pAudioCodecContext = (*pFormatContext)->streams[(unsigned int)audioStream]->codec;
    pCodec = avcodec_find_decoder((*pAudioCodecContext)->codec_id);
    if (pCodec == NULL) {
        NSLog(@"Unsupported Audio Codec");
        return -1;
    }
    if (avcodec_open2(*pAudioCodecContext, pCodec, NULL) < 0) {
        NSLog(@"Couldn't open Audio Codec");
        return -1;
    }
    
    return 0;
}

- (UIImage *)uiImageFromAVPicture:(AVPicture *)pPicture width:(int)width height:(int)height
{
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    size_t bitsPerComponent = 8;
    size_t bitsPerPixel = 24;
    size_t bytesPerRow = pPicture->linesize[0];
    
    //NSLog(@"Creating UIImage from AVPicture (bitsPerComponent: %zu, bitsPerPixel: %zu, bytesPerRow: %zu)", bitsPerComponent, bitsPerPixel, bytesPerRow);
    
    CFDataRef data = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, pPicture->data[0], bytesPerRow*height, kCFAllocatorNull);
    CGDataProviderRef dataProvider = CGDataProviderCreateWithCFData(data);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGImageRef cgImage = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpace, bitmapInfo, dataProvider, NULL, NO, kCGRenderingIntentDefault);
    
    // create the UIImage
    UIImage *image = [UIImage imageWithCGImage:cgImage scale:1 orientation:UIImageOrientationRight];
    //UIImage *image = [UIImage imageWithCGImage:cgImage];
    
    // release the suckers
    CGImageRelease(cgImage);
    CGColorSpaceRelease(colorSpace);
    CGDataProviderRelease(dataProvider);
    CFRelease(data);
    
    return image;
}

@end