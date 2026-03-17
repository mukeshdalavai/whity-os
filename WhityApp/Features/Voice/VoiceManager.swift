import Foundation
import Speech
import AVFoundation
import Combine

class VoiceManager: NSObject, ObservableObject {

    static let shared = VoiceManager()
    @Published var transcript = ""

    private let audioEngine = AVAudioEngine()
    private let recognizer = SFSpeechRecognizer()

    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    let synthesizer = AVSpeechSynthesizer()

    func startListening() {

        let audioSession = AVAudioSession.sharedInstance()

        try? audioSession.setCategory(
            .playAndRecord,
            mode: .voiceChat,
            options: [.allowBluetoothHFP, .allowBluetoothA2DP]
        )
        try? audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        try? audioSession.overrideOutputAudioPort(.none)

        request = SFSpeechAudioBufferRecognitionRequest()

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.inputFormat(forBus: 0)

        inputNode.removeTap(onBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) {
            (buffer, _) in
            self.request?.append(buffer)
        }

        audioEngine.prepare()
        try? audioEngine.start()

        task = recognizer?.recognitionTask(with: request!) { result, error in

            if let result = result {

                DispatchQueue.main.async {
                    self.transcript = result.bestTranscription.formattedString
                }

                if result.isFinal {
                    
                    self.sendToAI(text: self.transcript)

                }
            }
        }
    }

    func stopListening(){
        audioEngine.stop()
        request?.endAudio()
    }

    func sendToAI(text: String) {
        self.transcript = ""
        var text_lower = text.lowercased()
        if text_lower.contains("what do you see") ||
            text_lower.contains("analyze scene") ||
            text_lower.contains("look at this") {
            
            self.analyzeScene(text: text)
            
        } else {
            OpenAIService.shared.send(
                text: text,
            ) { reply in

                DispatchQueue.main.async {
                    self.speak(reply)
                }
            }
        }
    }
    
    
    func analyzeScene(text: String) {
        guard !text.isEmpty else { return }

        PhotoManager.fetchLatestMetaPhoto { imageData in

            guard let imageData = imageData else {
                return
            }

            VisionManager.shared.analyze(
                imageData: imageData,
                text: text
            )

        }

    }

    func speak(_ text:String){

        DispatchQueue.main.async {
            print(AVSpeechSynthesisVoice.speechVoices())
            let utterance = AVSpeechUtterance(string: text)

            if let voice = AVSpeechSynthesisVoice(identifier: "com.apple.voice.super-compact.en-US.Samantha") {
                utterance.voice = voice
            } else {
                utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            }

            utterance.rate = 0.5

            self.synthesizer.stopSpeaking(at: .immediate)
            self.synthesizer.speak(utterance)
        }
    }
}
