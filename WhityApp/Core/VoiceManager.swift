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
    
    var messages:[[String:String]] = [
        ["role":"system",
         "content":
            """
            You are Whity, Mukesh's AI thinking partner.

            Mukesh is an engineer building a wearable AI system called Whity OS.
            He wants to build impactful systems for India including healthcare and decentralization.

            Be concise.
            Challenge ideas when needed.
            Act like a thinking partner.
            """]
    ]

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

                    let text = self.transcript.lowercased()

                    if text.contains("what do you see") ||
                       text.contains("analyze scene") ||
                       text.contains("look at this") {

                        self.analyzeScene(text: self.transcript)

                    } else {

                        self.sendToAI(text: self.transcript)

                    }
                }
            }
        }
    }

    func stopListening(){
        audioEngine.stop()
        request?.endAudio()
    }

    func sendToAI(text:String){
        self.transcript = ""

        let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
        let url = URL(string:"https://api.openai.com/v1/chat/completions")!

        var request = URLRequest(url:url)

        request.httpMethod = "POST"

        request.setValue("application/json", forHTTPHeaderField:"Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField:"Authorization")
        
        messages.append(["role":"user","content":text])

        let body:[String:Any] = [
            "model":"gpt-4o",
            "messages":messages
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request){ data, response, error in

            guard let data = data else { return }
            
            if let json = try? JSONSerialization.jsonObject(with:data) as? [String:Any],
               let choices = json["choices"] as? [[String:Any]],
               let message = choices.first?["message"] as? [String:Any],
               let reply = message["content"] as? String {

                DispatchQueue.main.async {
                    self.messages.append(["role":"assistant","content":reply])
                    self.speak(reply)
                }

            }

        }.resume()
    }
    
    
    func analyzeScene(text: String) {
        guard !text.isEmpty else { return }

        PhotoManager.fetchLatestMetaPhoto { imageData in

            guard let imageData = imageData else {
                return
            }

            VisionManager.shared.sendImageAndText(
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
