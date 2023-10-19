//
//
//  ContentView.swift
//
//  Created by あぷりしゃちょう@apppman
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @ObservedObject var viewModel = VoiceTranslatorViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            
            Spacer()
            
            VStack {
                // 認識されたテキストを表示
                Text(viewModel.recognizedText)
                    .font(.title)
                    .foregroundColor(.gray)
                    .padding()
                
                // 翻訳結果を表示
                Text(viewModel.translatedText)
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()
                
                Picker("Voice", selection: $viewModel.selectedVoice) {
                    ForEach(viewModel.voices, id: \.id) { voice in
                        Text(voice.voice?.name ?? "声がありません").tag(Optional(voice))
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
        
            
            
            ZStack {
                ExpandingCircleAnimationView(volume: $viewModel.currentVolume)
                
                // 音声認識の開始/停止ボタン
                Button(action: {
                    viewModel.toggleRecording()
                }) {
                    Text(viewModel.isRecording ? "録音停止" : "録音開始")
                        .font(.title2)
                        .padding(80)
                        .background(viewModel.isRecording ? Color.red : Color.blue)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }
                .padding()
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.black)
        .edgesIgnoringSafeArea(.all)
        .preferredColorScheme(.dark)
    }
}

struct ExpandingCircleAnimationView: View {
    @Binding var volume: CGFloat
    @State private var circles: [CircleInfo] = []
    
    var lineOpacity: Double = 0.3
    var lineColor: Color = .gray
    var minScale: CGFloat = 0.5
    var maxScale: CGFloat = 2.0
    
    private func addNewCircle(for volume: CGFloat) {
        let newCircle = CircleInfo(initialScale: minScale + (maxScale - minScale) * volume, currentScale: minScale)
        circles.append(newCircle)
        
        // Immediate expansion and fadeout of circle
        if let index = circles.firstIndex(where: { $0.id == newCircle.id }) {
            withAnimation(.easeOut(duration: 1)) {
                circles[index].opacity = 0.0
                circles[index].currentScale = newCircle.initialScale
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                circles.removeAll { $0.id == newCircle.id }
            }
        }
    }
    
    struct CircleInfo: Identifiable {
        let id = UUID()
        let initialScale: CGFloat
        var currentScale: CGFloat
        var opacity: Double = 1.0
    }

    var body: some View {
        ZStack {
            ForEach(circles) { circle in
                Circle()
                    .stroke(lineWidth: 2)
                    .foregroundColor(lineColor.opacity(circle.opacity * lineOpacity))
                    .scaleEffect(circle.currentScale)
            }
        }
        .onChange(of: volume) { _, newValue in
            addNewCircle(for: newValue)
        }
    }
}

#Preview {
    ContentView()
}
