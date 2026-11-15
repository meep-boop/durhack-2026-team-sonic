import SwiftUI

/// On a refit step: the photo the screws were found in, with each hole numbered, and a line for any screw that was
/// different (say, longer), so every screw goes back where it came from.
struct ScrewMapCard: View {
  let memory: ScrewMemory
  @State private var expanded = false

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Button {
        withAnimation(.snappy) { expanded.toggle() }
      } label: {
        HStack {
          Label("Screw map · \(memory.entries.count) screws", systemImage: "map.fill").font(.subheadline.weight(.semibold))
          Spacer()
          Image(systemName: expanded ? "chevron.up" : "chevron.down").font(.footnote)
        }
      }
      .buttonStyle(.plain)

      if expanded {
        if let photo = memory.photo {
          Image(uiImage: photo)
            .resizable()
            .scaledToFit()
            .overlay {
              GeometryReader { proxy in
                ForEach(memory.entries) { entry in
                  if let point = entry.photoPoint {
                    Text("\(entry.number)")
                      .font(.caption2.weight(.heavy))
                      .foregroundStyle(.black)
                      .frame(width: 20, height: 20)
                      .background(entry.note == nil ? Color.yellow : Color.orange, in: Circle())
                      .position(x: point.x * proxy.size.width, y: point.y * proxy.size.height)
                  }
                }
              }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .frame(maxHeight: 220)
            .accessibilityLabel("Photo of the panel with each screw hole numbered")
        }
        ForEach(memory.entries.filter { $0.note != nil }) { entry in
          Label("Screw \(entry.number) was different (\(entry.note ?? "")): it goes back in hole \(entry.number)", systemImage: "exclamationmark.triangle.fill")
            .font(.footnote)
            .foregroundStyle(.orange)
        }
        Text("Last out, first in: the pins count down from \(memory.entries.last?.number ?? 0).")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
    }
    .padding(14)
    .glassBackground(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
  }
}
