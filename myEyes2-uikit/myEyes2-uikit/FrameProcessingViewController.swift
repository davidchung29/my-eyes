//
//  sendFramesVC.swift
//  myEyes2-uikit
//
//  Created by David Jr on 2/7/25.
//

import UIKit

class FrameProcessingViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        // Add a button to trigger the test
        
    }
    @IBAction func testServerPressed(_ sender: Any) {
        sendTestImage()
    }
    
    @objc private func sendTestImage() {
        // Load the image from assets
        guard let testImage = UIImage(named: "shreked.jpg") else {
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

