import SwiftUI

enum Palette {
    static let background = Color(red: 0.961, green: 0.929, blue: 0.867)
    static let terracotta = Color(red: 0.714, green: 0.365, blue: 0.263)
    static let forest = Color(red: 0.235, green: 0.322, blue: 0.251)
    static let surface = Color(red: 0.990, green: 0.974, blue: 0.940)
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundStyle(.white)
            .background(Palette.terracotta, in: RoundedRectangle(cornerRadius: 16))
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}
