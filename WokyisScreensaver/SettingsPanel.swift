import SwiftUI

struct SettingsPanel: View {
    @Bindable var settings: Settings

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Settings")
                .font(.headline)
            Text("H hide   F fullscreen   Esc quit")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Divider()
            LabeledSlider(title: "Scale",        value: $settings.scale,          range: 0.5...10.0)
            LabeledSlider(title: "Line count",   value: $settings.lineCount,      range: 1.0...20.0, format: "%.1f")
            LabeledSlider(title: "Speed",        value: $settings.speed,          range: 0.0...1.0,  format: "%.3f")
            LabeledSlider(title: "Thickness",    value: $settings.thickness,      range: 0.0...5.0)
            LabeledSlider(title: "Softness",     value: $settings.softness,       range: 0.0...5.0)
            LabeledSlider(title: "Halo",         value: $settings.halo,           range: 0.0...10.0)
            LabeledSlider(title: "Halo bright",  value: $settings.haloBrightness, range: 0.0...1.0)
        }
        .padding(16)
        .frame(width: 280)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct LabeledSlider: View {
    let title: String
    @Binding var value: Float
    let range: ClosedRange<Float>
    var format: String = "%.2f"

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(title)
                    .font(.caption)
                Spacer()
                Text(String(format: format, value))
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range)
        }
    }
}
