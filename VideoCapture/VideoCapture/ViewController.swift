//
//  ViewController.swift
//  VideoCapture
//
//  Created by lcs-developer on 2018/05/05.
//  Copyright © 2018年 takapika. All rights reserved.
//

import UIKit
import AVFoundation // add

class ViewController: UIViewController {

    @IBOutlet weak var screen: UIImageView!
    var captureSession = AVCaptureSession()

    // front camera
    lazy var frontCameraDevice: AVCaptureDevice? = {

        let videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes:
            [.builtInWideAngleCamera, .builtInDualCamera], mediaType: .video, position: .front)
        
        let devices = videoDeviceDiscoverySession.devices
        return devices.filter{$0.position == .front}.first
    }()
    
    // output
    var movieOutput = AVCaptureVideoDataOutput()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // セッションの設定開始
        captureSession.beginConfiguration()

        // 解像度の設定
        captureSession.sessionPreset = AVCaptureSession.Preset.medium
        
        // Inputの設定
        // FPSを設定
        do {
            try frontCameraDevice?.lockForConfiguration()
        } catch {
            // handle error
             print("lock error: \(error.localizedDescription)")
            return
        }
        frontCameraDevice?.activeVideoMinFrameDuration = CMTimeMake(1, 15)
        frontCameraDevice?.unlockForConfiguration()

        // セッションに追加
        captureSession.addInput(deviceInputFromDevice(device: frontCameraDevice)!)

        
        // Outputの設定
        movieOutput.videoSettings = [ kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA ] as [String : Any]

        // デリゲートを設定
        let queue = DispatchQueue(label: "com.taka2488.app.queue1")
        movieOutput.setSampleBufferDelegate(self, queue: queue)
        
        // 遅れてきたフレームは無視する
        movieOutput.alwaysDiscardsLateVideoFrames = true
        
        // セッションに追加
        if captureSession.canAddOutput(movieOutput) {
            captureSession.addOutput(movieOutput)
        } else {
            return
        }
        
        // カメラの向きを合わせる
        for connection in movieOutput.connections {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = AVCaptureVideoOrientation.portrait
            }
        }
        // 設定変更のコミット
        captureSession.commitConfiguration()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // deviceからinput deviceを作成
    private func deviceInputFromDevice(device: AVCaptureDevice?) -> AVCaptureDeviceInput? {
        guard let validDevice = device else { return nil }
        do {
            return try AVCaptureDeviceInput(device: validDevice)
        } catch let outError {
            print("Device setup error occured \(outError)")
            return nil
        }
    }
    
    @IBAction func scanStartAction(_ sender: Any) {
        
        captureSession.startRunning()
        
    }
    

    // sampleBufferからUIImageへ変換
    func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> UIImage {
        // Get a CMSampleBuffer's Core Video image buffer for the media data
        let  imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        // Lock the base address of the pixel buffer
        CVPixelBufferLockBaseAddress(imageBuffer!, CVPixelBufferLockFlags.readOnly);
        
        
        // Get the number of bytes per row for the pixel buffer
        let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer!);
        
        // Get the number of bytes per row for the pixel buffer
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer!);
        // Get the pixel buffer width and height
        let width = CVPixelBufferGetWidth(imageBuffer!);
        let height = CVPixelBufferGetHeight(imageBuffer!);
        
        // Create a device-dependent RGB color space
        let colorSpace = CGColorSpaceCreateDeviceRGB();
        
        // Create a bitmap graphics context with the sample buffer data
        var bitmapInfo: UInt32 = CGBitmapInfo.byteOrder32Little.rawValue
        bitmapInfo |= CGImageAlphaInfo.premultipliedFirst.rawValue & CGBitmapInfo.alphaInfoMask.rawValue
        //let bitmapInfo: UInt32 = CGBitmapInfo.alphaInfoMask.rawValue
        let context = CGContext.init(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo)
        // Create a Quartz image from the pixel data in the bitmap graphics context
        let quartzImage = context?.makeImage();
        // Unlock the pixel buffer
        CVPixelBufferUnlockBaseAddress(imageBuffer!, CVPixelBufferLockFlags.readOnly);
        
        // Create an image object from the Quartz image
        let image = UIImage.init(cgImage: quartzImage!);
        
        return (image);
    }
    

}




// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension ViewController:AVCaptureVideoDataOutputSampleBufferDelegate {
    
    // 毎フレーム実行される処理
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        DispatchQueue.main.async {
            self.screen.image = self.imageFromSampleBuffer(sampleBuffer: sampleBuffer)
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // do something
    }
    
}
