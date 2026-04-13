import SwiftUI
import PhotosUI

struct RosterScanView: View {
    @Environment(\.dismiss) private var dismiss

    let onPlayersScanned: ([(number: String, firstName: String, lastName: String)]) -> Void

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var showingCamera = false
    @State private var isScanning = false
    @State private var scanError: String?
    @State private var scannedPlayers: [ScannedPlayer] = []
    @State private var showingResults = false
    @State private var usedGeminiFallback = false

    private let scanner = RosterScanner()

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if isScanning {
                    scanningView
                } else if showingResults {
                    resultsView
                } else {
                    sourcePickerView
                }
            }
            .navigationTitle("Scan Roster")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .fullScreenCover(isPresented: $showingCamera) {
                CameraView(image: $selectedImage)
                    .ignoresSafeArea()
            }
            .onChange(of: selectedPhoto) { _, newValue in
                loadPhoto(newValue)
            }
            .onChange(of: selectedImage) { _, newValue in
                if let image = newValue {
                    Task { await scanImage(image) }
                }
            }
        }
    }

    // MARK: - Source Picker

    private var sourcePickerView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "doc.viewfinder")
                .font(.system(size: 60))
                .foregroundStyle(.orange)

            Text("Take a photo of the opponent's roster, game program, or lineup sheet")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(spacing: 12) {
                Button {
                    showingCamera = true
                } label: {
                    Label("Take Photo", systemImage: "camera.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)

                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Label("Choose from Library", systemImage: "photo.on.rectangle")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 32)

            if let scanError {
                Text(scanError)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }

            Spacer()
        }
    }

    // MARK: - Scanning

    private var scanningView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Text("Scanning roster…")
                .font(.headline)
            if usedGeminiFallback {
                Text("Using AI to read the roster")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    // MARK: - Results

    private var resultsView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("\(scannedPlayers.count) players found")
                    .font(.headline)
                Spacer()
                if usedGeminiFallback {
                    Label("AI", systemImage: "sparkles")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            .padding()

            // Player list
            List {
                ForEach(Array(scannedPlayers.enumerated()), id: \.offset) { _, player in
                    HStack {
                        Text("#\(player.jerseyNumber)")
                            .fontWeight(.bold)
                            .frame(width: 44)
                        Text("\(player.firstName) \(player.lastName)")
                        Spacer()
                    }
                }
                .onDelete { offsets in
                    scannedPlayers.remove(atOffsets: offsets)
                }
            }
            .listStyle(.plain)

            // Action buttons
            VStack(spacing: 8) {
                Button {
                    let players = scannedPlayers.map {
                        (number: $0.jerseyNumber, firstName: $0.firstName, lastName: $0.lastName)
                    }
                    onPlayersScanned(players)
                    dismiss()
                } label: {
                    Text("Add \(scannedPlayers.count) Players")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(scannedPlayers.isEmpty)

                Button {
                    // Reset to try again
                    showingResults = false
                    scannedPlayers = []
                    selectedImage = nil
                    selectedPhoto = nil
                    scanError = nil
                    usedGeminiFallback = false
                } label: {
                    Text("Scan Again")
                        .font(.subheadline)
                }
            }
            .padding()
        }
    }

    // MARK: - Actions

    private func loadPhoto(_ item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                selectedImage = image
            }
        }
    }

    private func scanImage(_ image: UIImage) async {
        isScanning = true
        scanError = nil
        usedGeminiFallback = false

        // Try Vision first
        let result = await scanner.scanWithVision(image: image)

        switch result {
        case .success(let players):
            scannedPlayers = players
            showingResults = true

        case .needsFallback(let img):
            // Try Gemini
            usedGeminiFallback = true
            let geminiKey = GeminiConfig.apiKey
            guard !geminiKey.isEmpty else {
                scanError = "Vision couldn't parse this roster. Set up Gemini API key for AI fallback."
                break
            }
            let fallbackResult = await scanner.scanWithGemini(image: img, apiKey: geminiKey)
            switch fallbackResult {
            case .success(let players):
                scannedPlayers = players
                showingResults = true
            case .failure(let error):
                scanError = error
            case .needsFallback:
                scanError = "Could not read this roster. Try a clearer photo."
            }

        case .failure(let error):
            scanError = error
        }

        isScanning = false
    }
}

// MARK: - Camera View (UIKit wrapper)

struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
