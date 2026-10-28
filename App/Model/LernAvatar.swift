import SwiftUI

/// 21 benannte Tiere der Schöcklblick-Galerie plus Mr. Right nach Nutzerfoto.
/// Arten visuell eingeordnet; Lernrollen und Sprüche für Valerie erfunden.
/// Jeppediah/Leyla: Namenszuordnung im gemeinsamen Foto ist eine Annahme.
enum LernAvatar: String, CaseIterable, Identifiable {
    case rocky, nougat, jeppediah, leyla, whitney, silk, santana, kuno, flavio, claire, catwizzle, diego, dexter, covergirl, carry, thaios, nalima, diandro, cloe, callisto, amber, mrRight

    var id: String { rawValue }
    var assetName: String { "avatar_\(rawValue)" }

    var name: String {
        switch self {
        case .rocky: "Rocky"
        case .nougat: "Nougat"
        case .jeppediah: "Jeppediah"
        case .leyla: "Leyla"
        case .whitney: "Whitney"
        case .silk: "Silk"
        case .santana: "Santana"
        case .kuno: "Kuno"
        case .flavio: "Flavio"
        case .claire: "Claire"
        case .catwizzle: "Catwizzle"
        case .diego: "Diego"
        case .dexter: "Dexter"
        case .covergirl: "Covergirl"
        case .carry: "Carry"
        case .thaios: "Thaios"
        case .nalima: "Nalima"
        case .diandro: "Diandro"
        case .cloe: "Cloe"
        case .callisto: "Callisto"
        case .amber: "Amber"
        case .mrRight: "Mr. Right"
        }
    }

    var tierart: String {
        switch self {
        case .rocky: "Alpaka"
        case .nougat: "Lama"
        case .jeppediah: "Alpaka"
        case .leyla: "Alpaka"
        case .whitney: "Alpaka"
        case .silk: "Alpaka"
        case .santana: "Alpaka"
        case .kuno: "Alpaka"
        case .flavio: "Alpaka"
        case .claire: "Alpaka"
        case .catwizzle: "Alpaka"
        case .diego: "Alpaka"
        case .dexter: "Alpaka"
        case .covergirl: "Alpaka"
        case .carry: "Alpaka"
        case .thaios: "Lama"
        case .nalima: "Lama"
        case .diandro: "Alpaka"
        case .cloe: "Alpaka"
        case .callisto: "Alpaka"
        case .amber: "Alpaka"
        case .mrRight: "Alpaka"
        }
    }

    var lernrolle: String {
        switch self {
        case .rocky: "Der mutige Wortabenteurer"
        case .nougat: "Der neugierige Entdecker"
        case .jeppediah: "Der gelassene Erklärer"
        case .leyla: "Die kleine Neugierige"
        case .whitney: "Die fröhliche Wortfinderin"
        case .silk: "Der ruhige Zuhörer"
        case .santana: "Der konzentrierte Denker"
        case .kuno: "Der geduldige Übungspartner"
        case .flavio: "Der flinke Wiederholer"
        case .claire: "Die aufmerksame Lesefreundin"
        case .catwizzle: "Der verspielte Reimfreund"
        case .diego: "Der freundliche Mutmacher"
        case .dexter: "Der schlaue Rätselknacker"
        case .covergirl: "Die begeisterte Vorleserin"
        case .carry: "Die treue Übungsfreundin"
        case .thaios: "Der stolze Sterne-Sammler"
        case .nalima: "Die fröhliche Lernfreundin"
        case .diandro: "Der geduldige Aussprachehelfer"
        case .cloe: "Die liebevolle Mutmacherin"
        case .callisto: "Der neugierige Wortsammler"
        case .amber: "Die ruhige Geschichtenfreundin"
        case .mrRight: "Der verlässliche Lernbegleiter"
        }
    }

    var spruch: String {
        switch self {
        case .rocky: "Ready for a new adventure?"
        case .nougat: "Let's try a new word!"
        case .jeppediah: "Step by step, we learn."
        case .leyla: "What does this word mean?"
        case .whitney: "Let's find the right word!"
        case .silk: "Listen, then say it with me."
        case .santana: "Take your time. You've got this!"
        case .kuno: "One more try. You can do it!"
        case .flavio: "Say it again with me!"
        case .claire: "Let's read it together."
        case .catwizzle: "Can you hear the rhyme?"
        case .diego: "Great job, Valerie!"
        case .dexter: "Can you solve this one?"
        case .covergirl: "Your turn to read aloud!"
        case .carry: "A little practice every day!"
        case .thaios: "Another word, another star!"
        case .nalima: "Let's learn together!"
        case .diandro: "Let's say it slowly."
        case .cloe: "Mistakes help us learn!"
        case .callisto: "One new word at a time!"
        case .amber: "Every word tells a story."
        case .mrRight: "Let's get it right together!"
        }
    }

}

struct LernAvatarBild: View {
    let avatar: LernAvatar

    var body: some View {
        Image(avatar.assetName)
            .resizable()
            .scaledToFit()
            .accessibilityLabel("\(avatar.tierart) \(avatar.name)")
    }
}
