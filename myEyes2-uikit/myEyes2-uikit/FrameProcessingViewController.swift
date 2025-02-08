import UIKit
import AVFoundation

class FrameProcessingViewController: UIViewController {
    var capturedFrame: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        if let frame = capturedFrame {
            processFrame(image: frame)
        }
    }

    private func processFrame(image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }

        let url = URL(string: "http://172.26.68.228:5058/detect")!//change this to be server url + /detect
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
