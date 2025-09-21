# 📱 Creating Xcode Project for AI Coach

## Step 1: Create New iOS Project

1. **Open Xcode**
2. **Create a new project**:
   - Choose "iOS" → "App"
   - Product Name: "AI Coach"
   - Interface: SwiftUI
   - Language: Swift
   - Bundle Identifier: `com.yourname.aicoach`
   - Deployment Target: iOS 14.0+

## Step 2: Add Required Frameworks

In Project Settings → "Frameworks, Libraries, and Embedded Content":
- ✅ AVFoundation.framework
- ✅ Vision.framework  
- ✅ HealthKit.framework
- ✅ CoreML.framework

## Step 3: Configure Info.plist

Add these permissions:
```xml
<key>NSCameraUsageDescription</key>
<string>AI Coach needs camera access for real-time pose analysis and form correction</string>

<key>NSHealthShareUsageDescription</key>
<string>AI Coach needs access to heart rate data for workout monitoring</string>

<key>NSHealthUpdateUsageDescription</key>
<string>AI Coach needs to save workout data to Health app</string>
```

## Step 4: Add Swift Files

Copy all files from `/Users/heshi/Downloads/ai-coach/ios/AICoach/` to your Xcode project:

### Core Files:
- `Camera/CameraPipeline.swift`
- `Health/HealthKitManager.swift`
- `Pose/ApplePoseEstimator.swift`
- `Pose/FeatureExtractor.swift`
- `Pose/RepCounter.swift`
- `Coaching/CoachingEngine.swift`
- `Sync/MetricsSync.swift`
- `UI/WorkoutView.swift`
- `UI/PoseOverlayView.swift`

## Step 5: Create App Entry Point

Create `ContentView.swift`:
```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        WorkoutView()
    }
}

@main
struct AICoachApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

## Step 6: Build and Run

1. **Select iPhone simulator** (iPhone 14 Pro recommended)
2. **Press Cmd+R** to build and run
3. **Grant permissions** when prompted
4. **Test the UI** - camera won't work in simulator but UI will display

## Expected Result:
- ✅ App launches successfully
- ✅ UI renders correctly
- ✅ Buttons and controls work
- ⚠️ Camera shows black (simulator limitation)
- ⚠️ HealthKit may not work (simulator limitation)
