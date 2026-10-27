import SwiftUI
import VokabelKit

/// Lingos Herde: alle Tiere als Sammelkarten, noch gesperrte als Rätsel mit Level.
struct HerdView: View {
    @Environment(PlayerProgress.self) private var progress
    @Environment(\.dismiss) private var dismiss
    @State private var selected: Animal?

    private var unlockedCount: Int { Herd.unlocked(atLevel: progress.level).count }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("\(unlockedCount) von \(Herd.animals.count) Tieren gesammelt")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                        ForEach(Herd.animals) { animal in
                            if animal.unlockLevel <= progress.level {
                                Button { selected = animal } label: { AnimalTile(animal: animal) }
                                    .buttonStyle(.plain)
                            } else {
                                LockedTile(level: animal.unlockLevel)
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color("Wool"))
            .navigationTitle("Lingos Herde")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Fertig") { dismiss() } }
            .sheet(item: $selected) { AnimalCard(animal: $0) }
        }
    }
}

private struct AnimalTile: View {
    let animal: Animal

    var body: some View {
        VStack(spacing: 6) {
            Text(animal.emoji).font(.system(size: 56))
            Text(animal.name).font(.subheadline.bold()).multilineTextAlignment(.center)
            Text(animal.englishName).font(.caption).italic().foregroundStyle(Color.accentColor)
        }
        .frame(maxWidth: .infinity, minHeight: 140)
        .padding(.vertical, 8)
        .background(Color("WoolCard"), in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct LockedTile: View {
    let level: Int

    var body: some View {
        VStack(spacing: 6) {
            Text("❓").font(.system(size: 44)).opacity(0.4)
            Label("ab Level \(level)", systemImage: "lock.fill").font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 140)
        .padding(.vertical, 8)
        .background(Color("WoolCard").opacity(0.5), in: RoundedRectangle(cornerRadius: 16))
    }
}

/// Die große Sammelkarte mit Fun Fact zum Vorlesen.
struct AnimalCard: View {
    let animal: Animal
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text(animal.emoji).font(.system(size: 110))
            Text(animal.name).font(.largeTitle.bold()).multilineTextAlignment(.center)
            Button { Speaker.shared.speak(animal.englishName) } label: {
                Label(animal.englishName, systemImage: "speaker.wave.2.fill").font(.title3.italic())
            }

            VStack(alignment: .leading, spacing: 10) {
                Label("Fun Fact", systemImage: "sparkles").font(.headline).foregroundStyle(Color.accentColor)
                Text(animal.funFact).font(.title3)
                Button("Vorlesen", systemImage: "speaker.wave.2.fill") { Speaker.shared.speak(animal.funFact) }
                    .buttonStyle(.bordered)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color("Wool"), in: RoundedRectangle(cornerRadius: 16))

            Spacer()
            Button("Schließen") { dismiss() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .padding(24)
        .background(Color("WoolCard"))
        .presentationDetents([.large])
    }
}
