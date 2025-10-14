import SwiftUI

struct SettingsView: View {
    @AppStorage("openai_api_key") private var openaiApiKey: String = ""

    // Keyboard shortcut storage
    @AppStorage("shortcut_save_text_key") private var saveTextKey: String = "s"
    @AppStorage("shortcut_save_text_cmd") private var saveTextCmd: Bool = true
    @AppStorage("shortcut_save_text_opt") private var saveTextOpt: Bool = false
    @AppStorage("shortcut_save_text_shift") private var saveTextShift: Bool = true

    @AppStorage("shortcut_area_screenshot_key") private var areaScreenshotKey: String = "a"
    @AppStorage("shortcut_area_screenshot_cmd") private var areaScreenshotCmd: Bool = true
    @AppStorage("shortcut_area_screenshot_opt") private var areaScreenshotOpt: Bool = false
    @AppStorage("shortcut_area_screenshot_shift") private var areaScreenshotShift: Bool = true

    @AppStorage("shortcut_full_screenshot_key") private var fullScreenshotKey: String = "f"
    @AppStorage("shortcut_full_screenshot_cmd") private var fullScreenshotCmd: Bool = true
    @AppStorage("shortcut_full_screenshot_opt") private var fullScreenshotOpt: Bool = false
    @AppStorage("shortcut_full_screenshot_shift") private var fullScreenshotShift: Bool = true

    @AppStorage("shortcut_generate_embeddings_key") private var generateEmbeddingsKey: String = "e"
    @AppStorage("shortcut_generate_embeddings_cmd") private var generateEmbeddingsCmd: Bool = true
    @AppStorage("shortcut_generate_embeddings_opt") private var generateEmbeddingsOpt: Bool = false
    @AppStorage("shortcut_generate_embeddings_shift") private var generateEmbeddingsShift: Bool = false

    @AppStorage("shortcut_regenerate_embedding_key") private var regenerateEmbeddingKey: String = "r"
    @AppStorage("shortcut_regenerate_embedding_cmd") private var regenerateEmbeddingCmd: Bool = true
    @AppStorage("shortcut_regenerate_embedding_opt") private var regenerateEmbeddingOpt: Bool = false
    @AppStorage("shortcut_regenerate_embedding_shift") private var regenerateEmbeddingShift: Bool = false

    @AppStorage("shortcut_delete_entry_key") private var deleteEntryKey: String = "Delete"
    @AppStorage("shortcut_delete_entry_cmd") private var deleteEntryCmd: Bool = false
    @AppStorage("shortcut_delete_entry_opt") private var deleteEntryOpt: Bool = false
    @AppStorage("shortcut_delete_entry_shift") private var deleteEntryShift: Bool = false

    @AppStorage("shortcut_next_entry_key") private var nextEntryKey: String = "↓"
    @AppStorage("shortcut_next_entry_cmd") private var nextEntryCmd: Bool = false
    @AppStorage("shortcut_next_entry_opt") private var nextEntryOpt: Bool = false
    @AppStorage("shortcut_next_entry_shift") private var nextEntryShift: Bool = false

    @AppStorage("shortcut_previous_entry_key") private var previousEntryKey: String = "↑"
    @AppStorage("shortcut_previous_entry_cmd") private var previousEntryCmd: Bool = false
    @AppStorage("shortcut_previous_entry_opt") private var previousEntryOpt: Bool = false
    @AppStorage("shortcut_previous_entry_shift") private var previousEntryShift: Bool = false

    @State private var selectedTab = 0

