import SwiftUI
import UniformTypeIdentifiers
import PhotosUI
import UIKit

@MainActor final class DiskStore<T: CheckedData>: ObservableObject {
    @Published var data: T { didSet { save() } }
    @Published var error: String?
    private let url: URL
    private var canSave = true
    init(_ initial: T, filename: String) {
        url = URL.applicationSupportDirectory.appending(path: filename)
        if FileManager.default.fileExists(atPath: url.path) {
            do { data = try LocalJSON.decode(T.self, from: Data(contentsOf: url)) }
            catch { data = initial; canSave = false; self.error = "Could not load saved data. Original file preserved. Import a valid backup to recover. \(error.localizedDescription)" }
        } else { data = initial }
    }
    func save() {
        guard canSave else { return }
        do { try LocalJSON.save(data, to: url) } catch { self.error = error.localizedDescription }
    }
    func restore(_ bytes: Data) throws {
        let restored = try LocalJSON.decode(T.self, from: bytes)
        try LocalJSON.save(restored, to: url)
        canSave = true; data = restored
    }
}
struct JSONDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var bytes: Data
    init(bytes: Data) { self.bytes = bytes }
    init(configuration: ReadConfiguration) throws { bytes = configuration.file.regularFileContents ?? Data() }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: bytes) }
}
struct BackupControls<T: CheckedData>: View {
    @ObservedObject var store: DiskStore<T>
    let filename: String
    var afterImport: () -> Void = {}
    @State private var exporting = false
    @State private var importing = false
    @State private var confirm = false
    @State private var document = JSONDocument(bytes: Data())
    var body: some View {
        Button("Export JSON backup", systemImage: "square.and.arrow.up") {
            do { document = JSONDocument(bytes: try LocalJSON.encode(store.data)); exporting = true }
            catch { store.error = error.localizedDescription }
        }
        Button("Import JSON backup", systemImage: "square.and.arrow.down") { confirm = true }
            .confirmationDialog("Replace this app's data with a backup?", isPresented: $confirm) {
                Button("Choose backup", role: .destructive) { importing = true }
            }
            .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
                do {
                    let url = try result.get()
                    let access = url.startAccessingSecurityScopedResource()
                    defer { if access { url.stopAccessingSecurityScopedResource() } }
                    let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                    guard size < 30_000_000 else { throw DataIssue.invalid("Backup exceeds 30 MB.") }
                    try store.restore(Data(contentsOf: url)); afterImport()
                } catch { store.error = error.localizedDescription }
            }
            .fileExporter(isPresented: $exporting, document: document, contentType: .json, defaultFilename: filename) { result in
                if case .failure(let error) = result { store.error = error.localizedDescription }
            }
    }
}
struct PhotoControl: View {
    @Binding var data: Data?
    var label = "Choose image"
    @State private var selection: PhotosPickerItem?
    @State private var error: String?
    var body: some View {
        PhotosPicker(selection: $selection, matching: .images) { Label(label, systemImage: "photo") }
            .onChange(of: selection) { _, item in
                Task {
                    do {
                        guard let bytes = try await item?.loadTransferable(type: Data.self), let image = UIImage(data: bytes) else { throw DataIssue.invalid("Could not read this photo.") }
                        let scale = min(1, 1000 / max(image.size.width, image.size.height))
                        let size = CGSize(width: image.size.width*scale, height: image.size.height*scale)
                        let format = UIGraphicsImageRendererFormat(); format.scale = 1
                        data = UIGraphicsImageRenderer(size: size, format: format).image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }.jpegData(compressionQuality: 0.8)
                    } catch { self.error = error.localizedDescription }
                }
            }
            .alert("Photo unavailable", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) { Button("OK") { error = nil } } message: { Text(error ?? "") }
    }
}
struct LocalImage: View {
    var data: Data?
    var symbol = "person.crop.circle.fill"
    var body: some View {
        Group {
            if let data, let image = UIImage(data: data) { Image(uiImage: image).resizable().scaledToFill() }
            else { ZStack { Color.accentColor.opacity(0.13); Image(systemName: symbol).resizable().scaledToFit().padding(14).foregroundStyle(Color.accentColor) } }
        }.clipped()
    }
}
extension View {
    func errorAlert(_ error: Binding<String?>) -> some View {
        alert("Something needs attention", isPresented: Binding(get: { error.wrappedValue != nil }, set: { if !$0 { error.wrappedValue = nil } })) {
            Button("OK") { error.wrappedValue = nil }
        } message: { Text(error.wrappedValue ?? "") }
    }
    func card() -> some View {
        padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.primary.opacity(0.07)))
    }
}
func compact(_ value: Double) -> String {
    value.formatted(.number.notation(.compactName).precision(.fractionLength(0...1)))
}
