import SwiftUI

/// Beim ersten Start: Valerie sucht sich ihren Lernbegleiter aus. Die anderen Tiere kommen später in die Herde.
struct StarterPickerView: View {
    @Environment(PlayerProgress.self) private var progress
    @State private var picked: LernAvatar?

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Wähle deinen Lernbegleiter!").font(.largeTitle.bold()).multilineTextAlignment(.center)
                    Text("Alle \(LernAvatar.allCases.count) Tiere wohnen auf dem Schöcklblick-Hof. Eins darfst du dir jetzt aussuchen, die anderen kommen nach und nach in deine Herde.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 12) {
                        ForEach(LernAvatar.allCases) { avatar in
                            Button { withAnimation { picked = avatar } } label: {
                                VStack(spacing: 4) {
                                    LernAvatarBild(avatar: avatar).frame(height: 84)
                                    Text(avatar.name).font(.subheadline.bold()).lineLimit(1).minimumScaleFactor(0.7)
                                    Text(avatar.tierart).font(.caption).foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color("WoolCard"), in: RoundedRectangle(cornerRadius: 16))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 16)
                                        .strokeBorder(Color.accentColor, lineWidth: picked == avatar ? 3 : 0)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
            }

            if let picked {
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        LernAvatarBild(avatar: picked).frame(width: 64, height: 64)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(picked.name).font(.title3.bold())
                            Text(picked.lernrolle).font(.subheadline).foregroundStyle(.secondary)
                            Button { Speaker.shared.speak(picked.spruch) } label: {
                                Label("„\(picked.spruch)“", systemImage: "speaker.wave.2.fill").font(.subheadline.italic())
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    Button { progress.chooseStarter(picked) } label: {
                        Text("\(picked.name) wählen").font(.title3.bold()).frame(maxWidth: .infinity).padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.roundedRectangle(radius: 16))
                }
                .padding()
                .background(Color("WoolCard"))
                .transition(.move(edge: .bottom))
            }
        }
        .background(Color("Wool"))
        .interactiveDismissDisabled()
    }
}
