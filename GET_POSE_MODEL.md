# 📱 Getting a Core ML Pose Model

## Option 1: Use Apple's Built-in Vision Framework (Recommended)

✅ **Already implemented** in `ApplePoseEstimator.swift`
- Uses `VNDetectHumanBodyPoseRequest`
- No additional model file needed
- Works immediately on iOS 14+
- High accuracy and performance

## Option 2: Download Pre-trained Models

### A. Apple's CreateML Models
```bash
# Download from Apple's Machine Learning gallery
# https://developer.apple.com/machine-learning/models/

# PoseNet model (if available)
curl -O https://ml-assets.apple.com/coreml/models/Image/PoseEstimation/PoseNet.mlmodel
```

### B. Convert TensorFlow Models
```bash
# Install coremltools
pip install coremltools tensorflow

# Convert PoseNet from TensorFlow Hub
python3 << EOF
import coremltools as ct
import tensorflow as tf

# Load TensorFlow model
model = tf.keras.models.load_model('posenet_model')

# Convert to Core ML
coreml_model = ct.convert(model, 
                         inputs=[ct.ImageType(shape=(1, 257, 257, 3))])

# Save as .mlmodel
coreml_model.save('PoseNet.mlmodel')
EOF

# Compile to .mlmodelc
xcrun coremlcompiler compile PoseNet.mlmodel ios/AICoach/Resources/
```

### C. Use MediaPipe Models
```bash
# MediaPipe has pose models that can be converted
# https://google.github.io/mediapipe/solutions/pose.html

# Download MediaPipe pose model
curl -O https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_lite/float16/latest/pose_landmarker_lite.task

# Convert using MediaPipe's Core ML converter
# (Requires MediaPipe framework)
```

## Option 3: Quick Setup with Apple Vision (No Model Needed)

### Update WorkoutView to use Apple's built-in pose detection:

```swift
// In WorkoutView.swift, replace:
@StateObject private var poseEstimator = PoseEstimator()

// With:
@StateObject private var poseEstimator = ApplePoseEstimator()
```

### This gives you:
- ✅ **Immediate functionality** - no model download needed
- ✅ **High accuracy** - Apple's trained models
- ✅ **Optimized performance** - hardware accelerated
- ✅ **Privacy compliant** - all processing on-device

## 🚀 Recommended Quick Start

1. **Use Apple Vision Framework** (already implemented)
2. **Update WorkoutView** to use `ApplePoseEstimator`
3. **Test on iOS device** (simulator has limited camera support)
4. **Add Core ML model later** if you need custom pose detection

## 📱 Testing on Device

```bash
# Create Xcode project
open -a Xcode

# Create new iOS project
# Add all Swift files from ios/AICoach/
# Set deployment target to iOS 14.0+
# Add required frameworks:
#   - AVFoundation
#   - Vision
#   - HealthKit
#   - CoreML (if using custom model)

# Build and run on physical device
# (Camera doesn't work well in simulator)
```

## 🎯 Expected Results

With Apple Vision Framework, you'll get:
- **Real-time pose detection** at 30fps
- **17 joint keypoints** (COCO format)
- **Confidence scores** for each joint
- **Live form analysis** and coaching cues
- **Privacy-compliant** processing (all on-device)

The system will then provide:
- ✅ Live camera feed with pose overlay
- ✅ Real-time depth analysis ("Go deeper!")
- ✅ Tempo feedback ("Slow down!")
- ✅ Form correction ("Keep knees aligned!")
- ✅ Heart rate integration
- ✅ Rep counting and progress tracking
