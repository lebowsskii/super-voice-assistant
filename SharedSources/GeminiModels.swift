import Foundation

/// Model names used for the Gemini API.
///
/// Google closes older models to new API keys without warning - `gemini-2.5-flash`
/// started returning 404 ("no longer available to new users") for freshly created
/// keys, which silently broke transcription, video and TTS at once. Keeping the
/// names here means the next migration is one edit, and `.env` can override them
/// without a rebuild.
///
/// Note: `tools/transcribe-video` carries its own copy because it is built without
/// dependencies. Update it too when these change.
public enum GeminiModels {

    /// Model for `generateContent` requests: audio and video transcription.
    /// Fixed — fastest and most consistent of the models benchmarked
    /// (see docs/superpowers/specs/2026-08-16-todo-followups-design.md).
    /// No .env override: tools/transcribe-video keeps its own copy and its
    /// own GEMINI_MODEL handling, out of scope here.
    public static let generateContent = "gemini-3.1-flash-lite"

    /// Model for the Live API (WebSocket) used by streaming text-to-speech.
    /// Override with GEMINI_LIVE_MODEL in .env
    ///
    /// Pinned to the `-latest` alias rather than a dated preview: the dated
    /// preview this replaced is exactly what disappeared, and no 3.x native
    /// audio model is offered.
    public static var liveAudio: String {
        ProcessInfo.processInfo.environment["GEMINI_LIVE_MODEL"] ?? "gemini-2.5-flash-native-audio-latest"
    }
}
