# POC Video Player with Trick Play

A proof-of-concept iOS video player built with AVFoundation featuring advanced trick play functionality with pre-generated thumbnails for optimal performance.

## 🎯 Overview

This project demonstrates how to implement a high-performance video player with trick play capabilities using AVFoundation's `AVAssetImageGenerator`. The implementation focuses on providing instant thumbnail responses during slider interactions through intelligent pre-generation strategies.

## ✨ Features

- **Real-time Video Playback** with HLS stream support
- **Interactive Time Slider** with current/total duration display
- **Instant Trick Play Thumbnails** with zero lag during interaction
- **Pre-generated Thumbnail System** for optimal performance
- **I-Frame Optimized** image generation
- **Adaptive Quality Settings** based on video duration
- **Memory Efficient** thumbnail management
- **Responsive UI** with proper layout constraints

## 🏗️ Architecture

### Core Components

1. **ViewController.swift** - Main video player controller
2. **TimeSliderView.swift** - Custom slider component with trick play functionality

### Key Technologies

- **AVFoundation** - Core media playback and processing
- **AVAssetImageGenerator** - Thumbnail generation from video frames
- **AVPlayer/AVPlayerLayer** - Video rendering and playback control
- **UIKit** - User interface and custom components

## 🔧 Implementation Details

### Trick Play Strategy

We implemented a **pre-generation approach** instead of on-demand thumbnail creation:

#### ❌ Initial Approach (On-Demand)
```swift
// Generates image for each slider value change - causes lag
imageGenerator.generateCGImageAsynchronously(for: requestTime) { image, _, error in
    // Handle single image response
}
```

#### ✅ Final Approach (Pre-Generated)
```swift
// Generate all thumbnails upfront when video loads
imageGenerator.generateCGImagesAsynchronously(forTimes: requestedTimes) { requestedTime, image, actualTime, result, error in
    // Store in dictionary for instant access
    preGeneratedImages[timeKey] = uiImage
}
```

### Adaptive Thumbnail Intervals

The system automatically adjusts thumbnail density based on video duration:

```swift
// Shorter videos: more frequent images, longer videos: less frequent
if totalSeconds <= 300 { // 5 minutes or less
    imageGenerationInterval = 2.0 // Every 2 seconds
} else if totalSeconds <= 1800 { // 30 minutes or less
    imageGenerationInterval = 5.0 // Every 5 seconds
} else { // Longer than 30 minutes
    imageGenerationInterval = 10.0 // Every 10 seconds
}
```

### I-Frame Optimization

We discovered that AVAssetImageGenerator automatically uses I-frames when configured with appropriate time tolerance:

```swift
// Allow tolerance to find nearest I-frame within reasonable time range
imageGenerator?.requestedTimeToleranceBefore = CMTime(seconds: 2.0, preferredTimescale: 600)
imageGenerator?.requestedTimeToleranceAfter = CMTime(seconds: 2.0, preferredTimescale: 600)
```

**Key Insights:**
- **Zero tolerance** forces exact time matching (slower, may require P/B frame decoding)
- **Flexible tolerance** allows AVAssetImageGenerator to find nearest I-frame (much faster)
- **I-frames** are complete, self-contained frames that decode faster than P/B frames

## 📋 Key Findings

### 1. Asset Loading Challenges

**Problem:** Initial implementation didn't account for async asset loading
```swift
// ❌ This fails because duration might not be loaded yet
duration = currentItem.duration
```

**Solution:** Proper async asset loading
```swift
// ✅ Wait for asset properties to load
let loadedDuration = try await asset.load(.duration)
```

### 2. HLS I-Frame Support

**Discovery:** Some HLS streams include special I-frame playlists with `EXT-X-I-FRAMES-ONLY` tags specifically designed for trick play. AVAssetImageGenerator can automatically use these when available.

### 3. Performance Optimization

**Key optimizations implemented:**
- **240p thumbnail resolution** for faster generation and lower memory usage
- **Pre-generation strategy** eliminates real-time processing lag
- **Dictionary-based lookup** for instant thumbnail retrieval
- **Memory cleanup** in deinit to prevent leaks

### 4. Quality vs Performance Trade-offs

```swift
// 240p quality - optimal balance for trick play
imageGenerator?.maximumSize = CGSize(width: 426, height: 240)
```

Higher resolutions increase generation time and memory usage without significant UX benefit for trick play scenarios.

## 🚀 Usage

### Basic Setup

1. **Initialize the player:**
```swift
let asset = AVURLAsset(url: videoURL)
let playerItem = AVPlayerItem(asset: asset)
player = AVPlayer(playerItem: playerItem)
```

2. **Configure the time slider:**
```swift
timeSliderView.configure(with: player)
```

3. **Set up callbacks:**
```swift
timeSliderView.onSeek = { [weak self] time in
    self?.player?.seek(to: time)
}

timeSliderView.onTrickPlayImageUpdate = { [weak self] image in
    self?.updateTrickPlayImage(image)
}
```

### Supported Video Formats

- **HLS Streams** (.m3u8)
- **MP4 Files**
- **Any format supported by AVFoundation**

## 🎛️ Configuration Options

### Thumbnail Generation Settings

```swift
// Adjust quality (lower = faster generation)
imageGenerator?.maximumSize = CGSize(width: 426, height: 240)

// Adjust I-frame tolerance (higher = faster, less precise)
imageGenerator?.requestedTimeToleranceBefore = CMTime(seconds: 2.0, preferredTimescale: 600)
imageGenerator?.requestedTimeToleranceAfter = CMTime(seconds: 2.0, preferredTimescale: 600)
```

### Generation Intervals

Modify the adaptive interval logic in `preGenerateTrickPlayImages()` to adjust thumbnail density based on your needs.

## 🧪 Testing

The project includes debug logging to monitor performance:

```swift
print("Pre-generating \(numberOfImages) trick play images (interval: \(imageGenerationInterval)s)...")
print("Generated image for time: \(timeKey)s")
print("Showing trick play image for time: \(timeInSeconds)s")
```

### Test Videos

- **No I-Frame playlist:** `https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8`
- **With I-Frame playlist:** `https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8`

## 📱 Requirements

- **iOS 18.5+**
- **Xcode 15.0+**
- **Swift 5.0+**

## 🔮 Future Enhancements

1. **Progressive Loading** - Generate thumbnails in background during playback
2. **Caching System** - Persist thumbnails across app sessions
3. **Quality Adaptation** - Dynamic quality based on device performance
4. **Gesture Support** - Two-finger scrubbing for fine-grained control
5. **Chapter Markers** - Integration with video chapter metadata

## 📚 References

- [Apple Developer - Creating Images from a Video Asset](https://developer.apple.com/documentation/avfoundation/creating-images-from-a-video-asset)
- [AVAssetImageGenerator Documentation](https://developer.apple.com/documentation/avfoundation/avassetimagegenerator)
- [HLS Authoring Specification](https://tools.ietf.org/html/rfc8216)

## 🤝 Contributing

This is a proof-of-concept project demonstrating advanced AVFoundation techniques. Feel free to use these patterns in your own projects.

## 📄 License

This project is available for educational and demonstration purposes.

---

*Built with ❤️ using AVFoundation and UIKit*