# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

POC-Player is an iOS application built with Swift and UIKit, targeting iOS 18.5+. It uses a traditional Storyboard-based architecture with separate AppDelegate and SceneDelegate classes.

## Build Commands

- **Build the project**: `xcodebuild -project POC-Player.xcodeproj -scheme POC-Player -configuration Debug build`
- **Clean build**: `xcodebuild -project POC-Player.xcodeproj -scheme POC-Player clean`
- **Build for release**: `xcodebuild -project POC-Player.xcodeproj -scheme POC-Player -configuration Release build`
- **Run on simulator**: Open in Xcode and use Cmd+R, or use `xcrun simctl` commands

## Architecture

- **Entry Point**: AppDelegate.swift handles app lifecycle
- **Scene Management**: SceneDelegate.swift manages window scenes
- **Main UI**: Uses Main.storyboard with ViewController.swift as the initial view controller
- **Bundle Identifier**: Performance.POC-Player
- **Development Team**: RPWVB626RU
- **Swift Version**: 5.0

## Key Project Settings

- iOS Deployment Target: 18.5
- Supports iPhone and iPad (Universal)
- Uses automatic code signing
- Main storyboard: Main.storyboard
- Launch screen: LaunchScreen.storyboard