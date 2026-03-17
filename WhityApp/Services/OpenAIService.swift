import Foundation
import UIKit

class OpenAIService {

    static let shared = OpenAIService()
    
    var messages:[[String:Any]] = [
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

    func send(
        text: String,
        image: String? = nil,
        completion: @escaping (String) -> Void
    ) {

        let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""

        let url = URL(string: "https://api.openai.com/v1/chat/completions")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        var content: Any = text
        
        if let image = image {
            content = [
                    ["type":"text","text":text],
                    [
                        "type":"image_url",
                        "image_url":[
                            "url":"data:image/jpeg;base64,\(image)"
                        ]
                    ]
                ]
        }
        
        self.messages.append([
            "role":"user",
            "content": content
        ])

        let body:[String:Any] = [
            "model":"gpt-4o",
            "messages":self.messages
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, _, _ in

            guard let data = data else { return }

            if let json = try? JSONSerialization.jsonObject(with:data) as? [String:Any],
               let choices = json["choices"] as? [[String:Any]],
               let message = choices.first?["message"] as? [String:Any] {

                if let reply = message["content"] as? String {
                    self.messages.append(["role":"assistant","content":reply])
                    completion(reply)

                } else if let contentArray = message["content"] as? [[String:Any]],
                          let first = contentArray.first,
                          let reply = first["text"] as? String {
                    self.messages.append(["role":"assistant","content":reply])
                    completion(reply)
                }
            }

        }.resume()
    }
}
