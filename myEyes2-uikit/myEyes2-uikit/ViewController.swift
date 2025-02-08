//
//  ViewController.swift
//  myEyes2-uikit
//
//  Created by David Jr on 2/7/25.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    var session: AVCaptureSession?
    let output = AVCapturePhotoOutput()
    let previewLayer = AVCaptureVideoPreviewLayer()
    override func viewDidLoad(){
        super.viewDidLoad()
        view.backgroundColor = .black
        view.layer.addSublayer(previewLayer)
        // Do any additional setup after loading the view.
        checkCamPerm()
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = view.bounds
    }
    private func checkCamPerm()
    {
        switch AVCaptureDevice.authorizationStatus(for: .video){
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video){ [weak self] granted in
                guard granted else{
                    return
                }
                DispatchQueue.main.async{
                    self?.setCamera()
                }
            }
        case .restricted:
            break
        case .denied:
            break
        case .authorized:
            setCamera()
        @unknown default:
            break
        }
    }
    private func setCamera(){
        let session = AVCaptureSession()
        if let device = AVCaptureDevice.default(for: .video){
            do{
                let input = try AVCaptureDeviceInput(device: device)
                if session.canAddInput(input){
                    session.addInput(input)
                }
                if session.canAddOutput(output){
                    session.addOutput(output)
                }
                previewLayer.videoGravity = .resizeAspectFill
                previewLayer.session = session
                session.startRunning()
                self.session = session
            }
            catch{
                print(error)
            }
        }
    }
}

extension ViewController: AVCapturePhotoCaptureDelegate{
    func photoOutput(output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?){
        guard let data = photo.fileDataRepresentation() else{
            return
        }
        let image = UIImage(data: data)
        global.image = UIImage(data: data)
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.frame = view.bounds
        view.addSubview(imageView)
    }
}
