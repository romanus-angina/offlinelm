# Voice Quality Enhancement Guide

## Overview

Your `SpeechService` has been enhanced to prioritize premium and enhanced voices, detect voice quality, and guide users to download better voices for the best experience.

## What Changed

### 1. Enhanced Voice Selection (`SpeechService.swift`)

The voice selection algorithm now:
- **Prioritizes personal/Siri voices** - These are the highest quality voices available
- **Detects premium and enhanced voices** - Automatically uses downloaded high-quality voices
- **Provides fallback options** - Gracefully degrades to available voices
- **Tracks voice quality** - Exposes a `voiceQuality` property with three levels:
  - `.optimal` - Premium/enhanced voices active
  - `.good` - Standard quality voices
  - `.suboptimal` - Limited or basic voices

### 2. New Properties and Methods

#### Properties:
```swift
speechService.voiceQuality: VoiceQuality
speechService.hasBetterVoicesAvailable: Bool
speechService.voiceInfo: (hostA: String, hostB: String)
```

#### Methods:
```swift
speechService.openVoiceSettings()  // Opens iOS Settings
speechService.refreshVoices()       // Re-checks available voices
```

## New UI Components

### 1. VoiceQualityBannerView
A dismissible banner that appears at the top of your player when voice quality can be improved.

**Usage:**
```swift
VoiceQualityBannerView(
    voiceQuality: viewModel.speech.voiceQuality,
    onOpenSettings: {
        viewModel.speech.openVoiceSettings()
    }
)
```

**Features:**
- Auto-hides when optimal voices are active
- Dismissible by user
- Provides clear call-to-action
- Different styles for .good and .suboptimal quality

### 2. VoiceDownloadGuideView
A full-screen guide that explains the benefits of premium voices and provides step-by-step instructions.

**Usage:**
```swift
.sheet(isPresented: $showingVoiceGuide) {
    VoiceDownloadGuideView {
        speechService.openVoiceSettings()
    }
}
```

**Features:**
- Explains benefits of premium voices
- Step-by-step download instructions
- Pro tips section
- Beautiful gradient design

### 3. VoiceInfoView
A compact info card showing current voice status.

**Usage:**
```swift
VoiceInfoView(speechService: speechService)
```

**Features:**
- Shows current quality level
- Lists active voices for each host
- Provides download button when applicable
- Great for settings or about screens

## Implementation Examples

### In Your Player (Already Done)
The `PodcastPlayerView` now shows the banner automatically:

```swift
VStack(spacing: 0) {
    header
    
    VoiceQualityBannerView(
        voiceQuality: viewModel.speech.voiceQuality,
        onOpenSettings: {
            viewModel.speech.openVoiceSettings()
        }
    )
    
    waveformSection
    transcript
    controls
}
```

### In a Settings View
```swift
struct SettingsView: View {
    let speechService: SpeechService
    
    var body: some View {
        List {
            Section("Audio Quality") {
                VoiceInfoView(speechService: speechService)
            }
        }
    }
}
```

### Show Guide on First Launch
```swift
struct ContentView: View {
    @State private var showVoiceGuide = false
    @AppStorage("hasSeenVoiceGuide") private var hasSeenVoiceGuide = false
    let speechService: SpeechService
    
    var body: some View {
        // Your content
        .onAppear {
            if !hasSeenVoiceGuide && speechService.hasBetterVoicesAvailable {
                showVoiceGuide = true
                hasSeenVoiceGuide = true
            }
        }
        .sheet(isPresented: $showVoiceGuide) {
            VoiceDownloadGuideView {
                speechService.openVoiceSettings()
            }
        }
    }
}
```

## How Premium Voices Work

### Voice Quality Levels

1. **Premium/Enhanced Voices** (iOS 7+)
   - Much more natural sounding
   - Better prosody and intonation
   - Typically 200-500 MB per voice
   - Must be downloaded from Settings

2. **Siri Voices** (iOS 14+)
   - The highest quality available
   - Same technology used by Siri
   - Neural text-to-speech
   - Often labeled as "Premium" in Settings

