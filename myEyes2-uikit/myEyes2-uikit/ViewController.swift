import UIKit
import AVFoundation

class ViewController: UIViewController {
    var session: AVCaptureSession?
    let output = AVCaptureVideoDataOutput()
    let previewLayer = AVCaptureVideoPreviewLayer()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        view.layer.addSublayer(previewLayer)
        checkCamPerm()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = view.bounds
    }

    private func checkCamPerm() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard granted else { return }
                DispatchQueue.main.async {
                    self?.setCamera()
                }
            }
        case .authorized:
            setCamera()
        default:
            break
        }
    }

    private func setCamera() {
        let session = AVCaptureSession()
        guard let device = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back){
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
            output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            if session.canAddOutput(output) {
                session.addOutput(output)
            }

            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.session = session
            session.startRunning()
            self.session = session

        } catch {
            print(error)
        }
    }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let image = UIImage(ciImage: ciImage)
        
        DispatchQueue.main.async {
            let frameVC = FrameProcessingViewController()
            frameVC.capturedFrame = image
            self.present(frameVC, animated: true)
        }
    }
}
