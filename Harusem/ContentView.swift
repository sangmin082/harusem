import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("하루셈")
                .font(.largeTitle.bold())
            Text("매일 5문제, 숫자 퍼즐")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
