import SwiftUI

@Observable
final class OrientationManager {
    static let shared = OrientationManager()

    var allowLandscape: Bool = false

    var supportedOrientations: UIInterfaceOrientationMask {
        allowLandscape ? .allButUpsideDown : .portrait
    }

    private init() {}
}
