import SwiftUI
import VokabelKit

/// Die Herde: alle Tiere vom Hof als Sammelkarten, noch fehlende als Schatten mit Level.
struct HerdView: View {
    @Environment(PlayerProgress.self) private var progress
    @Environment(\.dismiss) private var dismiss
    @State private var selected: LernAvatar?

    var body: some View {
        let unlocked = progress.unlockedHerd
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("\(unlocked.count) of \(progress.herd.count) animals collected")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 12)], spacing: 12) {
                        ForEach(progress.herd) { avatar in
                            if unlocked.contains(avatar) {
                                Button { selected = avatar } label: {
                                    AvatarTile(avatar: avatar, isCompanion: progress.companion == avatar)
                                }
                                .buttonStyle(.plain)
                            } else {
                                LockedTile(avatar: avatar, level: progress.unlockLevel(of: avatar))
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color("Wool"))
            .navigationTitle("Your herd")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Done") { dismiss() } }
            .sheet(item: $selected) { AvatarCard(avatar: $0) }
        }
    }
}

private struct AvatarTile: View {
    let avatar: LernAvatar
    let isCompanion: Bool

    var body: some View {
        VStack(spacing: 4) {
            LernAvatarBild(avatar: avatar).frame(height: 88)
            Text(avatar.name).font(.subheadline.bold()).lineLimit(1).minimumScaleFactor(0.7)
            Text(isCompanion ? "Buddy ✓" : avatar.species)
                .font(.caption)
                .foregroundStyle(isCompanion ? Color.accentColor : .secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color("WoolCard"), in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16).strokeBorder(Color.accentColor, lineWidth: isCompanion ? 3 : 0)
        }
    }
}

/// Noch nicht in der Herde: nur der Umriss, damit man sich schon freuen kann.
private struct LockedTile: View {
    let avatar: LernAvatar
    let level: Int

    var body: some View {
        VStack(spacing: 4) {
            Image(avatar.assetName)
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .foregroundStyle(.primary.opacity(0.12))
                .frame(height: 88)
                .accessibilityHidden(true)
            Text("???").font(.subheadline.bold()).foregroundStyle(.secondary)
            Label("level \(level)", systemImage: "lock.fill").font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color("WoolCard").opacity(0.5), in: RoundedRectangle(cornerRadius: 16))
    }
}

/// Die große Sammelkarte mit Lernrolle und englischem Spruch zum Vorlesen.
struct AvatarCard: View {
    let avatar: LernAvatar
    @Environment(PlayerProgress.self) private var progress
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 14) {
            LernAvatarBild(avatar: avatar).frame(height: 220)
            Text(avatar.name).font(.largeTitle.bold())
            Text("\(avatar.species) · \(avatar.role)")
                .font(.headline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                Text("“\(avatar.spruch)”").font(.title3.italic())
                Button { Speaker.shared.speak(avatar.spruch) } label: {
                    Image(systemName: "speaker.wave.2.circle.fill").font(.title)
                }
                .accessibilityLabel("Read aloud")
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color("Wool"), in: RoundedRectangle(cornerRadius: 16))

            Spacer()
            if progress.companion == avatar {
                Label("Your learning buddy", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.tint)
            } else if progress.unlockedHerd.contains(avatar) {
                Button("Make \(avatar.name) your buddy") {
                    progress.chooseCompanion(avatar)
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            Button("Close") { dismiss() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .padding(24)
        .background(Color("WoolCard"))
    }
}

/// Schnell den Lernbegleiter wechseln, unter allen Tieren, die schon in der Herde sind.
struct BuddySwitcherView: View {
    @Environment(PlayerProgress.self) private var progress
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Who do you want to learn with today?")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 12)], spacing: 12) {
                        ForEach(progress.unlockedHerd) { avatar in
                            Button {
                                progress.chooseCompanion(avatar)
                                Speaker.shared.speak(avatar.spruch)
                                dismiss()
                            } label: {
                                AvatarTile(avatar: avatar, isCompanion: progress.companion == avatar)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    if progress.unlockedHerd.count < progress.herd.count {
                        Text("Reach the next level to bring more friends into your herd.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()
            }
            .background(Color("Wool"))
            .navigationTitle("Change buddy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Done") { dismiss() } }
        }
    }
}
