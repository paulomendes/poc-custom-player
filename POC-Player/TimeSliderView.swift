import UIKit
import AVFoundation

class TimeSliderView: UIView {
    
    // MARK: - UI Components
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.text = "00:00 / 00:00"
        label.font = UIFont.preferredFont(forTextStyle: .callout)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let slider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.value = 0
        slider.minimumTrackTintColor = .systemBlue
        slider.maximumTrackTintColor = .systemGray
        slider.thumbTintColor = .white
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()
    
    // MARK: - Properties
    private var player: AVPlayer?
    private var timeObserver: Any?
    private var imageGenerator: AVAssetImageGenerator?
    private var isSliding = false
    private var duration: CMTime = .zero
    private var preGeneratedImages: [Double: UIImage] = [:]
    private var imageGenerationInterval: Double = 5.0 // Generate image every 5 seconds
    
    // MARK: - Callbacks
    var onSeek: ((CMTime) -> Void)?
    var onTrickPlayStart: (() -> Void)?
    var onTrickPlayEnd: (() -> Void)?
    var onTrickPlayImageUpdate: ((UIImage?) -> Void)?
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupSliderActions()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupSliderActions()
    }
    
    // MARK: - Setup
    private func setupUI() {
        addSubview(timeLabel)
        addSubview(slider)
        
        NSLayoutConstraint.activate([
            // Time label at the top
            timeLabel.topAnchor.constraint(equalTo: topAnchor),
            timeLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            timeLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            timeLabel.heightAnchor.constraint(equalToConstant: 20),
            
            // Slider below the time label
            slider.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 8),
            slider.leadingAnchor.constraint(equalTo: leadingAnchor),
            slider.trailingAnchor.constraint(equalTo: trailingAnchor),
            slider.heightAnchor.constraint(equalToConstant: 30),
            
            // Set the overall height of the container
            heightAnchor.constraint(equalToConstant: 58)
        ])
    }
    
    private func setupSliderActions() {
        slider.addTarget(self, action: #selector(sliderTouchDown), for: .touchDown)
        slider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        slider.addTarget(self, action: #selector(sliderTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }
    
    // MARK: - Player Integration
    func configure(with player: AVPlayer) {
        self.player = player
        setupTimeObserver()
        setupImageGenerator()
        updateDuration()
    }
    
    private func setupTimeObserver() {
        guard let player = player else { return }
        
        // Remove existing observer
        if let timeObserver = timeObserver {
            player.removeTimeObserver(timeObserver)
        }
        
        // Add periodic time observer
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.updateTimeDisplay(currentTime: time)
        }
    }
    
    private func setupImageGenerator() {
        guard let player = player,
              let asset = player.currentItem?.asset else { return }
        
        Task {
            do {
                let _ = try await asset.load(.tracks)
                let loadedDuration = try await asset.load(.duration)
                
                DispatchQueue.main.async { [weak self] in
                    self?.imageGenerator = AVAssetImageGenerator(asset: asset)
                    self?.imageGenerator?.appliesPreferredTrackTransform = true
                    
                    // Set maximum size for 240p quality
                    self?.imageGenerator?.maximumSize = CGSize(width: 426, height: 240)
                    
                    // Use I-frames for better performance
                    // Allow tolerance to find nearest I-frame within reasonable time range
                    self?.imageGenerator?.requestedTimeToleranceBefore = CMTime(seconds: 2.0, preferredTimescale: 600)
                    self?.imageGenerator?.requestedTimeToleranceAfter = CMTime(seconds: 2.0, preferredTimescale: 600)
                    
                    print("Image generator setup completed")
                    
                    // Start pre-generating trick play images
                    self?.preGenerateTrickPlayImages(duration: loadedDuration)
                }
            } catch {
                print("Failed to load asset tracks for image generator: \(error)")
            }
        }
    }
    
    private func updateDuration() {
        guard let player = player,
              let currentItem = player.currentItem else { return }
        
        let asset = currentItem.asset
        
        Task {
            do {
                let loadedDuration = try await asset.load(.duration)
                
                DispatchQueue.main.async { [weak self] in
                    self?.duration = loadedDuration
                    
                    if loadedDuration.isValid && !loadedDuration.isIndefinite {
                        self?.slider.maximumValue = Float(loadedDuration.seconds)
                        print("Asset duration loaded: \(loadedDuration.seconds) seconds")
                    }
                }
            } catch {
                print("Failed to load asset duration: \(error)")
            }
        }
    }
    
    // MARK: - Pre-generate Trick Play Images
    private func preGenerateTrickPlayImages(duration: CMTime) {
        guard let imageGenerator = imageGenerator,
              duration.isValid && !duration.isIndefinite else { return }
        
        let totalSeconds = duration.seconds
        
        // Adaptive interval based on video duration
        // Shorter videos: more frequent images, longer videos: less frequent
        if totalSeconds <= 300 { // 5 minutes or less
            imageGenerationInterval = 2.0 // Every 2 seconds
        } else if totalSeconds <= 1800 { // 30 minutes or less
            imageGenerationInterval = 5.0 // Every 5 seconds
        } else { // Longer than 30 minutes
            imageGenerationInterval = 10.0 // Every 10 seconds
        }
        
        let numberOfImages = Int(ceil(totalSeconds / imageGenerationInterval))
        
        print("Pre-generating \(numberOfImages) trick play images (interval: \(imageGenerationInterval)s)...")
        
        var requestedTimes: [NSValue] = []
        
        // Create time intervals for image generation
        for i in 0..<numberOfImages {
            let timeInSeconds = Double(i) * imageGenerationInterval
            if timeInSeconds <= totalSeconds {
                let time = CMTime(seconds: timeInSeconds, preferredTimescale: 600)
                requestedTimes.append(NSValue(time: time))
            }
        }
        
        // Generate all images at once
        imageGenerator.generateCGImagesAsynchronously(forTimes: requestedTimes) { [weak self] (requestedTime, image, actualTime, result, error) in
            DispatchQueue.main.async {
                if let image = image, result == .succeeded {
                    let uiImage = UIImage(cgImage: image)
                    let timeKey = requestedTime.seconds
                    self?.preGeneratedImages[timeKey] = uiImage
                    print("Generated image for time: \(timeKey)s")
                } else if let error = error {
                    print("Failed to generate image for time \(requestedTime.seconds): \(error)")
                }
            }
        }
    }
    
    // MARK: - Time Display
    private func updateTimeDisplay(currentTime: CMTime) {
        guard !isSliding else { return }
        
        let current = formatTime(currentTime)
        let total = formatTime(duration)
        timeLabel.text = "\(current) / \(total)"
        
        if duration.seconds > 0 {
            slider.value = Float(currentTime.seconds)
        }
    }
    
    private func formatTime(_ time: CMTime) -> String {
        guard time.isValid && !time.isIndefinite else { return "00:00" }
        
        let seconds = Int(time.seconds)
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
    
    // MARK: - Slider Actions
    @objc private func sliderTouchDown() {
        isSliding = true
        onTrickPlayStart?()
    }
    
    @objc private func sliderValueChanged() {
        let time = CMTime(seconds: Double(slider.value), preferredTimescale: 600)
        print("slider value changed: \(slider.value), isSliding: \(isSliding)")
        updateTimeDisplayForSliding(time: time)
        showPreGeneratedImage(for: time)
    }
    
    @objc private func sliderTouchUp() {
        isSliding = false
        onTrickPlayEnd?()
        onTrickPlayImageUpdate?(nil) // Clear the trick play image
        
        let time = CMTime(seconds: Double(slider.value), preferredTimescale: 600)
        onSeek?(time)
    }
    
    private func updateTimeDisplayForSliding(time: CMTime) {
        let current = formatTime(time)
        let total = formatTime(duration)
        timeLabel.text = "\(current) / \(total)"
    }
    
    // MARK: - Trick Play Image Display
    private func showPreGeneratedImage(for time: CMTime) {
        let timeInSeconds = time.seconds
        
        // Find the closest pre-generated image
        let closestImageTime = findClosestImageTime(for: timeInSeconds)
        
        if let image = preGeneratedImages[closestImageTime] {
            print("Showing trick play image for time: \(timeInSeconds)s (closest: \(closestImageTime)s)")
            onTrickPlayImageUpdate?(image)
        } else {
            print("No pre-generated image available for time: \(timeInSeconds)s")
            // If no pre-generated image is available, show nothing
            onTrickPlayImageUpdate?(nil)
        }
    }
    
    private func findClosestImageTime(for timeInSeconds: Double) -> Double {
        guard !preGeneratedImages.isEmpty else { return 0.0 }
        
        // Find the closest time interval
        let intervalIndex = Int(round(timeInSeconds / imageGenerationInterval))
        let closestTime = Double(intervalIndex) * imageGenerationInterval
        
        // Make sure we have an image for this time, otherwise find the nearest available
        if preGeneratedImages[closestTime] != nil {
            return closestTime
        }
        
        // If exact match not found, find the closest available time
        let availableTimes = preGeneratedImages.keys.sorted()
        guard let nearestTime = availableTimes.min(by: { abs($0 - timeInSeconds) < abs($1 - timeInSeconds) }) else {
            return 0.0
        }
        
        return nearestTime
    }
    
    // MARK: - Cleanup
    deinit {
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
        }
        preGeneratedImages.removeAll()
    }
}
