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
                        .rotationEffect(.degrees(place.rotation))
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
        case .head: "Head"
        case .eyes: "Eyes"
        case .neck: "Neck"
        case .extra: "Extras"
        }
    }
}

/// Wo ein Teil sitzt: Mitte relativ zur Bildmitte, Größe und Drehung im Uhrzeigersinn, in Vielfachen der Bildgröße.
struct Placement {
    let x: CGFloat
    let y: CGFloat
    let scale: CGFloat
    var rotation: Double = 0
}

/// Die Augen eines Avatars, in Bildkoordinaten (Mitte 0, Rand ±0.5, y nach unten), aus den Bildern vermessen.
/// Daraus ergeben sich Kopfneigung und Gesichtsgröße, nach denen alle Teile ausgerichtet werden.
struct AvatarFace {
    let left: CGPoint
    let right: CGPoint

    var center: CGPoint { CGPoint(x: (left.x + right.x) / 2, y: (left.y + right.y) / 2) }
    var eyeDistance: CGFloat { hypot(right.x - left.x, right.y - left.y) }
    var tilt: Double { atan2(right.y - left.y, right.x - left.x) * 180 / .pi }

    /// Punkt im Gesicht: `along` entlang der Augenachse, `up` Richtung Stirn, beides in Augenabständen.
    func point(along: CGFloat, up: CGFloat) -> CGPoint {
        let d = eyeDistance
        let ax = (right.x - left.x) / d, ay = (right.y - left.y) / d
        return CGPoint(x: center.x + (along * ax + up * ay) * d, y: center.y + (along * ay - up * ax) * d)
    }

    static let all: [LernAvatar: AvatarFace] = [
        .amber: .init(left: CGPoint(x: -0.07, y: -0.093), right: CGPoint(x: 0.147, y: -0.048)),
        .callisto: .init(left: CGPoint(x: -0.046, y: -0.06), right: CGPoint(x: 0.172, y: -0.019)),
        .carry: .init(left: CGPoint(x: -0.072, y: -0.073), right: CGPoint(x: 0.163, y: -0.04)),
        .catwizzle: .init(left: CGPoint(x: -0.066, y: -0.073), right: CGPoint(x: 0.151, y: -0.046)),
        .claire: .init(left: CGPoint(x: -0.076, y: -0.065), right: CGPoint(x: 0.15, y: -0.029)),
        .cloe: .init(left: CGPoint(x: -0.066, y: -0.076), right: CGPoint(x: 0.165, y: -0.039)),
        .covergirl: .init(left: CGPoint(x: -0.072, y: -0.073), right: CGPoint(x: 0.163, y: -0.035)),
        .dexter: .init(left: CGPoint(x: -0.082, y: -0.09), right: CGPoint(x: 0.146, y: -0.04)),
        .diandro: .init(left: CGPoint(x: -0.06, y: -0.05), right: CGPoint(x: 0.171, y: -0.006)),
        .diego: .init(left: CGPoint(x: -0.08, y: -0.067), right: CGPoint(x: 0.146, y: -0.026)),
        .flavio: .init(left: CGPoint(x: -0.07, y: -0.051), right: CGPoint(x: 0.154, y: -0.009)),
        .jeppediah: .init(left: CGPoint(x: -0.061, y: -0.09), right: CGPoint(x: 0.151, y: -0.056)),
        .kuno: .init(left: CGPoint(x: -0.076, y: -0.081), right: CGPoint(x: 0.155, y: -0.039)),
        .leyla: .init(left: CGPoint(x: -0.08, y: -0.076), right: CGPoint(x: 0.148, y: -0.031)),
        .mrRight: .init(left: CGPoint(x: -0.117, y: -0.113), right: CGPoint(x: 0.134, y: -0.082)),
        .nalima: .init(left: CGPoint(x: -0.061, y: -0.077), right: CGPoint(x: 0.169, y: -0.032)),
        .nougat: .init(left: CGPoint(x: -0.072, y: -0.06), right: CGPoint(x: 0.126, y: -0.029)),
        .rocky: .init(left: CGPoint(x: -0.082, y: -0.06), right: CGPoint(x: 0.146, y: -0.021)),
        .santana: .init(left: CGPoint(x: -0.06, y: -0.04), right: CGPoint(x: 0.16, y: -0.009)),
        .silk: .init(left: CGPoint(x: -0.08, y: -0.066), right: CGPoint(x: 0.146, y: -0.032)),
        .thaios: .init(left: CGPoint(x: -0.05, y: -0.098), right: CGPoint(x: 0.148, y: -0.063)),
        .whitney: .init(left: CGPoint(x: -0.07, y: -0.068), right: CGPoint(x: 0.168, y: -0.028)),
    ]