3. **Default Voices**
   - Built into iOS
   - Smaller file size
   - More robotic sounding
   - Always available

### How to Download Premium Voices

Users need to:
1. Open Settings
2. Go to Accessibility
3. Select Spoken Content
4. Tap Voices
5. Select English (or their language)
6. Download voices marked "Enhanced" or "Premium"

**Note:** iOS doesn't provide a direct deep link to the Voices page, so `openVoiceSettings()` opens the app's settings page. Users will need to navigate manually from there.

## Voice Detection Logic

The enhanced `selectVoices()` method now:

```swift
// 1. Filter to real Apple voices
let realVoices = all.filter {
    $0.identifier.hasPrefix("com.apple.voice") ||
    $0.identifier.hasPrefix("com.apple.eloquence")
}

// 2. Find premium/enhanced US English voices
let premium = enUS.filter { 
    $0.quality == .premium || $0.quality == .enhanced 
}

// 3. Look for Siri/personal voices (highest quality)
let personal = premium.filter { voice in
    // Check identifier and name for Siri voice indicators
    identifier.contains("personal") || 
    identifier.contains("siri") ||
    // Common Siri voice names
    name.contains("samantha") || name.contains("ava") || ...
}

// 4. Use best available, track quality level
```

## Testing

### In Simulator
The simulator typically has only default voices, so you'll see the "suboptimal" quality indicator. This is expected behavior.

### On Device
Test on a real device where you can:
1. Start with default voices (should show banner)
2. Download premium voices from Settings
3. Close and reopen the app
4. Verify the banner disappears and voice quality improves

### Debug Output
In DEBUG builds, the service logs all available voices:

```
[SpeechService] Available English voices: 12
  en-US | premium | Samantha | com.apple.voice.premium.en-US.Samantha
  en-US | enhanced | Ava | com.apple.voice.enhanced.en-US.Ava
  ...
[SpeechService] Host A -> Samantha (en-US)
[SpeechService] Host B -> Ava (en-US)
```

## User Experience Tips

### Best Practices
1. **Show banner on first use** - Let users know immediately they can improve quality
2. **Don't be too pushy** - Allow dismissal and don't show too frequently
3. **Educate about benefits** - Use the guide view to explain why it matters
4. **Consider onboarding** - Show the guide during initial app setup
5. **Settings integration** - Provide easy access to voice info in settings

### When to Show the Guide
- First time user opens player with suboptimal voices
- User taps "Learn More" from banner
- In settings/preferences section
- After app update that improves voice support

### Storage Considerations
Premium voices are large (200-500 MB each). Consider:
- Warning users about download size
- Recommending Wi-Fi for downloads
- Explaining they can delete unused voices later
- Not forcing downloads, just recommending them

## Future Enhancements

### Possible Improvements
1. **Dynamic voice refresh** - Detect when new voices are installed without restart
2. **Voice preferences** - Let users choose specific voices for each host
3. **A/B testing** - Try different voices and let users pick favorites
4. **Download progress** - Show if voices are currently downloading (requires private API)
5. **Language support** - Extend to multiple languages beyond English

### Making Voices Truly Dynamic
Currently, voices are selected at init. To make them truly dynamic:

```swift
// Change from let to @Published var
@Published private(set) var voiceForHostA: AVSpeechSynthesisVoice?
@Published private(set) var voiceForHostB: AVSpeechSynthesisVoice?

// Then refreshVoices() can actually update them
func refreshVoices() {
    let (newA, newB, newQuality) = Self.selectVoices()
    voiceForHostA = newA
    voiceForHostB = newB
    voiceQuality = newQuality
}
```

## Summary

Your app now:
✅ Automatically uses the best available voices
✅ Detects voice quality levels
✅ Guides users to download better voices
✅ Provides multiple UI components for voice quality
✅ Maintains graceful fallbacks
✅ Works on both simulator and device

The changes ensure users with premium voices get the best experience, while users with default voices are gently encouraged to upgrade for better quality.
