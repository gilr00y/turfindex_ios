//
//  CreatePostView.swift
//  grassy
//
//  Created by jason on 1/14/26.
//

import SwiftUI
import PhotosUI

struct CreatePostView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var caption = ""
    @State private var location = ""
    @State private var tagInput = ""
    @State private var tags: [String] = []
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    // Photo picker
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        if let selectedImageData,
                           let uiImage = UIImage(data: selectedImageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 300)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            Label("Select Photo", systemImage: "photo.on.rectangle.angled")
                                .frame(maxWidth: .infinity)
                                .frame(height: 200)
                                .background(.gray.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                } header: {
                    Text("Photo")
                }
                
                Section {
                    TextField("What's happening?", text: $caption, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Caption")
                }
                
                Section {
                    TextField("Add location", text: $location)
                } header: {
                    Text("Location")
                }
                
                Section {
                    // Tag input
                    HStack {
                        TextField("Add a tag", text: $tagInput)
                            .textInputAutocapitalization(.never)
                            .submitLabel(.done)
                            .onSubmit(addTag)
                        
                        Button(action: addTag) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(TurfTheme.primary)
                        }
                        .disabled(tagInput.isEmpty)
                    }
                    
                    // Display tags
                    if !tags.isEmpty {
                        FlowLayout(spacing: 8) {
                            ForEach(tags, id: \.self) { tag in
                                TagView(tag: tag) {
                                    tags.removeAll { $0 == tag }
                                }
                            }
                        }
                    }
                } header: {
                    Text("Tags")
                }
            }
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    if appState.isLoading {
                        ProgressView()
                    } else {
                        Button("Post") {
                            createPost()
                        }
                        .disabled(selectedImageData == nil)
                    }
                }
            }
            .onChange(of: selectedPhoto) { oldValue, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                        selectedImageData = data
                    }
                }
            }
        }
    }
    
    private func addTag() {
        let trimmed = tagInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !tags.contains(trimmed) else { return }
        tags.append(trimmed)
        tagInput = ""
    }
    
    private func createPost() {
        print("🎬 CREATE POST: Starting...")
        
        guard let imageData = selectedImageData else {
            print("❌ CREATE POST: No image data selected")
            return
        }
        
        print("✅ CREATE POST: Image data size: \(imageData.count) bytes")
        
        guard let uiImage = UIImage(data: imageData) else {
            print("❌ CREATE POST: Failed to create UIImage from data")
            return
        }
        
        print("✅ CREATE POST: UIImage created - Size: \(uiImage.size)")
        print("📝 CREATE POST: Caption: '\(caption)'")
        print("📍 CREATE POST: Location: '\(location)'")
        print("🏷️ CREATE POST: Tags: \(tags)")
        
        Task {
            print("🔄 CREATE POST: Starting compression...")
            
            // Compress image before upload
            guard let compressedData = ImageHelper.prepareForUpload(uiImage) else {
                print("❌ CREATE POST: Image compression failed")
                return
            }
            
            print("✅ CREATE POST: Compressed to \(compressedData.count) bytes")
            print("📊 CREATE POST: Compression ratio: \(Double(compressedData.count) / Double(imageData.count) * 100)%")
            
            print("🚀 CREATE POST: Calling appState.createPost()...")
            
            await appState.createPost(
                caption: caption,
                location: location,
                tags: tags,
                imageData: compressedData
            )
            
            if let error = appState.error {
                print("❌ CREATE POST: Error occurred: \(error.localizedDescription)")
                print("📋 CREATE POST: Full error: \(error)")
            } else {
                print("✅ CREATE POST: Success! Post created")
                print("🎉 CREATE POST: Dismissing view...")
                dismiss()
            }
        }
    }
}

/// Simple tag view with delete button
struct TagView: View {
    let tag: String
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text("#\(tag)")
                .font(.subheadline)
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(TurfTheme.limeGreen.opacity(0.15))
        .foregroundStyle(TurfTheme.forestGreen)
        .clipShape(Capsule())
    }
}

/// Simple flow layout for tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0
        
        var lineWidth: CGFloat = 0
        var lineHeight: CGFloat = 0
        
        for size in sizes {
            if lineWidth + size.width > proposal.width ?? 0 {
                totalHeight += lineHeight + spacing
                lineWidth = size.width
                lineHeight = size.height
            } else {
                lineWidth += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }
            totalWidth = max(totalWidth, lineWidth)
        }
        totalHeight += lineHeight
        
        return CGSize(width: totalWidth, height: totalHeight)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var lineX = bounds.minX
        var lineY = bounds.minY
        var lineHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if lineX + size.width > bounds.maxX && lineX > bounds.minX {
                lineY += lineHeight + spacing
                lineHeight = 0
                lineX = bounds.minX
            }
            
            subview.place(at: CGPoint(x: lineX, y: lineY), proposal: .unspecified)
            
            lineHeight = max(lineHeight, size.height)
            lineX += size.width + spacing
        }
    }
}

#Preview {
    CreatePostView()
        .environment(AppState())
}
