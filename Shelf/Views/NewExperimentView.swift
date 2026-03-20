import SwiftUI
import PhotosUI

struct NewExperimentView: View {
    @EnvironmentObject var store: SupabaseExperimentStore
    @Environment(\.dismiss) var dismiss

    @State private var name: String = ""
    @State private var intention: String = ""
    @State private var frequency: CheckInFrequency? = .daily
    @State private var durationDays: Int? = 30
    @State private var isPublic: Bool = true
    @State private var selectedIcon: ExperimentIcon = .book
    @State private var openEnded: Bool = false
    @State private var step: Int = 0

    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var processedImage: UIImage? = nil
    @State private var isProcessingPhoto = false
    @State private var showPhotoPicker = false
    @State private var showCamera = false
    @State private var showPhotoSourceSheet = false

    private let cream    = Color(red: 0.98, green: 0.96, blue: 0.93)
    private let graphite = Color(red: 0.25, green: 0.23, blue: 0.22)

    var body: some View {
        ZStack {
            cream.ignoresSafeArea()
            VStack(spacing: 0) {
                Capsule()
                    .fill(graphite.opacity(0.2))
                    .frame(width: 36, height: 4)
                    .padding(.top, 12).padding(.bottom, 28)

                HStack(spacing: 6) {
                    ForEach(0..<2) { i in
                        Capsule()
                            .fill(i <= step ? graphite : graphite.opacity(0.15))
                            .frame(width: i == step ? 20 : 6, height: 6)
                            .animation(.spring(response: 0.4), value: step)
                    }
                }
                .padding(.bottom, 32)

                if step == 0 {
                    stepOne.transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .trailing)),
                        removal: .opacity.combined(with: .move(edge: .leading))
                    ))
                } else {
                    stepTwo.transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .trailing)),
                        removal: .opacity.combined(with: .move(edge: .leading))
                    ))
                }
            }
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhoto, matching: .images)
        .onChange(of: selectedPhoto) { _, item in Task { await loadPickedPhoto(item) } }
        .sheet(isPresented: $showCamera) {
            CameraView { image in Task { await processPhoto(image) } }
        }
        .confirmationDialog("Add photo", isPresented: $showPhotoSourceSheet) {
            Button("Take a photo")        { showCamera = true }
            Button("Choose from library") { showPhotoPicker = true }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Step 1: Icon / Photo + Name

    private var stepOne: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {

                VStack(alignment: .leading, spacing: 14) {
                    Text("Give it an icon")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundStyle(graphite)

                    Button { showPhotoSourceSheet = true } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(graphite.opacity(0.04))
                                .frame(maxWidth: .infinity).frame(height: 110)
                                .overlay(RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(graphite.opacity(0.18), style: StrokeStyle(lineWidth: 1, dash: [5])))

                            if isProcessingPhoto {
                                HStack(spacing: 10) {
                                    ProgressView().tint(graphite)
                                    Text("Removing background…")
                                        .font(.system(size: 13, design: .rounded))
                                        .foregroundStyle(graphite.opacity(0.5))
                                }
                            } else if let img = processedImage {
                                HStack(spacing: 16) {
                                    Image(uiImage: img).resizable().scaledToFit()
                                        .frame(width: 72, height: 72)
                                        .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Looking good")
                                            .font(.system(size: 14, weight: .medium, design: .rounded))
                                            .foregroundStyle(graphite)
                                        Text("Tap to change")
                                            .font(.system(size: 12, design: .rounded))
                                            .foregroundStyle(graphite.opacity(0.4))
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                            } else {
                                HStack(spacing: 10) {
                                    Image(systemName: "camera")
                                        .font(.system(size: 18, weight: .thin))
                                        .foregroundStyle(graphite.opacity(0.45))
                                    Text("Add a photo of your object")
                                        .font(.system(size: 14, design: .rounded))
                                        .foregroundStyle(graphite.opacity(0.45))
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    HStack {
                        Rectangle().fill(graphite.opacity(0.1)).frame(height: 1)
                        Text("or pick one")
                            .font(.system(size: 11, design: .rounded))
                            .foregroundStyle(graphite.opacity(0.3)).padding(.horizontal, 8)
                        Rectangle().fill(graphite.opacity(0.1)).frame(height: 1)
                    }

                    LazyVGrid(columns: Array(repeating: .init(.flexible(), spacing: 10), count: 4), spacing: 12) {
                        ForEach(ExperimentIcon.allCases, id: \.self) { icon in
                            let isSelected = selectedIcon == icon && processedImage == nil
                            Button {
                                withAnimation(.spring(response: 0.3)) { selectedIcon = icon; processedImage = nil }
                            } label: {
                                VStack(spacing: 5) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(isSelected ? graphite : graphite.opacity(0.06))
                                            .frame(width: 54, height: 54)
                                        Image(systemName: icon.rawValue)
                                            .font(.system(size: 22, weight: .thin))
                                            .foregroundStyle(isSelected ? cream : graphite.opacity(0.55))
                                    }
                                    Text(icon.label)
                                        .font(.system(size: 9, design: .rounded))
                                        .foregroundStyle(graphite.opacity(0.4))
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Rectangle().fill(graphite.opacity(0.08)).frame(height: 1)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Name your experiment")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(graphite)
                    ZStack(alignment: .leading) {
                        if name.isEmpty {
                            Text("e.g. Wake before 5am")
                                .font(.system(size: 17, design: .rounded))
                                .foregroundStyle(graphite.opacity(0.2))
                        }
                        TextField("", text: $name)
                            .font(.system(size: 17, design: .rounded))
                            .foregroundStyle(graphite).tint(graphite)
                    }
                    .padding(.vertical, 14)
                    Rectangle().fill(graphite.opacity(0.15)).frame(height: 1)
                }

                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { step = 1 }
                } label: {
                    Text("Continue")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(name.isEmpty ? graphite.opacity(0.3) : cream)
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(name.isEmpty ? graphite.opacity(0.1) : graphite)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(name.isEmpty)
            }
            .padding(.horizontal, 24).padding(.bottom, 40)
        }
    }

    // MARK: - Step 2: Details

    private var stepTwo: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {

                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Text("Set an intention")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(graphite)
                        Text("optional")
                            .font(.system(size: 11, design: .rounded))
                            .foregroundStyle(graphite.opacity(0.35))
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(graphite.opacity(0.06)).clipShape(Capsule())
                    }
                    ZStack(alignment: .topLeading) {
                        if intention.isEmpty {
                            Text("Why are you trying this?")
                                .font(.system(size: 14, design: .rounded))
                                .foregroundStyle(graphite.opacity(0.2))
                                .padding(.top, 14).padding(.leading, 4)
                        }
                        TextEditor(text: $intention)
                            .font(.system(size: 14, design: .rounded)).foregroundStyle(graphite)
                            .scrollContentBackground(.hidden).frame(minHeight: 80)
                            .padding(.horizontal, -4)
                    }
                    Rectangle().fill(graphite.opacity(0.15)).frame(height: 1)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("How often?")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(graphite.opacity(0.5))
                    HStack(spacing: 8) {
                        ForEach(CheckInFrequency.allCases, id: \.self) { f in
                            let sel = frequency == f
                            Button { withAnimation(.spring(response: 0.3)) { frequency = f } } label: {
                                Text(f.rawValue)
                                    .font(.system(size: 12, weight: sel ? .semibold : .regular, design: .rounded))
                                    .foregroundStyle(sel ? cream : graphite.opacity(0.55))
                                    .padding(.horizontal, 12).padding(.vertical, 9)
                                    .background(sel ? graphite : graphite.opacity(0.07))
                                    .clipShape(Capsule())
                            }.buttonStyle(.plain)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Duration")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(graphite.opacity(0.5))
                        Spacer()
                        Toggle("", isOn: $openEnded)
                            .toggleStyle(SwitchToggleStyle(tint: graphite)).labelsHidden()
                        Text("Open-ended")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundStyle(graphite.opacity(0.4))
                    }
                    if !openEnded {
                        HStack(spacing: 8) {
                            ForEach([7, 14, 21, 30], id: \.self) { d in
                                let sel = durationDays == d
                                Button { withAnimation(.spring(response: 0.3)) { durationDays = d } } label: {
                                    Text("\(d)d")
                                        .font(.system(size: 13, weight: sel ? .semibold : .regular, design: .rounded))
                                        .foregroundStyle(sel ? cream : graphite.opacity(0.55))
                                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                                        .background(sel ? graphite : graphite.opacity(0.07))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }.buttonStyle(.plain)
                            }
                        }
                    }
                }

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Make it public")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(graphite.opacity(0.6))
                        Text("Others can browse and try your experiment")
                            .font(.system(size: 11, design: .rounded))
                            .foregroundStyle(graphite.opacity(0.3))
                    }
                    Spacer()
                    Toggle("", isOn: $isPublic).toggleStyle(SwitchToggleStyle(tint: graphite))
                }
                .padding(14).background(graphite.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                HStack(spacing: 10) {
                    Button { withAnimation(.spring(response: 0.4)) { step = 0 } } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(graphite.opacity(0.6))
                            .frame(width: 50, height: 50)
                            .background(graphite.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }.buttonStyle(.plain)

                    Button { launch() } label: {
                        Text("Place on shelf")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(cream).frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(graphite).clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
            .padding(.horizontal, 24).padding(.bottom, 40)
        }
    }

    // MARK: - Photo handling

    private func loadPickedPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        isProcessingPhoto = true
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            await processPhoto(image)
        }
        isProcessingPhoto = false
    }

    private func processPhoto(_ image: UIImage) async {
        isProcessingPhoto = true
        processedImage = await BackgroundRemover.process(image)
        isProcessingPhoto = false
    }

    private func launch() {
        var experiment = Experiment(
            name: name,
            intention: intention.isEmpty ? nil : intention,
            frequency: frequency,
            durationDays: openEnded ? nil : durationDays,
            isPublic: isPublic,
            iconPreset: selectedIcon
        )
        if let img = processedImage {
            experiment.hasCustomImage = true
            store.add(experiment)
            store.saveCustomImage(img, for: experiment.id)
        } else {
            store.add(experiment)
        }
        dismiss()
    }
}

// MARK: - Camera wrapper

struct CameraView: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void
    @Environment(\.dismiss) var dismiss
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let p = UIImagePickerController(); p.sourceType = .camera; p.delegate = context.coordinator; return p
    }
    func updateUIViewController(_ vc: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        init(_ p: CameraView) { self.parent = p }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage { parent.onCapture(image) }
            parent.dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.dismiss() }
    }
}
