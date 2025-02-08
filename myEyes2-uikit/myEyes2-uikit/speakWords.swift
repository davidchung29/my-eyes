//
//  speakWords.swift
//  myEyes2-uikit
//
//  Created by David Jr on 2/7/25.
//

import AVFoundation
let speechSynthesizer = AVSpeechSynthesizer()

func speakWords(from words: [String]) {
    for word in words {
        let utterance = AVSpeechUtterance(string: word)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.65  // Adjust this value for speech speed
        speechSynthesizer.speak(utterance)
    }
}
