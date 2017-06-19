//
//  ViewController.m
//  ZSPhotoShow
//
//  Created by shenshen on 2015/6/18.
//  Copyright © 2015年 shenshen. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
@interface ViewController ()
@property (nonatomic, strong) AVCaptureSession * captureSession;//输入输出数据的传递；
@property (nonatomic, strong) AVCaptureDeviceInput * captureDeviceInput;//负责从设备获取数据
@property (nonatomic, strong) AVCaptureStillImageOutput * stillImageOutput;//照片输出流
@property (nonatomic, strong) AVCaptureVideoPreviewLayer * captureVideoPreViewLayer;//相机拍摄预览层
@property (nonatomic, strong) AVCaptureDevice * captureDevice;//获取摄像头
@property (weak, nonatomic) IBOutlet UIButton *lighAutoBtn;//自动闪光灯
@property (weak, nonatomic) IBOutlet UIButton *lighOpenBtn;//打开闪光灯
@property (weak, nonatomic) IBOutlet UIButton *lighCloseBtn;//关闭闪光灯
@property (weak, nonatomic) IBOutlet UIButton *takePhotoBtn;//拍照
@property (weak, nonatomic) IBOutlet UIView *photoView;//照片显示的view
@property (weak, nonatomic) IBOutlet UIImageView *focusCursor; //聚焦光圈


@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    [self cameraDescrip];
    [self.captureSession startRunning];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)cameraDescrip{
    self.captureSession = [[AVCaptureSession alloc]init];
    if ([self.captureSession canSetSessionPreset:AVCaptureSessionPreset1280x720]) {//设置分辨率
        self.captureSession.sessionPreset = AVCaptureSessionPreset1280x720;
    }
    
    AVCaptureDevice * device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    [device lockForConfiguration:nil];//设置设备要先锁定 否则会崩溃
    [device setFocusMode:AVCaptureFocusModeAutoFocus];//设置闪光灯为自动
    [device unlockForConfiguration];
    NSError * error;
    self.captureDeviceInput = [[AVCaptureDeviceInput alloc]initWithDevice:device error:&error];
    if (error) {
        NSLog(@"-----%@",error.localizedDescription);
    }
    
    //初始化输出设备
    self.stillImageOutput = [[AVCaptureStillImageOutput alloc]init];
    NSDictionary * outputDic = @{AVVideoCodecKey:AVVideoCodecJPEG};
    [self.stillImageOutput setOutputSettings:outputDic];
    
    if ([self.captureSession canAddInput:self.captureDeviceInput]) {
        [self.captureSession addInput:self.captureDeviceInput];
    }
    
    if ([self.captureSession canAddOutput:self.stillImageOutput]) {
        [self.captureSession addOutput:self.stillImageOutput];
    }
    
    self.captureVideoPreViewLayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:self.captureSession];
    CALayer * layer = (CALayer *)self.photoView.layer;
    layer.masksToBounds=YES;

    self.captureVideoPreViewLayer.frame = layer.bounds;
    self.captureVideoPreViewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;//填充模式
    [layer addSublayer:self.captureVideoPreViewLayer];
    
    [layer insertSublayer:self.captureVideoPreViewLayer below:self.focusCursor.layer];
    
    
    
    [self addNotficationCaptureDevice:self.captureDevice];
    [self addGenstureRecognizer];
}

//给输入设备添加通知
- (void)addNotficationCaptureDevice:(AVCaptureDevice *)captureDevice{
//注意添加区域改变捕获通知必须首先设置设备允许捕获
    [captureDevice lockForConfiguration:nil];
    captureDevice.subjectAreaChangeMonitoringEnabled = YES;
    [captureDevice unlockForConfiguration];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(areaChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:captureDevice];
}
/**
 *  捕获区域改变
 *
 *  @param notification 通知对象
 */
-(void)areaChange:(NSNotification *)notification{
    NSLog(@"捕获区域改变...");
}
-(void)removeNotificationFromCaptureDevice:(AVCaptureDevice *)captureDevice{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:captureDevice];
}

/**
 *  添加点按手势，点按时聚焦
 */
-(void)addGenstureRecognizer{
    UITapGestureRecognizer *tapGesture=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapFouces:)];
    [self.photoView addGestureRecognizer:tapGesture];
}

- (void)tapFouces:(UITapGestureRecognizer *)tap{
    CGPoint point = [tap locationInView:self.photoView];//点击部分的坐标
    self.focusCursor.center = point;//设置光圈的位置
    self.focusCursor.transform = CGAffineTransformMakeScale(1.5, 1.5);
    self.focusCursor.alpha = 1;
    [UIView animateWithDuration:1 animations:^{
        self.focusCursor.transform=CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        self.focusCursor.alpha = 0;
    }];
    [self focusWithMode:AVCaptureFocusModeAutoFocus exposureMode:AVCaptureExposureModeAutoExpose atPoint:point];
}

/**
 *  设置聚焦点
 *
 *  @param point 聚焦点
 */
-(void)focusWithMode:(AVCaptureFocusMode)focusMode exposureMode:(AVCaptureExposureMode)exposureMode atPoint:(CGPoint)point{
    AVCaptureDevice * device = [self.captureDeviceInput device];
    [device lockForConfiguration:nil];
        if ([device isFocusModeSupported:focusMode]) {
            [device setFocusMode:AVCaptureFocusModeAutoFocus];
        }
        if ([device isFocusPointOfInterestSupported]) {
            [device setFocusPointOfInterest:point];
        }
        if ([device isExposureModeSupported:exposureMode]) {
            [device setExposureMode:AVCaptureExposureModeAutoExpose];
        }
        if ([device isExposurePointOfInterestSupported]) {
            [device setExposurePointOfInterest:point];
        }
    [device unlockForConfiguration];

}
/**
 *  设置曝光模式
 *
 *  @param exposureMode 曝光模式
 */
