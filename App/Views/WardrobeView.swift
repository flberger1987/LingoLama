import SwiftUI
import VokabelKit

/// Der Lernbegleiter mit allem, was er gerade anhat. Die Accessoires sitzen relativ zur Bildgröße auf dem Porträt.
struct CompanionView: View {
    @Environment(PlayerProgress.self) private var progress
    var size: CGFloat = 100
    /// Gerade verfüttertes Leckerli, fliegt zum Maul.
    var feeding: Treat? = nil

    var body: some View {
        let avatar = progress.companion
        Group {
            if let avatar {
                LernAvatarBild(avatar: avatar)
            } else {
                Text("🦙").font(.system(size: size * 0.8))
            }
        }
        .frame(width: size, height: size)
        .overlay {
            ForEach(Slot.allCases, id: \.self) { slot in
                if let item = progress.wearing(slot) {
                    let place = item.placement(on: avatar)
                    Text(item.emoji)
                        .font(.system(size: size * place.scale))
                        .offset(x: size * place.x, y: size * place.y)
                }
            }
            if let feeding {
                let mouth = Placement.mouth(of: avatar)
                Text(feeding.emoji)
                    .font(.system(size: size * 0.18))
                    .offset(x: size * mouth.x, y: size * mouth.y)
                    .transition(.asymmetric(insertion: .offset(y: size * 0.5).combined(with: .opacity),
                                            removal: .scale(scale: 0.1).combined(with: .opacity)))
                Text("❤️")
                    .font(.system(size: size * 0.16))
                    .offset(x: size * 0.28, y: -size * 0.1)
                    .transition(.asymmetric(insertion: .scale(scale: 0.2), removal: .offset(y: -size * 0.3).combined(with: .opacity)))
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
}

/// Wo ein Teil sitzt: Mitte relativ zur Bildmitte und Größe, jeweils in Vielfachen der Bildgröße.
struct Placement {
    let x: CGFloat
    let y: CGFloat
    let scale: CGFloat

    /// Die Hoftiere sind gleich aufgebaut: Ohren oben, Augen knapp über der Mitte, Hals unten.
    fileprivate static let standard: [String: Placement] = [
        "cap": .init(x: 0.03, y: -0.29, scale: 0.36),
        "sunhat": .init(x: 0.02, y: -0.33, scale: 0.40),
        "tophat": .init(x: 0.02, y: -0.35, scale: 0.34),
        "crown": .init(x: 0.02, y: -0.31, scale: 0.30),
        "gradcap": .init(x: 0.02, y: -0.31, scale: 0.34),
        "glasses": .init(x: 0.03, y: -0.03, scale: 0.30),
        "sunglasses": .init(x: 0.03, y: -0.03, scale: 0.30),
        "bell": .init(x: 0, y: 0.27, scale: 0.18),
        "bow": .init(x: 0, y: 0.26, scale: 0.24),
        "scarf": .init(x: 0, y: 0.34, scale: 0.32),
        "flower": .init(x: 0.27, y: -0.24, scale: 0.20),
        "sunflower": .init(x: -0.27, y: -0.24, scale: 0.20),
        "balloon": .init(x: 0.36, y: -0.30, scale: 0.26),
        "yarn": .init(x: 0.34, y: 0.38, scale: 0.22),
        "butterfly": .init(x: 0.34, y: -0.36, scale: 0.18),
    ]

    /// Mr. Right ist nach eigenem Foto gezeichnet: Kopf leicht gedreht, Augen höher, langer schmaler Hals mit Halfter.
    fileprivate static let mrRight: [String: Placement] = [
        "cap": .init(x: 0.03, y: -0.27, scale: 0.36),
        "sunhat": .init(x: 0.02, y: -0.31, scale: 0.40),
        "tophat": .init(x: 0.02, y: -0.33, scale: 0.34),
        "crown": .init(x: 0.02, y: -0.29, scale: 0.30),
        "gradcap": .init(x: 0.02, y: -0.29, scale: 0.34),
        "glasses": .init(x: 0.03, y: -0.09, scale: 0.30),
        "sunglasses": .init(x: 0.03, y: -0.09, scale: 0.30),
        "bell": .init(x: 0.02, y: 0.20, scale: 0.16),
        "bow": .init(x: 0.02, y: 0.19, scale: 0.20),
        "scarf": .init(x: 0.02, y: 0.30, scale: 0.26),
        "flower": .init(x: 0.30, y: -0.22, scale: 0.18),
        "sunflower": .init(x: -0.28, y: -0.22, scale: 0.18),
    ]

    static func mouth(of avatar: LernAvatar?) -> Placement {
        avatar == .mrRight ? .init(x: 0, y: 0.06, scale: 0) : .init(x: 0, y: 0.12, scale: 0)
    }
}

extension Accessory {
    func placement(on avatar: LernAvatar?) -> Placement {
        (avatar == .mrRight ? Placement.mrRight[id] : nil)
            ?? Placement.standard[id]
            ?? Placement(x: 0, y: 0, scale: 0.25)
    }
}

struct WardrobeView: View {
    @Environment(PlayerProgress.self) private var progress
    @Environment(\.dismiss) private var dismiss
    @State private var toBuy: Accessory?
    @State private var feeding: Treat?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(spacing: 12) {
                        CompanionView(size: 200, feeding: feeding)
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

                    treats

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

    private var treats: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Leckerli").font(.title3.bold())
                Spacer()
                if progress.treatsFed > 0 {
                    Text("schon \(progress.treatsFed) verfüttert").font(.caption).foregroundStyle(.secondary)
                }
            }
            HStack(spacing: 10) {
                ForEach(Treats.catalog) { treat in
                    Button { feed(treat) } label: {
                        VStack(spacing: 4) {
                            Text(treat.emoji).font(.system(size: 34))
                            Text(treat.name).font(.caption.bold()).lineLimit(1).minimumScaleFactor(0.8)
                            Text("\(treat.price) ⭐️").font(.caption2).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color("WoolCard"), in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .disabled(feeding != nil || progress.availableStars < treat.price)
                    .opacity(progress.availableStars < treat.price ? 0.5 : 1)
                }
            }
        }
    }

    private func feed(_ treat: Treat) {
        guard progress.feed(treat) else { return }
        withAnimation(.spring(duration: 0.5)) { feeding = treat }
        Task {
            try? await Task.sleep(for: .seconds(1.2))
            withAnimation(.easeOut(duration: 0.5)) { feeding = nil }
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
