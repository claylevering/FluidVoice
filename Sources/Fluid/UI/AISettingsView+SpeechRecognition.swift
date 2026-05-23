//
//  AISettingsView+SpeechRecognition.swift
//  fluid
//
//  Extracted from AISettingsView.swift to keep view body under lint limit.
//

import SwiftUI

extension VoiceEngineSettingsView {
    // MARK: - Speech Recognition Card

    var speechRecognitionCard: some View {
        return ThemedCard(hoverEffect: false) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 16) {
                    HStack(spacing: 10) {
                        Image(systemName: "waveform")
                            .font(.title2)
                            .foregroundStyle(self.theme.palette.accent)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Dictation")
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text("Choose a voice engine or control filler-word cleanup.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer(minLength: 16)

                    Picker("", selection: self.$selectedTab) {
                        ForEach(VoiceEngineSettingsView.DictationTab.allCases) { tab in
                            Text(tab.title).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 392, alignment: .trailing)
                }

                Group {
                    switch self.selectedTab {
                    case .voiceEngine:
                        self.voiceEngineSelectionContent
                    case .fillerWords:
                        self.fillerWordsManagementContent
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .padding(14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var voiceEngineSelectionContent: some View {
        return ScrollView(.vertical, showsIndicators: false) {
            self.dictationPrimaryPanel {
                HStack(spacing: 10) {
                    Text("Preview a row, then activate the model you want to use for dictation.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer(minLength: 12)

                    self.toolbarMenu(
                        title: "Filter",
                        value: self.viewModel.providerFilter.rawValue,
                        icon: "line.3.horizontal.decrease.circle"
                    ) {
                        ForEach(SpeechProviderFilter.allCases) { option in
                            Button(option.rawValue) {
                                self.viewModel.providerFilter = option
                            }
                        }
                    }

                    self.toolbarMenu(title: "Sort", value: self.viewModel.modelSortOption.rawValue) {
                        ForEach(ModelSortOption.allCases) { option in
                            Button(option.rawValue) {
                                self.viewModel.modelSortOption = option
                            }
                        }
                    }
                }

                Divider().opacity(0.3)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Models")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    VStack(spacing: 8) {
                        ForEach(self.viewModel.filteredSpeechModels) { model in
                            self.speechModelCard(for: model)
                        }
                    }
                }
            }
        }
    }

    private var fillerWordsManagementContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            self.dictationPrimaryPanel {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Filler-word cleanup")
                        .font(.title3.weight(.semibold))
                    Text("Remove spoken fillers before text is inserted, and tune the exact list FluidVoice should ignore.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Divider().opacity(0.3)

                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Example")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text("\"um I think we should ship this\"")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        Text("\"I think we should ship this\"")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(self.theme.palette.accent)
                    }

                    Spacer()
                }

                Divider().opacity(0.3)

                self.fillerWordsSection
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// Expanded preview panel shown inside the selected model row
    func modelStatsPanel(for model: SettingsStore.SpeechModel) -> some View {
        let supportsCustomWords = model.supportsCustomVocabulary

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(model.humanReadableName)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(self.theme.palette.primaryText)

                            if let badge = model.badgeText {
                                Text(badge)
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(badge == "FluidVoice Pick" ? .cyan.opacity(0.2) : .orange.opacity(0.2)))
                                    .foregroundStyle(badge == "FluidVoice Pick" ? .cyan : .orange)
                            }

                            Spacer()
                        }

                        Text(model.cardDescription)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 8) {
                            self.metadataChip(label: model.downloadSize, icon: "internaldrive")

                            if model.requiresAppleSilicon {
                                self.metadataChip(label: "Apple Silicon", tint: self.theme.palette.accent)
                            }

                            self.metadataChip(label: model.languageSupport)
                            Spacer(minLength: 0)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            self.metadataChip(label: model.downloadSize, icon: "internaldrive")

                            if model.requiresAppleSilicon {
                                self.metadataChip(label: "Apple Silicon", tint: self.theme.palette.accent)
                            }

                            self.metadataChip(label: model.languageSupport)
                        }
                    }

                    // Memory warning for large models
                    if let memoryWarning = model.memoryWarning {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                            Text(memoryWarning)
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.orange.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(.orange.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 10) {
                    self.compactMetric(label: "Speed", value: model.speedPercent, tint: .yellow, icon: "bolt.fill")
                    self.compactMetric(label: "Accuracy", value: model.accuracyPercent, tint: self.theme.palette.accent, icon: "target")
                }
                .frame(width: 190, alignment: .leading)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: model.id)
            }