-(void)setExposureMode:(AVCaptureExposureMode)exposureMode{
    AVCaptureDevice * device = [self.captureDeviceInput device];
    [device lockForConfiguration:nil];
    if ([device isExposureModeSupported:exposureMode]) {
        [device setExposureMode:exposureMode];
    }
    [device unlockForConfiguration];
}
/**
 *  设置闪光灯模式
 *
 *  @param flashMode 闪光灯模式
 */
- (void)setFlashMode:(AVCaptureFlashMode )flashMode{
    AVCaptureDevice * device = [self.captureDeviceInput device];
    [device lockForConfiguration:nil];
    if ([device isFlashModeSupported:flashMode]) {
        [device setFlashMode:flashMode];
    }
    [device unlockForConfiguration];
}
/**
 *设置闪光灯自动模式
 */
- (IBAction)flashModeAuto:(id)sender {
    [self setFlashMode:AVCaptureFlashModeAuto];
}

/**
 *设置打开闪光灯模式
 */
- (IBAction)flashModeOpen:(id)sender {
    [self setFlashMode:AVCaptureFlashModeOn];
}

/**
 *设置关闭闪光灯模式
 */
- (IBAction)flashModeClose:(id)sender {
    [self setFlashMode:AVCaptureFlashModeOff];
}
- (IBAction)photoDeviceFrontOrBack:(id)sender {
    AVCaptureDevice * currentDevice = [self.captureDeviceInput device];
    AVCaptureDevicePosition  currentPosition = [currentDevice position];
    [self removeNotificationFromCaptureDevice:currentDevice];
    AVCaptureDevice * newDevice;
    AVCaptureDevicePosition newDevicePositon = AVCaptureDevicePositionFront;
    if (currentPosition == AVCaptureDevicePositionUnspecified || currentPosition == AVCaptureDevicePositionFront) {
        newDevicePositon = AVCaptureDevicePositionBack;
    }
    newDevice = [self getCameraDeviceWithPosition:newDevicePositon];
    [self addNotficationCaptureDevice:newDevice];
    
    AVCaptureDeviceInput * captureDeviceInput = [[AVCaptureDeviceInput alloc]initWithDevice:newDevice error:nil];
    //改变配置前一定要先开启配置，配置完成后再提交
    [self.captureSession beginConfiguration];
    [self.captureSession removeInput:self.captureDeviceInput];//将原来输入对象移除添加改变之后的输入对象
    
    if ([self.captureSession canAddInput:captureDeviceInput]) {
        [self.captureSession addInput:captureDeviceInput];
        self.captureDeviceInput = captureDeviceInput;
    }
    //提交新配置
    [self.captureSession commitConfiguration];
    
}

/**
 *  取得指定位置的摄像头
 *
 *  @param position 摄像头位置
 *
 *  @return 摄像头设备
 */
-(AVCaptureDevice *)getCameraDeviceWithPosition:(AVCaptureDevicePosition )position{
    NSArray *cameras= [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *camera in cameras) {
        if ([camera position]==position) {
            return camera;
        }
    }
    return nil;
}
- (IBAction)takePhotoClick:(id)sender {
    AVCaptureConnection * captureConnection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:captureConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        if (imageDataSampleBuffer) {
            NSData * data = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            UIImage * img = [UIImage imageWithData:data];
            [self filterAction:nil image:img];
        }
    }];
}
//滤镜按钮的触发方法
- (void)filterAction:(UIButton *)sender image:(UIImage *)myImage{
    
    //    1.源图
    CIImage *inputImage = [CIImage imageWithCGImage:myImage.CGImage];
    //    2.滤镜
    CIFilter *filter = [CIFilter filterWithName:@"CIColorMonochrome"];
    //    NSLog(@"%@",[CIFilter filterNamesInCategory:kCICategoryColorEffect]);//注意此处两个输出语句的重要作用
    NSLog(@"%@",filter.attributes);
    
    [filter setValue:inputImage forKey:kCIInputImageKey];
    
    [filter setValue:[CIColor colorWithRed:1.000 green:0.165 blue:0.176 alpha:1.000] forKey:kCIInputColorKey];
    CIImage *outImage = filter.outputImage;
    [self addFilterLinkerWithImage:outImage image:myImage];
    
}

//再次添加滤镜  形成滤镜链
- (void)addFilterLinkerWithImage:(CIImage *)image image:(UIImage *)myImage{
    
    CIFilter *filter = [CIFilter filterWithName:@"CISepiaTone"];
    [filter setValue:image forKey:kCIInputImageKey];
//    [filter setValue:@(0.5) forKey:kCIInputIntensityKey];
    
    //    在这里创建上下文  把滤镜和图片进行合并
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef resultImage = [context createCGImage:filter.outputImage fromRect:filter.outputImage.extent];
    myImage = [UIImage imageWithCGImage:resultImage];
    
    UIImageView * sss = [[UIImageView alloc]initWithFrame:CGRectMake(20, 20, 200, 200)];
    sss.image = myImage;
    [self.view addSubview:sss];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
