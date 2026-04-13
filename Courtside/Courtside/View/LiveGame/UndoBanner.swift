import SwiftUI

struct UndoBanner: View {
    @Bindable var viewModel: LiveGameViewModel

    var body: some View {
        if viewModel.showUndoBanner, let event = viewModel.lastUndoableEvent {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.statType.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    // TODO: show player name via query
                }

                Spacer()

                Button {
                    viewModel.undoLastStat()
                } label: {
                    Text("Undo")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.orange)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + Constants.undoBannerDuration) {
                    withAnimation {
                        viewModel.showUndoBanner = false
                    }
                }
            }
        }
    }
}