            if supportsCustomWords {
                HStack(alignment: .center, spacing: 10) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundStyle(Color.fluidGreen)

                    Text("Custom Words supported on Parakeet. Teach names, product terms, and uncommon words for better accuracy.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)

                    Spacer(minLength: 8)

                    Button("Open Custom Dictionary") {
                        NotificationCenter.default.post(name: .openCustomDictionaryFromVoiceEngine, object: nil)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.fluidGreen.opacity(0.10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.fluidGreen.opacity(0.30), lineWidth: 1)
                        )
                )
            }
        }
        .padding(.vertical, 6)
    }

    func speechModelCard(for model: SettingsStore.SpeechModel) -> some View {
        let isSelected = self.viewModel.previewSpeechModel == model
        let isConfiguredActive = self.viewModel.isActiveSpeechModel(model)
        let isActive = isConfiguredActive && model.isInstalled

        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(isSelected ? self.theme.palette.accent : self.theme.palette.cardBorder.opacity(0.28))
                    .frame(width: 4, height: 44)

                self.speechModelLogoView(for: model)
                    .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(model.humanReadableName)
                            .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                            .foregroundStyle(self.theme.palette.primaryText)

                        if let badge = model.badgeText {
                            Text(badge)
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule().fill(
                                        badge == "FluidVoice Pick" ? .cyan.opacity(0.16) : .orange.opacity(0.16)
                                    )
                                )
                                .foregroundStyle(badge == "FluidVoice Pick" ? .cyan : .orange)
                        }
                    }

                    Text(self.speechModelSubtitle(for: model))
                        .font(.caption)
                        .foregroundStyle(.secondary.opacity(0.7))

                    HStack(spacing: 8) {
                        self.metadataChip(label: "Speed \(Int(model.speedPercent * 100))%", tint: .yellow, icon: "bolt.fill")
                        self.metadataChip(label: "Acc \(Int(model.accuracyPercent * 100))%", tint: self.theme.palette.accent, icon: "target")

                        if isActive {
                            self.metadataChip(label: "Active", tint: Color.fluidGreen)
                        } else if isSelected {
                            self.metadataChip(label: "Previewing")
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if self.viewModel.downloadingModel == model {
                    VStack(alignment: .trailing, spacing: 4) {
                        if self.viewModel.downloadProgress >= 0.82 {
                            HStack(spacing: 6) {
                                ProgressView()
                                    .controlSize(.mini)
                                Text("Finalizing…")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            ProgressView(value: self.viewModel.downloadProgress)
                                .progressViewStyle(.linear)
                                .frame(width: 90)
                            Text("\(Int(self.viewModel.downloadProgress * 100))%")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else if (self.viewModel.asr.isDownloadingModel || self.viewModel.asr.isLoadingModel) && isConfiguredActive && !self.viewModel.asr.isAsrReady {
                    VStack(alignment: .trailing, spacing: 4) {
                        if let progress = self.viewModel.asr.downloadProgress, self.viewModel.asr.isDownloadingModel {
                            if progress >= 0.82 {
                                HStack(spacing: 6) {
                                    ProgressView()
                                        .controlSize(.mini)
                                    Text("Finalizing…")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            } else {
                                ProgressView(value: progress)
                                    .progressViewStyle(.linear)
                                    .frame(width: 90)
                                Text("\(Int(progress * 100))%")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            ProgressView()
                                .controlSize(.mini)
                            Text(self.viewModel.asr.isLoadingModel ? "Loading…" : "Downloading…")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else if model.isInstalled {
                    HStack(spacing: 8) {
                        if isConfiguredActive {
                            let isLoading = (self.viewModel.asr.isLoadingModel || self.viewModel.asr.isDownloadingModel) && !self.viewModel.asr.isAsrReady
                            self.speechModelLanguagePicker(for: model)
                                .disabled(self.viewModel.asr.isRunning)

                            Text(isLoading ? "Loading…" : "Active")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(isLoading ? .orange.opacity(0.25) : Color.fluidGreen.opacity(0.25)))
                                .foregroundStyle(isLoading ? .orange : Color.fluidGreen)
                        } else {
                            Button("Activate") {
                                self.viewModel.activateSpeechModel(model)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .tint(Color.fluidGreen)
                            .disabled(self.viewModel.asr.isRunning || self.viewModel.downloadingModel != nil)
                        }

                        if !model.usesAppleLogo, isSelected {
                            Button {
                                self.viewModel.deleteSpeechModel(model)
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 15))
                                    .foregroundStyle(.red.opacity(0.7))
                            }
                            .buttonStyle(.plain)
                            .disabled(self.viewModel.asr.isRunning || self.viewModel.downloadingModel != nil)
                        }
                    }
                } else {
                    ZStack(alignment: .trailing) {
                        if model.requiresExternalArtifacts {
                            HStack(spacing: 8) {
                                if model.externalCoreMLSpec?.sourceURL != nil {
                                    Button {
                                        self.viewModel.openExternalModelSource(for: model)
                                    } label: {
                                        Image(systemName: "arrow.up.right.square")
                                            .font(.system(size: 14))
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundStyle(.secondary)
                                    .disabled(self.viewModel.asr.isRunning || self.viewModel.downloadingModel != nil)
                                }

                                Button("Download") {
                                    self.viewModel.previewSpeechModel = model
                                    self.viewModel.downloadSpeechModel(model)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .tint(.blue)
                                .disabled(self.viewModel.asr.isRunning || self.viewModel.downloadingModel != nil)
                            }
                        } else {
                            if !isSelected {
                                Text("Not downloaded")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }

                            if isSelected {
                                Button("Download") {
                                    self.viewModel.previewSpeechModel = model
                                    self.viewModel.downloadSpeechModel(model)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .tint(.blue)
                                .disabled(self.viewModel.asr.isRunning || self.viewModel.downloadingModel != nil)
                            }
                        }
                    }
                    .frame(width: model.requiresExternalArtifacts ? 150 : 120, alignment: .trailing)
                }
            }

            if isSelected {
                Divider()
                    .opacity(0.3)
                    .padding(.top, 10)
                    .padding(.bottom, 12)

                self.modelStatsPanel(for: model)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? self.theme.palette.contentBackground.opacity(0.72) : self.theme.palette.contentBackground.opacity(0.22))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? self.theme.palette.accent.opacity(0.35) : self.theme.palette.cardBorder.opacity(0.2), lineWidth: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isActive ? Color.fluidGreen.opacity(0.55) : .clear, lineWidth: 1.5)
                )
        )
        .onTapGesture {
            self.viewModel.previewSpeechModel = model
        }
        .opacity(self.viewModel.asr.isRunning ? 0.6 : 1.0)
        .allowsHitTesting(!self.viewModel.asr.isRunning)
    }

    @ViewBuilder
    private func speechModelLanguagePicker(for model: SettingsStore.SpeechModel) -> some View {
        if model == .cohereTranscribeSixBit {
            Menu {
                ForEach(SettingsStore.CohereLanguage.allCases) { language in
                    Button {
                        guard language != self.settings.selectedCohereLanguage else { return }
                        self.settings.selectedCohereLanguage = language
                    } label: {
                        HStack {
                            Text(language.displayName)
                            if language == self.settings.selectedCohereLanguage {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                self.languageChipLabel(self.settings.selectedCohereLanguage.displayName)
            }
            .buttonStyle(.plain)
        } else if model == .nemotronOffline || model == .nemotronStreaming || model == .nemotronStreaming320 {
            self.nemotronLanguagePickerButton
        }
    }

    private func languageChipLabel(_ title: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: "globe")
                .font(.caption2)
                .foregroundStyle(self.theme.palette.accent)
            Text(title)
                .lineLimit(1)
                .fontWeight(.semibold)
            Image(systemName: "chevron.down")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .font(.caption2)
        .frame(minHeight: 24)
        .padding(.horizontal, 9)
        .background(
            Capsule()
                .fill(self.theme.palette.accent.opacity(0.10))
                .overlay(
                    Capsule()
                        .stroke(self.theme.palette.accent.opacity(0.28), lineWidth: 1)
                )
        )
    }

    private func speechModelSubtitle(for model: SettingsStore.SpeechModel) -> String {
        switch model {
        case .nemotronStreaming, .nemotronStreaming320:
            return "Nemotron Speech 3.5 - Streaming Capable"
        default:
            return model.displayName
        }
    }

    private var nemotronLanguagePickerButton: some View {
        Button {
            self.isShowingNemotronLanguagePicker.toggle()
        } label: {
            self.languageChipLabel(self.settings.selectedNemotronLanguage.compactDisplayName)
        }
        .buttonStyle(.plain)
        .popover(isPresented: self.$isShowingNemotronLanguagePicker, arrowEdge: .bottom) {
            self.nemotronLanguagePickerPopover
        }
    }

    private var nemotronLanguagePickerPopover: some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(SettingsStore.NemotronLanguage.allCases) { language in
                    Button {
                        self.settings.selectedNemotronLanguage = language
                        self.isShowingNemotronLanguagePicker = false
                    } label: {
                        HStack(spacing: 8) {
                            Text(language.displayName)
                                .font(.caption)
                                .foregroundStyle(.primary)
                            Spacer(minLength: 12)
                            if language == self.settings.selectedNemotronLanguage {
                                Image(systemName: "checkmark")
                                    .font(.caption)
                                    .foregroundStyle(self.theme.palette.accent)
                            }
                        }
                        .contentShape(Rectangle())
                        .padding(.horizontal, 12)
                        .frame(height: 26)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 6)
        }
        .frame(width: 260, height: 532)
    }

    var modelStatusView: some View {
        HStack(spacing: 12) {
            if (self.viewModel.asr.isDownloadingModel || self.viewModel.asr.isLoadingModel) && !self.viewModel.asr.isAsrReady {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small).fixedSize()
                    if self.viewModel.asr.isDownloadingModel,
                       let progress = self.viewModel.asr.downloadProgress,
                       progress >= 0.82
                    {
                        Text("Finalizing download and loading model…")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(self.viewModel.asr.isLoadingModel ? "Loading model…" : "Downloading…")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } else if self.viewModel.asr.isAsrReady {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.fluidGreen).font(.caption)
                Text("Ready").font(.caption).foregroundStyle(.secondary)

                Button(action: { Task { await self.viewModel.deleteModels() } }) {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                        Text("Delete")
                    }
                    .font(.caption)
                    .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            } else if self.viewModel.asr.modelsExistOnDisk {
                Image(systemName: "doc.fill").foregroundStyle(self.theme.palette.accent).font(.caption)
                Text("Cached")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button(action: { Task { await self.viewModel.deleteModels() } }) {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                        Text("Delete")
                    }
                    .font(.caption)
                    .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            } else {
                HStack(spacing: 8) {
                    if self.settings.selectedSpeechModel.requiresExternalArtifacts,
                       self.settings.selectedSpeechModel.externalCoreMLSpec?.sourceURL != nil
                    {
                        Button(action: { self.viewModel.openExternalModelSource(for: self.settings.selectedSpeechModel) }) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up.right.square")
                                Text("Hugging Face")
                            }
                            .font(.caption)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(self.theme.palette.accent)
                    }

                    Button(action: { Task { await self.viewModel.downloadModels() } }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.circle.fill")
                            Text("Download")
                        }
                        .font(.caption)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .tint(.blue)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 8)
            .fill(self.theme.palette.cardBackground.opacity(0.8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(self.theme.palette.cardBorder.opacity(0.5), lineWidth: 1)))
    }

    var fillerWordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Remove filler words")
                        .font(.body.weight(.semibold))
                    Text("Automatically remove filler sounds like 'um', 'uh', 'er' from transcriptions")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Toggle("", isOn: self.$viewModel.removeFillerWordsEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .onChange(of: self.viewModel.removeFillerWordsEnabled) { _, newValue in
                        self.settings.removeFillerWordsEnabled = newValue
                    }
            }

            if self.viewModel.removeFillerWordsEnabled {
                FillerWordsEditor()
            }
        }
    }

    private func dictationPrimaryPanel<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            content()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(self.theme.palette.cardBackground.opacity(0.88))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(self.theme.palette.cardBorder.opacity(0.28), lineWidth: 1)
                )
        )
    }

    private func toolbarMenu<Content: View>(
        title: String,
        value: String,
        icon: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Menu {
            content()
        } label: {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text("\(title): \(value)")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(self.theme.palette.contentBackground.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .stroke(self.theme.palette.cardBorder.opacity(0.35), lineWidth: 1)
                    )
            )
        }
    }

    private func metadataChip(label: String, tint: Color? = nil, icon: String? = nil) -> some View {
        HStack(spacing: 5) {
            if let icon {
                Image(systemName: icon)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(tint ?? .secondary)
            }

            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(tint ?? .secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill((tint ?? self.theme.palette.contentBackground).opacity(tint == nil ? 0.55 : 0.14))
        )
    }

    private func compactMetric(label: String, value: Double, tint: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(tint)
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(value * 100))%")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(self.theme.palette.contentBackground.opacity(0.7))

                    Capsule()
                        .fill(tint.opacity(0.9))
                        .frame(width: max(16, geometry.size.width * value))
                }
            }
            .frame(height: 8)
        }
    }

    // MARK: - Speech Model Logo View

    private func speechModelLogoView(for model: SettingsStore.SpeechModel) -> some View {
        let bgColor = self.speechModelBackgroundColor(for: model)
        let imageName = self.speechModelImageName(for: model)
        let isNvidia = model.brandName.lowercased().contains("nvidia")

        return ZStack {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(bgColor)

            if model.usesAppleLogo {
                Image(systemName: "apple.logo")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)
            } else if let imageName {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    // NVIDIA logo larger to fill more of the container
                    .frame(width: isNvidia ? 24 : 18, height: isNvidia ? 24 : 18)
            } else {
                Text(String(model.brandName.prefix(2)).uppercased())
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: 28, height: 28)
        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
    }

    private func speechModelBackgroundColor(for model: SettingsStore.SpeechModel) -> Color {
        let brand = model.brandName.lowercased()

        // Both NVIDIA and OpenAI use white/light gray bg (transparent logos)
        if brand.contains("nvidia") || brand.contains("openai") || brand.contains("whisper") {
            return Color(red: 0.97, green: 0.97, blue: 0.97)
        }
        if brand.contains("apple") || model.usesAppleLogo {
            return self.theme.palette.cardBackground.opacity(0.9)
        }
        return Color(hex: model.brandColorHex)?.opacity(0.2) ?? self.theme.palette.cardBackground
    }

    private func speechModelImageName(for model: SettingsStore.SpeechModel) -> String? {
        let brand = model.brandName.lowercased()

        if brand.contains("nvidia") {
            return "Provider_NVIDIA"
        }
        if brand.contains("cohere") {
            return "Provider_Cohere"
        }
        if brand.contains("openai") || brand.contains("whisper") {
            return "Provider_OpenAI"
        }
        return nil
    }
}

extension Notification.Name {
    static let openCustomDictionaryFromVoiceEngine = Notification.Name("OpenCustomDictionaryFromVoiceEngine")
}
