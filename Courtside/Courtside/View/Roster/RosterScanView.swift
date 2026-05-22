import SwiftUI
import PhotosUI

/// Roster scan — source picker → (scan) → editable review screen.
/// Apple OCR is unreliable, so the review screen is built to invite editing:
/// low-confidence rows are flagged amber, every field is inline-editable.
struct RosterScanView: View {
    @Environment(\.dismiss) private var dismiss

    let onPlayersScanned: ([(number: String, firstName: String, lastName: String)]) -> Void

    @State private var stage: Stage = .source
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var showingCamera = false
    @State private var scanError: String?
    @State private var rows: [ScanRow] = []
    @State private var usedGeminiFallback = false

    private let scanner = RosterScanner()

    enum Stage { case source, scanning, review }

    struct ScanRow: Identifiable {
        let id = UUID()
        var number: String
        var first: String
        var last: String
        var lowConfidence: Bool
    }

    private var flaggedCount: Int { rows.filter(\.lowConfidence).count }
    private var validRows: [ScanRow] {
        rows.filter { !$0.number.trimmingCharacters(in: .whitespaces).isEmpty
            || !$0.last.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    var body: some View {
        VStack(spacing: 0) {
            chrome
            switch stage {
            case .source:   sourcePicker
            case .scanning: scanningView
            case .review:   reviewView
            }
        }
        .background(CS.bgStage)
        .fullScreenCover(isPresented: $showingCamera) {
            CameraView(image: $selectedImage).ignoresSafeArea()
        }
        .onChange(of: selectedPhoto) { _, newValue in loadPhoto(newValue) }
        .onChange(of: selectedImage) { _, newValue in
            if let image = newValue { Task { await scanImage(image) } }
        }
    }

    // MARK: - Chrome

    private var chrome: some View {
        HStack {
            Button("Cancel") { dismiss() }
                .font(.csUI(15, weight: .medium))
                .foregroundStyle(CS.inkMute)
            Spacer()
            Text(stage == .review ? "Review · \(rows.count) found" : "Scan roster")
                .font(.csUI(16, weight: .bold))
                .foregroundStyle(CS.ink)
            Spacer()
            if stage == .review && usedGeminiFallback {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                    Text("AI")
                }
                .font(.csUI(12, weight: .bold))
                .foregroundStyle(CS.brand)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(CS.brandSoft, in: Capsule())
            } else {
                Color.clear.frame(width: 52, height: 1)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        .overlay(alignment: .bottom) { Rectangle().fill(CS.line).frame(height: 1) }
    }

    // MARK: - Source picker

    private var sourcePicker: some View {
        VStack(spacing: 0) {
            VStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(CS.brand.opacity(0.08))
                    .frame(width: 120, height: 140)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(CS.brand.opacity(0.45),
                                          style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                    )
                    .overlay(
                        Image(systemName: "list.bullet.rectangle")
                            .font(.system(size: 44, weight: .light))
                            .foregroundStyle(CS.brand)
                    )

                VStack(spacing: 6) {
                    Text("Snap a roster sheet.")
                        .font(.csDisplay(26, weight: .heavy))
                        .foregroundStyle(CS.ink)
                    Text("Take a photo of the opponent's roster, program, or lineup sheet. We'll pull out numbers and names.")
                        .font(.csUI(14))
                        .foregroundStyle(CS.inkMute)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.top, 32)
            .padding(.horizontal, 24)

            disclaimer
                .padding(.horizontal, 14)
                .padding(.top, 20)

            VStack(spacing: 10) {
                Button { showingCamera = true } label: {
                    actionLabel("Take photo", systemImage: "camera.fill", filled: true)
                }
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    actionLabel("Choose from library", systemImage: "photo.on.rectangle", filled: false)
                }
                Button {
                    rows = [ScanRow(number: "", first: "", last: "", lowConfidence: false)]
                    usedGeminiFallback = false
                    stage = .review
                } label: {
                    Text("Enter manually")
                        .font(.csUI(14, weight: .semibold))
                        .foregroundStyle(CS.inkMute)
                        .frame(height: 44)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 16)

            if let scanError {
                Text(scanError)
                    .font(.csUI(12))
                    .foregroundStyle(CS.danger)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 10)
            }

            Spacer()
        }
    }

    private var disclaimer: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("!")
                .font(.csDisplay(12, weight: .heavy))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(CS.amber, in: Circle())
            (Text("Always review the results. ").font(.csUI(12, weight: .bold))
             + Text("Handwriting, glare, and odd fonts can throw it off. You'll see every player on the next screen and can fix anything before adding.")
                .font(.csUI(12)))
            .foregroundStyle(CS.ink)
        }
        .padding(12)
        .background(CS.amberSoft)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(CS.amber.opacity(0.4), lineWidth: 1.2)
        )
    }

    private func actionLabel(_ title: String, systemImage: String, filled: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
            Text(title)
        }
        .font(.csUI(16, weight: .bold))
        .foregroundStyle(filled ? .white : CS.ink)
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .background(filled ? CS.brand : CS.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(filled ? .clear : CS.lineStrong, lineWidth: 1.4)
        )
    }

    // MARK: - Scanning

    private var scanningView: some View {
        VStack(spacing: 14) {
            Spacer()
            ProgressView().controlSize(.large)
            Text("Scanning roster…")
                .font(.csDisplay(20, weight: .bold))
                .foregroundStyle(CS.ink)
            if usedGeminiFallback {
                Text("Using AI to read the roster")
                    .font(.csUI(13))
                    .foregroundStyle(CS.inkMute)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Review

    private var reviewView: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    summary
                    tipBanner
                    VStack(spacing: 6) {
                        ForEach($rows) { $row in
                            scanRow($row)
                        }
                    }
                    .padding(.horizontal, 14)

                    Button {
                        rows.append(ScanRow(number: "", first: "", last: "", lowConfidence: false))
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                            Text("Add a player manually")
                        }
                        .font(.csUI(13, weight: .semibold))
                        .foregroundStyle(CS.inkMute)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(CS.lineStrong,
                                              style: StrokeStyle(lineWidth: 1.4, dash: [5, 4]))
                        )
                    }
                    .padding(14)
                }
            }
            .scrollIndicators(.hidden)

            commitBar
        }
    }

    private var summary: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 8)
                .fill(CS.ink.opacity(0.1))
                .frame(width: 50, height: 62)
                .overlay(
                    Image(systemName: "doc.text")
                        .font(.system(size: 24))
                        .foregroundStyle(CS.inkMute)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text("\(rows.count) player\(rows.count == 1 ? "" : "s") parsed")
                    .font(.csUI(13, weight: .bold))
                    .foregroundStyle(CS.ink)
                Text(flaggedCount > 0
                     ? "\(flaggedCount) row\(flaggedCount == 1 ? "" : "s") flagged low confidence — review the highlighted ones"
                     : "Tap any field to fix a name or number before adding.")
                    .font(.csUI(11))
                    .foregroundStyle(CS.inkMute)
            }
            Spacer(minLength: 0)
            Button("Re-scan") {
                stage = .source
                rows = []
                selectedImage = nil
                selectedPhoto = nil
                scanError = nil
            }
            .font(.csUI(12, weight: .bold))
            .foregroundStyle(CS.brand)
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 6)
    }

    private var tipBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "pencil")
                .font(.system(size: 12))
                .foregroundStyle(CS.amber)
            Text("Tap any field to edit · use the trash icon to remove a row")
                .font(.csUI(11))
                .foregroundStyle(CS.inkMute)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(CS.bgSoft)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 14)
        .padding(.bottom, 10)
    }

    private func scanRow(_ row: Binding<ScanRow>) -> some View {
        let flagged = row.wrappedValue.lowConfidence
        return HStack(spacing: 10) {
            TextField("#", text: row.number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.csDisplay(16, weight: .heavy))
                .foregroundStyle(CS.home)
                .frame(width: 40, height: 36)
                .background(CS.home.opacity(0.1), in: Circle())
                .overlay(Circle().strokeBorder(CS.home, lineWidth: 1.4))

            VStack(spacing: 2) {
                HStack(spacing: 6) {
                    TextField("First", text: row.first)
                        .font(.csUI(14, weight: .semibold))
                    TextField("Last", text: row.last)
                        .font(.csUI(14, weight: .bold))
                    if flagged {
                        Text("CHECK")
                            .font(.csUI(9, weight: .heavy))
                            .tracking(0.6)
                            .foregroundStyle(CS.amber)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(CS.amber.opacity(0.18), in: Capsule())
                    }
                }
                .foregroundStyle(CS.ink)
                .autocorrectionDisabled()
            }

            Button {
                if let index = rows.firstIndex(where: { $0.id == row.wrappedValue.id }) {
                    rows.remove(at: index)
                }
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundStyle(CS.inkMute)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(flagged ? CS.amber.opacity(0.07) : CS.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(flagged ? CS.amber.opacity(0.45) : CS.line, lineWidth: 1.2)
        )
    }

    private var commitBar: some View {
        HStack(spacing: 8) {
            Button {
                dismiss()
            } label: {
                Text("Discard")
                    .font(.csUI(14, weight: .bold))
                    .foregroundStyle(CS.ink)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(CS.bgSoft, in: RoundedRectangle(cornerRadius: 12))
            }
            Button {
                onPlayersScanned(validRows.map {
                    (number: $0.number.trimmingCharacters(in: .whitespaces),
                     firstName: $0.first.trimmingCharacters(in: .whitespaces),
                     lastName: $0.last.trimmingCharacters(in: .whitespaces))
                })
                dismiss()
            } label: {
                Text("Add \(validRows.count) player\(validRows.count == 1 ? "" : "s")")
                    .font(.csUI(15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(CS.brand, in: RoundedRectangle(cornerRadius: 12))
            }
            .disabled(validRows.isEmpty)
            .opacity(validRows.isEmpty ? 0.5 : 1)
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(CS.bgStage)
        .overlay(alignment: .top) { Rectangle().fill(CS.line).frame(height: 1) }
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
        stage = .scanning
        scanError = nil
        usedGeminiFallback = false

        let result = await scanner.scanWithVision(image: image)

        switch result {
        case .success(let players):
            rows = players.map(makeRow)
            stage = .review

        case .needsFallback(let img):
            usedGeminiFallback = true
            let geminiKey = GeminiConfig.apiKey
            guard !geminiKey.isEmpty else {
                scanError = "Vision couldn't parse this roster. Set up a Gemini API key for AI fallback, or enter players manually."
                stage = .source
                return
            }
            let fallback = await scanner.scanWithGemini(image: img, apiKey: geminiKey)
            switch fallback {
            case .success(let players):
                rows = players.map(makeRow)
                stage = .review
            case .failure(let error):
                scanError = error
                stage = .source
            case .needsFallback:
                scanError = "Could not read this roster. Try a clearer photo."
                stage = .source
            }

        case .failure(let error):
            scanError = error
            stage = .source
        }
    }

    private func makeRow(_ player: ScannedPlayer) -> ScanRow {
        ScanRow(
            number: player.jerseyNumber,
            first: player.firstName,
            last: player.lastName,
            lowConfidence: player.confidence == .low
        )
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