    /// Für den Fall ohne Begleiter: ein gerade nach vorn schauendes Gesicht.
    static let neutral = AvatarFace(left: CGPoint(x: -0.1, y: -0.06), right: CGPoint(x: 0.12, y: -0.06))

    static func of(_ avatar: LernAvatar?) -> AvatarFace { avatar.flatMap { all[$0] } ?? neutral }
}

/// Wo ein Teil im Gesicht sitzt, in Augenabständen; die Drehung kommt zur Kopfneigung dazu.
struct FaceAnchor {
    let along: CGFloat
    let up: CGFloat
    let size: CGFloat
    var rotation: Double = 0

    /// Gegen alle 22 Avatare geprüft.
    static let items: [String: FaceAnchor] = [
        "cap": .init(along: 0.1, up: 1.0, size: 1.45),
        "sunhat": .init(along: 0, up: 1.05, size: 1.65),
        "tophat": .init(along: 0, up: 1.05, size: 1.3),
        "crown": .init(along: 0, up: 0.98, size: 1.15),
        "gradcap": .init(along: 0, up: 0.98, size: 1.35),
        "glasses": .init(along: 0, up: 0, size: 1.25),
        "sunglasses": .init(along: 0, up: 0, size: 1.25),
        "bell": .init(along: 0, up: -1.25, size: 0.6),
        "bow": .init(along: 0, up: -1.2, size: 0.85),
        "scarf": .init(along: 0, up: -1.55, size: 1.2),
        "flower": .init(along: 1.05, up: 0.95, size: 0.8, rotation: 20),
        "sunflower": .init(along: -1.05, up: 0.95, size: 0.8, rotation: -15),
        "balloon": .init(along: 1.5, up: 1.2, size: 1.1),
        "yarn": .init(along: 1.4, up: -2.0, size: 0.95),
        "butterfly": .init(along: 1.4, up: 1.5, size: 0.8),
    ]

    func placement(on face: AvatarFace) -> Placement {
        let p = face.point(along: along, up: up)
        let scale = size * face.eyeDistance
        // Nicht über den Bildrand hinaus, damit Ballon und Co. nicht abgeschnitten werden.
        let half = scale / 2
        return Placement(x: min(max(p.x, -0.5 + half), 0.5 - half),
                         y: min(max(p.y, -0.5 + half), 0.5 - half),
                         scale: scale, rotation: face.tilt + rotation)
    }
}

extension Placement {
    static func mouth(of avatar: LernAvatar?) -> Placement {
        let face = AvatarFace.of(avatar)
        let p = face.point(along: 0.25, up: -0.75)
        return Placement(x: p.x, y: p.y, scale: 0)
    }
}

extension Accessory {
    func placement(on avatar: LernAvatar?) -> Placement {
        (FaceAnchor.items[id] ?? FaceAnchor(along: 0, up: 0, size: 1)).placement(on: .of(avatar))
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
                            Text("\(progress.availableStars) stars to spend").bold()
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
            .navigationTitle("Rewards")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Done") { dismiss() } }
            .alert("Buy it?", isPresented: Binding(get: { toBuy != nil }, set: { if !$0 { toBuy = nil } }), presenting: toBuy) { item in
                Button("Buy for \(item.price) ⭐️") { withAnimation { progress.buy(item) } }
                Button("Not now", role: .cancel) {}
            } message: { item in
                Text("\(item.emoji) \(item.name) for \(progress.companion?.name ?? "your llama")?")
            }
            .animation(.spring(duration: 0.3), value: progress.availableStars)
        }
    }

    private var treats: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Treats").font(.title3.bold())
                Spacer()
                if progress.treatsFed > 0 {
                    Text(progress.treatsFed == 1 ? "1 treat so far" : "\(progress.treatsFed) treats so far").font(.caption).foregroundStyle(.secondary)
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
                case .alreadyOwned: Text(wearing ? "Wearing ✓" : "Put on")
                case nil: Text("\(item.price) ⭐️")
                case .notEnoughStars(let missing): Text("🔒 \(missing) more ⭐️")
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
