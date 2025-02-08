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
        while true{
            sendTestImage()
        }
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
    //@IBAction func testServerPressed(_ sender: Any) {
    //}
    
    @objc private func sendTestImage() {
        // Load the image from assets
        guard let testImage = global.image else {
            print("Image not found")
            return
        }
        
        processFrame(image: testImage)
    }

    private func processFrame(image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }

        let url = URL(string: "http://172.26.44.238:5011/detect")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = imageData
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                print("Error: No data received")
                return
            }

            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let detectedObjects = jsonResponse["detected_objects"] as? [String] {
                    print("Detected Objects: \(detectedObjects)")
                    speakWords(from: detectedObjects)
                }
            } catch {
                print("Error parsing response: \(error)")
            }
        }
        task.resume()
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
