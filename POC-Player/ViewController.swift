//
//  ViewController.swift
//  POC-Player
//
//  Created by Paulo Mendes on 16/06/25.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var startVODButton: UIButton!
    private var playPauseButton: UIButton!
    private var timeSliderView: TimeSliderView!
    private var trickPlayImageView: UIImageView!

    // NO TRICK PLAY
//    private let videoURL = "https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8"

    // HAS I-FRAMES
    private let videoURL = "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8"

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupUI()
        setupPlayer()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updatePlayerLayerFrame()
    }
    
    private func setupUI() {
        startVODButton = UIButton(type: .system)
        startVODButton.setTitle("Start VOD", for: .normal)
        startVODButton.setTitleColor(.white, for: .normal)
        startVODButton.backgroundColor = .systemBlue
        startVODButton.layer.cornerRadius = 8
        startVODButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        startVODButton.addTarget(self, action: #selector(startVODTapped), for: .touchUpInside)
        
        view.addSubview(startVODButton)
        
        startVODButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            startVODButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            startVODButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startVODButton.widthAnchor.constraint(equalToConstant: 120),
            startVODButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        setupPlayPauseButton()
        setupTimeSlider()
        setupTrickPlayImageView()
    }
    
    private func setupPlayPauseButton() {
        playPauseButton = UIButton(type: .system)
        playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playPauseButton.tintColor = .white
        playPauseButton.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        playPauseButton.layer.cornerRadius = 16
        playPauseButton.addTarget(self, action: #selector(playPauseTapped), for: .touchUpInside)
        
        view.addSubview(playPauseButton)
        
        playPauseButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            playPauseButton.widthAnchor.constraint(equalToConstant: 32),
            playPauseButton.heightAnchor.constraint(equalToConstant: 32),
            playPauseButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            playPauseButton.bottomAnchor.constraint(equalTo: view.centerYAnchor, constant: 130)
        ])
    }
    
    private func setupTimeSlider() {
        timeSliderView = TimeSliderView()
        timeSliderView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(timeSliderView)
        
        NSLayoutConstraint.activate([
            timeSliderView.leadingAnchor.constraint(equalTo: playPauseButton.trailingAnchor, constant: 16),
            timeSliderView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            timeSliderView.centerYAnchor.constraint(equalTo: playPauseButton.centerYAnchor)
        ])
        
        // Setup callbacks
        timeSliderView.onSeek = { [weak self] time in
            print(time)
            self?.player?.seek(to: time)
        }
        
        timeSliderView.onTrickPlayStart = { [weak self] in
            self?.player?.pause()
        }
        
//        timeSliderView.onTrickPlayEnd = { [weak self] in
//
//        }
        
        timeSliderView.onTrickPlayImageUpdate = { [weak self] image in
            self?.updateTrickPlayImage(image)
        }
    }
    
    private func setupTrickPlayImageView() {
        trickPlayImageView = UIImageView()
        trickPlayImageView.contentMode = .scaleAspectFit
        trickPlayImageView.backgroundColor = .black
        trickPlayImageView.layer.cornerRadius = 8
        trickPlayImageView.clipsToBounds = true
        trickPlayImageView.isHidden = true
        trickPlayImageView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(trickPlayImageView)
        
        NSLayoutConstraint.activate([
            trickPlayImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            trickPlayImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            trickPlayImageView.widthAnchor.constraint(equalTo: view.widthAnchor),
            trickPlayImageView.heightAnchor.constraint(equalTo: view.heightAnchor)
        ])
    }
    
    private func setupPlayer() {
        guard let url = URL(string: videoURL) else { return }
        
        let asset = AVURLAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem)
        
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.videoGravity = .resizeAspect
        
        if let playerLayer = playerLayer {
            view.layer.insertSublayer(playerLayer, below: startVODButton.layer)
        }
        
        // Configure time slider with player
        if let player = player {
            timeSliderView.configure(with: player)
        }
    }
    
    private func updatePlayerLayerFrame() {
        let playerHeight = view.bounds.height * 0.6
        let playerWidth = view.bounds.width
        let playerY = (view.bounds.height - playerHeight) / 2 - 50
        
        playerLayer?.frame = CGRect(x: 0, y: playerY, width: playerWidth, height: playerHeight)
    }
    
    @objc private func startVODTapped() {
        player?.play()
        updatePlayPauseButton()
    }
    
    @objc private func playPauseTapped() {
        guard let player = player else { return }
        
        if player.timeControlStatus == .playing {
            player.pause()
        } else {
            player.play()
        }
        updatePlayPauseButton()
    }
    
    private func updatePlayPauseButton() {
        guard let player = player else { return }
        
        let isPlaying = player.timeControlStatus == .playing
        let imageName = isPlaying ? "pause.fill" : "play.fill"
        playPauseButton.setImage(UIImage(systemName: imageName), for: .normal)
    }
    
    private func updateTrickPlayImage(_ image: UIImage?) {
        print("updateTrickPlayImage called with image: \(image != nil ? "YES" : "NO")")
        if let image = image {
            trickPlayImageView.image = image
            trickPlayImageView.isHidden = false
        } else {
            trickPlayImageView.isHidden = true
        }
    }
}

