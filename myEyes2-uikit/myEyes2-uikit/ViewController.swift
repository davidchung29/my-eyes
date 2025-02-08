import UIKit
import AVFoundation

class ViewController: UIViewController {
    var session: AVCaptureSession?
    let output = AVCaptureVideoDataOutput()
    let previewLayer = AVCaptureVideoPreviewLayer()
    var frameProcessingQueue = DispatchQueue(label: "frameProcessingQueue")
    var shouldSendFrame = true // Control frame sending interval

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
        guard let device = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back) else { return }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            }

            output.setSampleBufferDelegate(self, queue: frameProcessingQueue)
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
        guard shouldSendFrame else { return }

        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let image = UIImage(ciImage: ciImage)
        
        shouldSendFrame = false // Throttle frame capture
        sendFrameToServer(image: image)

        // Reset frame capture after 1 second
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.shouldSendFrame = true
        }
    }

    private func sendFrameToServer(image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }

        let url = URL(string: "http://172.26.44.238:5011/detect")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = imageData
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending frame: \(error)")
                return
            }

            guard let data = data else {
                print("Error: No data received")
                return
            }

            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let detectedObjects = jsonResponse["detected_objects"] as? [String] {
                    print("Detected Objects: \(detectedObjects)")
                    self.speakWords(from: detectedObjects)
                }
            } catch {
                print("Error parsing response: \(error)")
            }
        }
        task.resume()
    }

    private func speakWords(from words: [String]) {
        for word in words {
            let utterance = AVSpeechUtterance(string: word)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            utterance.rate = 0.5
            AVSpeechSynthesizer().speak(utterance)
        }
    }
}
