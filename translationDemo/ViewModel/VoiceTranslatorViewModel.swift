//
//
//  VoiceTranslatorViewModel.swift
//
//  Created by あぷりしゃちょう@apppman
//

import SwiftUI
import Combine

class VoiceTranslatorViewModel: ObservableObject {
      
    // プロパティ
    @Published var isRecording: Bool = false
    @Published var recognizedText: String = ""
    @Published var translatedText: String = ""
    
    private let voiceRecorder = VoiceRecorder()
    private let whisperAPIEndpoint = "https://api.openai.com/v1/audio/transcriptions"
    
    @Published var selectedVoice: VoiceModel?
    @Published var voices: [VoiceModel] = []
    
    @Published var currentVolume: CGFloat = 0.0
    private var volumeUpdateTimer: Timer?
    
    private var cancellables: Set<AnyCancellable> = []
    
    init() {
    
        voiceRecorder.$voices.map { voices in
            voices.map { voice in
                VoiceModel(voice: voice)
            }
        }
        .assign(to: \.voices, on: self)
        .store(in: &cancellables)
        
        $voices.map { models in
            models.first
        }
        .assign(to: \.selectedVoice, on: self)
        .store(in: &cancellables)
    }

    // 音声認識の開始/停止
    func toggleRecording() {
        isRecording.toggle()
        
        if isRecording {
            // 音声録音の開始
            startRecording()
        } else {
            // 音声録音の停止
            stopRecording()
        }
    }
    
    private func startRecording() {
        // ここで音声の録音を開始し、Whisper APIに送信するロジックを実装します。
        // 音声が認識されたら、recognizedTextを更新します。
        // その後、translateText()を呼び出してテキストを翻訳します。
        if let _ = voiceRecorder.startRecording() {
            // 録音が開始されました
            volumeUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                self?.updateVolume()
            }

        }
    }
    
    private func stopRecording() {
        // ここで音声の録音を停止します。
        volumeUpdateTimer?.invalidate()
        volumeUpdateTimer = nil
        currentVolume = 0.0
        
        voiceRecorder.stopRecording()
        if let url = voiceRecorder.recordingURL {
            sendAudioToAPI(audioURL: url)
        }
        
    }
    
    private func updateVolume() {
        voiceRecorder.audioRecorder?.updateMeters()
        let power = voiceRecorder.audioRecorder?.averagePower(forChannel: 0) ?? -160.0
        // dBスケールの値を0〜1の範囲に正規化
        currentVolume = CGFloat(max(0, 1 + power / 160))
    }
    
    private func translateText(_ text: String) {
        let apiUrl = "https://api-free.deepl.com/v2/translate"
        
        // リクエスト用のURLを作成
        var request = URLRequest(url: URL(string: apiUrl)!)
        request.httpMethod = "POST"
        
        // リクエストヘッダにAPIキーを設定
        request.setValue("DeepL-Auth-Key \(Constants.deeplApiKey)", forHTTPHeaderField: "Authorization")
        //print(text)
        // リクエストボディにテキストとターゲット言語を設定
        let bodyParameters = [
            "text": text,
            "target_lang": "EN"
        ]
        let bodyData = bodyParameters.map { key, value in
            return "\(key)=\(value)"
        }.joined(separator: "&").data(using: .utf8)
        
        request.httpBody = bodyData
        
        // URLSessionを使用してAPIリクエストを送信
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Error: \(error)")
                return
            }
            
            if let data = data {
                if let translation = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    print(translation)
                    if let translatedText = translation["translations"] as? [[String: String]] {
                        
                        if let firstTranslation = translatedText.first?["text"] {
                            DispatchQueue.main.async {
                                self.translatedText = firstTranslation
                                if let voice = self.selectedVoice?.voice {
                                    self.voiceRecorder.speakText(text: firstTranslation, voice: voice)
                                }
                            }
                        }
                    }
                }
            }
        }
        
        task.resume()
    }
    
    private func sendAudioToAPI(audioURL: URL) {
        var request = URLRequest(url: URL(string: whisperAPIEndpoint)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(Constants.whisperApiKey)", forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let modelName = "whisper-1"
        let audioData = try? Data(contentsOf: audioURL)
        
        let httpBody = createBody(with: audioData, boundary: boundary, modelName: modelName)
        request.httpBody = httpBody

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                if let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let text = jsonResponse["text"] as? String {
                    DispatchQueue.main.async {
                        self.recognizedText = text
                    }
                    self.translateText(text)
                }
            }
        }.resume()
    }

    private func createBody(with data: Data?, boundary: String, modelName: String) -> Data {
        var body = Data()

        // モデル名の追加
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n")
        body.append("\(modelName)\r\n")

        // 音声データの追加
        if let data = data {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n")
            body.append("Content-Type: audio/m4a\r\n\r\n")
            body.append(data)
            body.append("\r\n")
        }

        body.append("--\(boundary)--\r\n")
        return body
    }
    

}
