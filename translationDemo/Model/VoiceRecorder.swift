//
//
//  VoiceRecorder.swift
//
//  Created by あぷりしゃちょう@apppman
//

import Foundation
import AVFoundation

class VoiceRecorder: NSObject, AVAudioRecorderDelegate, ObservableObject {
    var audioRecorder: AVAudioRecorder?
    var recordingURL: URL?

    private let speechSynthesizer = AVSpeechSynthesizer()
    
    @Published var voices = AVSpeechSynthesisVoice.speechVoices().filter { $0.language == "en-US" }
    
    override init() {
        super.init()
        AVSpeechSynthesizer.requestPersonalVoiceAuthorization { [weak self] status in
            if let personalVoice = AVSpeechSynthesisVoice.speechVoices().filter({ $0.voiceTraits.contains(.isPersonalVoice) }).first {
                if self?.voices.contains(personalVoice) == false {
                    self?.voices.append(personalVoice)
                }
            }
        }
    }
    
    func startRecording() -> URL? {
    
        // AVAudioSessionの設定
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
            return nil
        }

        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            recordingURL = audioFilename
        } catch {
            print("Failed to start recording.")
            return nil
        }

        return recordingURL
    }

    func stopRecording() {
        audioRecorder?.stop()
    }

    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func speakText(text: String, voice: AVSpeechSynthesisVoice) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session category: \(error)")
        }
        
        let speechUtterance = AVSpeechUtterance(string: text)
        
        speechUtterance.voice = voice
        speechUtterance.rate = 0.5
        speechUtterance.volume = 1.0
       
        speechSynthesizer.speak(speechUtterance)
    }
}
