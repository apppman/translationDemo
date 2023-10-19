//
//
//  VoiceModel.swift
//
//  Created by あぷりしゃちょう@apppman
//

import Foundation
import AVFoundation

class VoiceModel: Identifiable, Hashable {
    
    static func == (lhs: VoiceModel, rhs: VoiceModel) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    var id = UUID()
    var voice: AVSpeechSynthesisVoice?

    init(voice: AVSpeechSynthesisVoice?) {
        self.voice = voice
    }
    
}

