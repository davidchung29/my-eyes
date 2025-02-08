import UIKit
import ARKit
import AudioToolbox
import AVFoundation

class ViewController: UIViewController {
    var sceneView: ARSCNView!
    var isProcessingDepth = false
    var alarmIsPlaying = false            // Flag to prevent repeated alarms
    var lastFrameSent: TimeInterval = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupARSceneView()
        setupARSession()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        sceneView.frame = view.bounds
    }
    
    private func setupARSceneView() {
        sceneView = ARSCNView(frame: view.bounds)
        view.addSubview(sceneView)
        sceneView.delegate = self
        sceneView.session.delegate = self
    }
    
    private func setupARSession() {
        let configuration = ARWorldTrackingConfiguration()
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            configuration.frameSemantics = .sceneDepth
        }
        sceneView.session.run(configuration)
    }
    
    private func imageFromPixelBuffer(_ pixelBuffer: CVPixelBuffer) -> UIImage {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        return UIImage(ciImage: ciImage)
    }
    
    private func sendFrameToServer(image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        let url = URL(string: "http://172.26.68.228:5058/detect")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = imageData
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        URLSession.shared.dataTask(with: request) { data, response, error in
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
        }.resume()
    }
    
    private func speakWords(from words: [String]) {
        for word in words {
            let utterance = AVSpeechUtterance(string: word)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            utterance.rate = 0.6
            AVSpeechSynthesizer().speak(utterance)
        }
    }
    
    func triggerAlarm() {
        if !alarmIsPlaying {
            alarmIsPlaying = true
            AudioServicesPlaySystemSound(1005)
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.alarmIsPlaying = false
            }
        }
    }
}

extension ViewController: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Process LiDAR depth data without blocking the main thread.
        // If a previous processing is in progress, skip this frame.
        if isProcessingDepth { return }
        isProcessingDepth = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            defer { self.isProcessingDepth = false }
            
            // Ensure we have scene depth data.
            guard let sceneDepth = frame.sceneDepth else { return }
            let depthMap = sceneDepth.depthMap
            
            // Lock the pixel buffer for safe reading.
            CVPixelBufferLockBaseAddress(depthMap, .readOnly)
            let width = CVPixelBufferGetWidth(depthMap)
            let height = CVPixelBufferGetHeight(depthMap)
            guard let baseAddress = CVPixelBufferGetBaseAddress(depthMap) else {
                CVPixelBufferUnlockBaseAddress(depthMap, .readOnly)
                return
            }
            let floatBuffer = baseAddress.assumingMemoryBound(to: Float32.self)
            let threshold: Float = 0.91  // Approximately 2 feet in meters.
            
            let startX = width / 2 - width / 8
            let endX   = width / 2 + width / 8
            let startY = height / 2 - height / 8
            let endY   = height / 2 + height / 8
            let step = 5
            var objectTooClose = false
            
            for y in stride(from: startY, to: endY, by: step) {
                for x in stride(from: startX, to: endX, by: step) {
                    let index = y * width + x
                    let distance = floatBuffer[index]
                    if distance > 0 && distance < threshold {
                        objectTooClose = true
                        break
                    }
                }
                if objectTooClose { break }
            }
            CVPixelBufferUnlockBaseAddress(depthMap, .readOnly)
            
            if objectTooClose {
                DispatchQueue.main.async {
                    self.triggerAlarm()
                }
            }
        }
    }
}

extension ViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // Throttle frame sending—here, one frame per second.
        if time - lastFrameSent > 1.0,
           let currentFrame = sceneView.session.currentFrame {
            lastFrameSent = time
            let pixelBuffer = currentFrame.capturedImage
            let image = imageFromPixelBuffer(pixelBuffer)
            sendFrameToServer(image: image)
        }
    }
}
