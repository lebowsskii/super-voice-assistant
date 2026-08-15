import Foundation
import AVFoundation
import SharedModels

/// Transcribes an audio file with Parakeet, exercising the same ParakeetTranscriber
/// wrapper the main app uses. Handy for checking the FluidAudio integration after
/// a dependency upgrade, without having to launch the app and speak into a mic.
///
/// Usage: swift run TestParakeet [path-to-audio] [v2|v3]
///        defaults to test_audio.wav and v2

private let sampleRate: Double = 16000

/// Load an audio file and convert it to the 16kHz mono float samples Parakeet expects
func loadAudioSamples(from url: URL) throws -> [Float] {
    let file = try AVAudioFile(forReading: url)

    guard let targetFormat = AVAudioFormat(
        commonFormat: .pcmFormatFloat32,
        sampleRate: sampleRate,
        channels: 1,
        interleaved: false
    ) else {
        throw NSError(domain: "TestParakeet", code: 1,
                      userInfo: [NSLocalizedDescriptionKey: "Failed to create 16kHz mono format"])
    }

    guard let converter = AVAudioConverter(from: file.processingFormat, to: targetFormat) else {
        throw NSError(domain: "TestParakeet", code: 2,
                      userInfo: [NSLocalizedDescriptionKey: "Failed to create audio converter"])
    }

    // Read the whole file, then convert it in one pass
    guard let inputBuffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat,
                                             frameCapacity: AVAudioFrameCount(file.length)) else {
        throw NSError(domain: "TestParakeet", code: 3,
                      userInfo: [NSLocalizedDescriptionKey: "Failed to allocate input buffer"])
    }
    try file.read(into: inputBuffer)

    let ratio = sampleRate / file.processingFormat.sampleRate
    let outputCapacity = AVAudioFrameCount(Double(inputBuffer.frameLength) * ratio) + 1024
    guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: outputCapacity) else {
        throw NSError(domain: "TestParakeet", code: 4,
                      userInfo: [NSLocalizedDescriptionKey: "Failed to allocate output buffer"])
    }

    var consumed = false
    var conversionError: NSError?
    converter.convert(to: outputBuffer, error: &conversionError) { _, status in
        if consumed {
            status.pointee = .noDataNow
            return nil
        }
        consumed = true
        status.pointee = .haveData
        return inputBuffer
    }

    if let conversionError {
        throw conversionError
    }

    guard let channelData = outputBuffer.floatChannelData?[0] else {
        throw NSError(domain: "TestParakeet", code: 5,
                      userInfo: [NSLocalizedDescriptionKey: "Converted buffer has no samples"])
    }

    return Array(UnsafeBufferPointer(start: channelData, count: Int(outputBuffer.frameLength)))
}

func run() async {
    let arguments = CommandLine.arguments

    let audioPath = arguments.count > 1
        ? arguments[1]
        : FileManager.default.currentDirectoryPath + "/test_audio.wav"

    let version: ParakeetVersion = (arguments.count > 2 && arguments[2] == "v3") ? .v3 : .v2

    let audioURL = URL(fileURLWithPath: audioPath)
    guard FileManager.default.fileExists(atPath: audioURL.path) else {
        print("❌ Audio file not found: \(audioURL.path)")
        print("Usage: swift run TestParakeet [path-to-audio] [v2|v3]")
        exit(1)
    }

    print("🎧 Audio:  \(audioURL.lastPathComponent)")
    print("🧠 Model:  \(version.displayName) (\(version.languages), \(version.speed))")
    print("📁 Cache:  \(version.modelDirectory.path)")
    print("           \(version.isDownloaded ? "already downloaded" : "not downloaded yet")")
    print("")

    let samples: [Float]
    do {
        samples = try loadAudioSamples(from: audioURL)
    } catch {
        print("❌ Failed to load audio: \(error.localizedDescription)")
        exit(1)
    }

    let duration = Double(samples.count) / sampleRate
    print("Loaded \(samples.count) samples (\(String(format: "%.2f", duration))s at 16kHz mono)")

    let transcriber = ParakeetTranscriber()

    do {
        print("Loading model (downloads on first run, ~600MB)...")
        let loadStart = Date()
        try await transcriber.loadModel(version: version)
        print("Model ready in \(String(format: "%.2f", Date().timeIntervalSince(loadStart)))s")

        guard await transcriber.isReady else {
            print("❌ Transcriber reports it is not ready after loading")
            exit(1)
        }

        let transcribeStart = Date()
        let text = try await transcriber.transcribe(audioSamples: samples)
        let elapsed = Date().timeIntervalSince(transcribeStart)

        print("")
        print("✅ Transcription (\(String(format: "%.2f", elapsed))s, \(String(format: "%.0f", duration / elapsed))x realtime):")
        print("")
        print(text)
        print("")

        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            print("⚠️  Transcription is empty - something is wrong with the integration")
            exit(1)
        }
    } catch {
        print("❌ \(error.localizedDescription)")
        exit(1)
    }
}

await run()
