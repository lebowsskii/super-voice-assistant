# Claude Development Notes for Super Voice Assistant

## Project Guidelines

- Follow the roadmap and tech choices outlined in README.md

## Background Process Management

- When developing and testing changes, run the app in background using: `swift build && swift run SuperVoiceAssistant` with `run_in_background: true`
- The user has a local shell alias `s` that runs the app from this project: `s='(cd ~/super-voice-assistant && swift run SuperVoiceAssistant)'`
- Keep the app running in background while the user tests functionality
- Only kill and restart the background instance when making code changes that require a fresh build
- Allow the user to continue using the running instance between agent sessions
- The user prefers to keep the app running for continuous testing

### Accessibility permission when launching the app

macOS grants Accessibility to the app that owns the process tree, not to the binary itself.
Launching the app from an agent shell therefore inherits the permission of whatever terminal
hosts the agent - which is usually not the one listed in System Settings.

Without that permission, the failure is silent and misleading:
- global hotkeys still work (KeyboardShortcuts registers them through Carbon, which needs no permission)
- recording, transcription and history all work
- only the synthetic Cmd+V never arrives, so nothing is pasted at the cursor
- the app still prints "✅ Paste command sent" - it never checks `AXIsProcessTrusted()`

To check before blaming the code, run a one-liner that prints `AXIsProcessTrusted()` from the
same shell. If it is false, either grant the host terminal Accessibility access or have the user
launch the app themselves with `s`.

## Git Commit Guidelines

- Never include Claude attribution or Co-Author information in git commits
- Keep commit messages clean and professional without AI-related references

## Completed Features

### Gemini Live TTS Integration

**Status**: ✅ Complete and integrated into main app
**Key Files**:
- `SharedSources/GeminiStreamingPlayer.swift` - Streaming TTS playback engine
- `SharedSources/GeminiAudioCollector.swift` - Audio collection and WebSocket handling
- `SharedSources/SmartSentenceSplitter.swift` - Text processing for optimal speech

**Features**:
- ✅ Cmd+Opt+S keyboard shortcut for reading selected text aloud
- ✅ Sequential streaming for smooth, natural speech with minimal latency
- ✅ Smart sentence splitting for optimal speech flow
- ✅ 15% speed boost via TimePitch effect

### Gemini Audio Transcription

**Status**: ✅ Complete and integrated into main app
**Branch**: `gemini-audio-feature`
**Key Files**:
- `SharedSources/GeminiAudioTranscriber.swift` - Gemini API audio transcription
- `Sources/GeminiAudioRecordingManager.swift` - Audio recording manager for Gemini

**Features**:
- ✅ Cmd+Opt+X keyboard shortcut for Gemini audio recording and transcription
- ✅ Cloud-based transcription using Gemini 2.5 Flash API
- ✅ WAV audio conversion and base64 encoding
- ✅ Silence detection and automatic filtering
- ✅ Mutual exclusion with WhisperKit recording and screen recording
- ✅ Transcription history integration

**Keyboard Shortcuts**:
- **Cmd+Opt+Z**: Offline audio recording with the engine selected in Settings (WhisperKit or Parakeet)
- **Cmd+Opt+X**: Gemini audio recording (cloud)
- **Cmd+Opt+S**: Text-to-speech with Gemini
- **Cmd+Opt+C**: Screen recording with video transcription
- **Cmd+Opt+A**: Show transcription history
- **Cmd+Opt+V**: Paste last transcription at cursor

## Memory monitoring

- Always on in main
- Key file: `SharedSources/MemoryMonitor.swift`
- Logs to `~/Library/Logs/SuperVoiceAssistant/memory.log`
- Logs threshold crossings at 5GB, 10GB, 20GB, 50GB, 100GB
- After a crash, check the log: `cat ~/Library/Logs/SuperVoiceAssistant/memory.log`