    let availableKeys = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "Delete", "Space", "Return", "Escape", "Tab", "↑", "↓", "←", "→", "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12"]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.semibold)

                VStack(alignment: .leading, spacing: 16) {
                    Text("OpenAI API Configuration")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("API Key")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        SecureField("Enter your OpenAI API key", text: $openaiApiKey)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: .infinity)

                        Text("Required for embeddings and image transcription. Get your API key from openai.com")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 16) {
                    Text("Keyboard Shortcuts")
                        .font(.headline)

                VStack(alignment: .leading, spacing: 12) {
                    Group {
                        advancedShortcutRow(
                            title: "Save Highlighted Text",
                            description: "Save selected text from any application",
                            icon: "text.cursor",
                            key: $saveTextKey,
                            cmd: $saveTextCmd,
                            opt: $saveTextOpt,
                            shift: $saveTextShift
                        )

                        advancedShortcutRow(
                            title: "Capture Selected Area",
                            description: "Click and drag to capture screen area",
                            icon: "viewfinder",
                            key: $areaScreenshotKey,
                            cmd: $areaScreenshotCmd,
                            opt: $areaScreenshotOpt,
                            shift: $areaScreenshotShift
                        )

                        advancedShortcutRow(
                            title: "Capture Full Screen",
                            description: "Capture the entire screen",
                            icon: "camera",
                            key: $fullScreenshotKey,
                            cmd: $fullScreenshotCmd,
                            opt: $fullScreenshotOpt,
                            shift: $fullScreenshotShift
                        )
                    }

                    Divider()
                        .padding(.vertical, 8)

                    Group {
                        advancedShortcutRow(
                            title: "Generate Embeddings",
                            description: "Generate embeddings for all entries",
                            icon: "brain.head.profile",
                            key: $generateEmbeddingsKey,
                            cmd: $generateEmbeddingsCmd,
                            opt: $generateEmbeddingsOpt,
                            shift: $generateEmbeddingsShift
                        )

                        advancedShortcutRow(
                            title: "Regenerate Embedding",
                            description: "Regenerate embedding for selected entry",
                            icon: "arrow.clockwise",
                            key: $regenerateEmbeddingKey,
                            cmd: $regenerateEmbeddingCmd,
                            opt: $regenerateEmbeddingOpt,
                            shift: $regenerateEmbeddingShift
                        )

                        advancedShortcutRow(
                            title: "Delete Entry",
                            description: "Delete the selected entry",
                            icon: "trash",
                            key: $deleteEntryKey,
                            cmd: $deleteEntryCmd,
                            opt: $deleteEntryOpt,
                            shift: $deleteEntryShift
                        )

                        advancedShortcutRow(
                            title: "Next Entry",
                            description: "Select next entry in list",
                            icon: "arrow.down",
                            key: $nextEntryKey,
                            cmd: $nextEntryCmd,
                            opt: $nextEntryOpt,
                            shift: $nextEntryShift
                        )

                        advancedShortcutRow(
                            title: "Previous Entry",
                            description: "Select previous entry in list",
                            icon: "arrow.up",
                            key: $previousEntryKey,
                            cmd: $previousEntryCmd,
                            opt: $previousEntryOpt,
                            shift: $previousEntryShift
                        )
                    }
                }
            }

            Spacer()

            VStack(spacing: 8) {
                Text("✨ Using Apple's Natural Language framework for on-device embeddings")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Text("All data stored locally in Core Data - no external API required")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Button("Go to Ledger Tab") {
                    // Post notification to change tab
                    NotificationCenter.default.post(name: NSNotification.Name("SwitchToLedgerTab"), object: nil)
                }
                .padding(.top, 8)

                HStack {
                    Button("Reset to Defaults") {
                        // Reset Save Text: Cmd+Shift+S
                        saveTextKey = "s"
                        saveTextCmd = true
                        saveTextOpt = false
                        saveTextShift = true

                        // Reset Area Screenshot: Cmd+Shift+A
                        areaScreenshotKey = "a"
                        areaScreenshotCmd = true
                        areaScreenshotOpt = false
                        areaScreenshotShift = true

                        // Reset Full Screenshot: Cmd+Shift+F
                        fullScreenshotKey = "f"
                        fullScreenshotCmd = true
                        fullScreenshotOpt = false
                        fullScreenshotShift = true

                        // Reset Generate Embeddings: Cmd+E
                        generateEmbeddingsKey = "e"
                        generateEmbeddingsCmd = true
                        generateEmbeddingsOpt = false
                        generateEmbeddingsShift = false

                        // Reset Regenerate Embedding: Cmd+R
                        regenerateEmbeddingKey = "r"
                        regenerateEmbeddingCmd = true
                        regenerateEmbeddingOpt = false
                        regenerateEmbeddingShift = false

                        // Reset Delete Entry: Delete
                        deleteEntryKey = "Delete"
                        deleteEntryCmd = false
                        deleteEntryOpt = false
                        deleteEntryShift = false

                        // Reset Next Entry: Down Arrow
                        nextEntryKey = "↓"
                        nextEntryCmd = false
                        nextEntryOpt = false
                        nextEntryShift = false

                        // Reset Previous Entry: Up Arrow
                        previousEntryKey = "↑"
                        previousEntryCmd = false
                        previousEntryOpt = false
                        previousEntryShift = false
                    }
                    .foregroundColor(.orange)

                    Spacer()
                }
            }
            }
            .padding()
        }
        .frame(width: 650, height: 700)
    }

    private func advancedShortcutRow(
        title: String,
        description: String,
        icon: String,
        key: Binding<String>,
        cmd: Binding<Bool>,
        opt: Binding<Bool>,
        shift: Binding<Bool>
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                // Display current shortcut
                Text(formatShortcut(key: key.wrappedValue, cmd: cmd.wrappedValue, opt: opt.wrappedValue, shift: shift.wrappedValue))
                    .font(.system(size: 12, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(4)
            }

            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                // Key selection
                HStack {
                    Text("Key:")
                        .font(.caption)
                    Picker("Key", selection: key) {
                        ForEach(availableKeys, id: \.self) { keyOption in
                            Text(keyOption).tag(keyOption)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 80)
                }

                // Modifiers
                Toggle("⌘", isOn: cmd)
                    .toggleStyle(.button)
                    .font(.system(size: 14, design: .monospaced))

                Toggle("⌥", isOn: opt)
                    .toggleStyle(.button)
                    .font(.system(size: 14, design: .monospaced))

                Toggle("⇧", isOn: shift)
                    .toggleStyle(.button)
                    .font(.system(size: 14, design: .monospaced))

                Spacer()
            }

            Divider()
        }
        .padding(.vertical, 4)
    }

    private func formatShortcut(key: String, cmd: Bool, opt: Bool, shift: Bool) -> String {
        var result = ""
        if cmd { result += "⌘" }
        if opt { result += "⌥" }
        if shift { result += "⇧" }

        let displayKey = key == "Delete" ? "⌫" : key
        result += displayKey

        return result
    }
}

#Preview {
    SettingsView()
}