import Foundation
import UIKit

class VisionManager {

    static let shared = VisionManager()

    func analyze(imageData: Data, text: String) {
        
        guard let uiImage = UIImage(data: imageData),
              let jpeg = uiImage.jpegData(compressionQuality: 0.6) else {
            return
        }

        let base64 = jpeg.base64EncodedString()

        OpenAIService.shared.send(
            text: text,
            image: base64
        ) { reply in

            DispatchQueue.main.async {

                VoiceManager.shared.speak(reply)

            }
        }
    }
}
