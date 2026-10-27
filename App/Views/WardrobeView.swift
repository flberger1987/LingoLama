import SwiftUI
import VokabelKit

/// Der Lernbegleiter mit allem, was er gerade anhat. Die Accessoires sitzen relativ zur Bildgröße auf dem Porträt.
struct CompanionView: View {
    @Environment(PlayerProgress.self) private var progress
    var size: CGFloat = 100

    var body: some View {
        Group {
            if let avatar = progress.companion {
                LernAvatarBild(avatar: avatar)
            } else {
                Text("🦙").font(.system(size: size * 0.8))
            }
        }
        .frame(width: size, height: size)
        .overlay {
            ForEach(Slot.allCases, id: \.self) { slot in
                if let item = progress.wearing(slot) {
                    Text(item.emoji)
                        .font(.system(size: size * slot.scale))
                        .offset(x: size * slot.offset.x, y: size * slot.offset.y)
                }
            }
        }
    }
}

extension Slot {
    var title: String {
        switch self {
        case .head: "Kopf"
        case .eyes: "Augen"
        case .neck: "Hals"
        case .extra: "Extras"
        }
    }

    /// Position der Mitte des Accessoires, relativ zur Bildmitte, in Vielfachen der Bildgröße.
    /// Alle Avatare sind gleich aufgebaut: Ohren oben, Augen knapp über der Mitte, Hals unten.
    fileprivate var offset: CGPoint {
        switch self {
        case .head: CGPoint(x: 0.02, y: -0.37)
        case .eyes: CGPoint(x: 0.03, y: -0.03)
        case .neck: CGPoint(x: 0, y: 0.34)
        case .extra: CGPoint(x: 0.3, y: -0.22)
        }
    }

    fileprivate var scale: CGFloat {
        switch self {
        case .head: 0.34
        case .eyes: 0.3
        case .neck: 0.32
        case .extra: 0.2
        }
    }
}

struct WardrobeView: View {
    @Environment(PlayerProgress.self) private var progress
    @Environment(\.dismiss) private var dismiss
    @State private var toBuy: Accessory?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(spacing: 12) {
                        CompanionView(size: 200)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 8)
                        Label {
                            Text("\(progress.availableStars) Sterne zum Ausgeben").bold()
                        } icon: {
                            Image(systemName: "star.fill").foregroundStyle(.yellow)
                        }
                        .contentTransition(.numericText())
                    }
                    .padding()
                    .background(Color("WoolCard"), in: RoundedRectangle(cornerRadius: 20))

                    ForEach(Slot.allCases, id: \.self) { slot in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(slot.title).font(.title3.bold())
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 12) {
                                ForEach(Wardrobe.catalog.filter { $0.slot == slot }) { item in
                                    Button { tap(item) } label: { ItemTile(item: item) }
                                        .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color("Wool"))
            .navigationTitle("Kleiderschrank")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Fertig") { dismiss() } }
            .alert("Kaufen?", isPresented: Binding(get: { toBuy != nil }, set: { if !$0 { toBuy = nil } }), presenting: toBuy) { item in
                Button("Kaufen für \(item.price) ⭐️") { withAnimation { progress.buy(item) } }
                Button("Lieber nicht", role: .cancel) {}
            } message: { item in
                Text("\(item.emoji) \(item.name) für \(progress.companion?.name ?? "dein Lama")?")
            }
            .animation(.spring(duration: 0.3), value: progress.availableStars)
        }
    }

    private func tap(_ item: Accessory) {
        switch progress.purchaseProblem(for: item) {
        case .alreadyOwned: withAnimation { progress.toggle(item) }
        case nil: toBuy = item
        case .notEnoughStars: break
        }
    }
}

private struct ItemTile: View {
    @Environment(PlayerProgress.self) private var progress
    let item: Accessory

    var body: some View {
        let problem = progress.purchaseProblem(for: item)
        let wearing = progress.isWearing(item)

        VStack(spacing: 6) {
            Text(item.emoji).font(.system(size: 44))
            Text(item.name).font(.subheadline.bold()).lineLimit(1).minimumScaleFactor(0.8)
            Group {
                switch problem {
                case .alreadyOwned: Text(wearing ? "Angezogen ✓" : "Anziehen")
                case nil: Text("\(item.price) ⭐️")
                case .notEnoughStars(let missing): Text("🔒 noch \(missing) ⭐️")
                }
            }
            .font(.caption)
            .foregroundStyle(wearing ? Color.accentColor : .secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color("WoolCard"), in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16).strokeBorder(Color.accentColor, lineWidth: wearing ? 3 : 0)
        }
        .opacity(problem.isLocked ? 0.5 : 1)
    }
}

private extension Optional where Wrapped == Wardrobe.PurchaseProblem {
    var isLocked: Bool {
        if case .notEnoughStars = self { true } else { false }
    }
}
