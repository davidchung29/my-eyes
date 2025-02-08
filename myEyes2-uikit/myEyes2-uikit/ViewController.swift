import UIKit
import ARKit
import AudioToolbox
import AVFoundation

class ViewController: UIViewController {
    var sceneView: ARSCNView!
    var isProcessingDepth = false
    var alarmIsPlaying = false            // Flag to prevent repeated alarms
    var lastFrameSent: TimeInterval = 0
    var lastCameraPosition: SIMD3<Float>? // Track last camera position
    let movementThreshold: Float = 0.05   // Movement threshold in meters (e.g., 0.05 m = 5 cm)
    
    // Create a single, persistent AVSpeechSynthesizer.
    let speechSynthesizer = AVSpeechSynthesizer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupARSceneView()
        setupARSession()
        let eyelidView = UIView(frame: self.view.bounds)
        eyelidView.backgroundColor = .black
        self.view.addSubview(eyelidView)
        
        // Animate the opening of the "eye"
        UIView.animate(withDuration: 3.0, animations: {
            eyelidView.alpha = 0 // Fade the eyelid view to reveal the screen
        }) { _ in
            // Remove the eyelid view once the animation completes
            eyelidView.removeFromSuperview()
        }
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
        let url = URL(string: "http://172.20.10.5:5058/detect")!
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
        DispatchQueue.main.async {
            // Optionally, if you want to avoid overlapping speech, you could check if the synthesizer is speaking:
            // if self.speechSynthesizer.isSpeaking { return }
            for word in words {
                let utterance = AVSpeechUtterance(string: word)
                utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                utterance.rate = 0.65
                self.speechSynthesizer.speak(utterance)
            }
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
            let threshold: Float = 0.75 // 2.5 feetish
            
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
        // Only send frames when the device is moving.
        guard let currentFrame = sceneView.session.currentFrame else { return }
        
        // Extract the current camera position from its transform.
        let transform = currentFrame.camera.transform
        let currentPosition = SIMD3<Float>(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
        
        if let lastPos = lastCameraPosition {
            let distance = simd_distance(lastPos, currentPosition)
            // Only send a frame if the device has moved more than the threshold
            // and at least 1 second has passed since the last frame was sent.
            if distance > movementThreshold && (time - lastFrameSent > 1.0) {
                lastFrameSent = time
                lastCameraPosition = currentPosition
                let pixelBuffer = currentFrame.capturedImage
                let image = imageFromPixelBuffer(pixelBuffer)
                sendFrameToServer(image: image)
            }
        } else {
            // For the first frame, record the position and send a frame if throttling allows.
            lastCameraPosition = currentPosition
            if time - lastFrameSent > 1.0 {
                lastFrameSent = time
                let pixelBuffer = currentFrame.capturedImage
                let image = imageFromPixelBuffer(pixelBuffer)
                sendFrameToServer(image: image)
            }
        }
    }
}
