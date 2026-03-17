import SwiftUI

struct ContentView: View {

    @StateObject var voice = VoiceManager()

    var body: some View {
        VStack(spacing:40){

            Button("Start Listening"){
                voice.startListening()
            }

            Button("Stop"){
                voice.stopListening()
            }

            Text(voice.transcript)
                .padding()

        }
        .padding()
    }
}
