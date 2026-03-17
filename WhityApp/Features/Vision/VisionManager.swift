import Foundation
import UIKit

class VisionManager {

    static let shared = VisionManager()

    func sendImageAndText(imageData: Data, text: String) {
        guard let uiImage = UIImage(data: imageData),
              let jpegData = uiImage.jpegData(compressionQuality: 0.6) else {
            return
        }

        let base64 = jpegData.base64EncodedString()

        let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""

        let url = URL(string:"https://api.openai.com/v1/chat/completions")!

        var request = URLRequest(url:url)

        request.httpMethod = "POST"

        request.setValue("application/json", forHTTPHeaderField:"Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField:"Authorization")

        let body:[String:Any] = [

            "model":"gpt-4o",

            "messages":[
                [
                    "role":"user",
                    "content":[
                        ["type":"text","text":text],
                        [
                            "type":"image_url",
                            "image_url":[
                                "url":"data:image/jpeg;base64,\(base64)"
                            ]
                        ]
                    ]
                ]
            ]
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else { return }
            if let json = try? JSONSerialization.jsonObject(with:data) as? [String:Any],
               let choices = json["choices"] as? [[String:Any]],
               let message = choices.first?["message"] as? [String:Any] {

                if let reply = message["content"] as? String {

                    DispatchQueue.main.async {
                        VoiceManager.shared.speak(reply)
                    }

                } else if let contentArray = message["content"] as? [[String:Any]],
                          let first = contentArray.first,
                          let reply = first["text"] as? String {

                    DispatchQueue.main.async {
                        VoiceManager.shared.speak(reply)
                    }
                }
            }

        }.resume()
    }
}
