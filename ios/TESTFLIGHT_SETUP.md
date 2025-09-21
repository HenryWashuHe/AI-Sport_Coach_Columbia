# 🛫 TestFlight Setup for AI Coach

## What is TestFlight?
TestFlight allows you to distribute beta versions of your app to testers before App Store release.

## Step 1: Prepare for TestFlight

### A. Apple Developer Account
- **Required**: $99/year Apple Developer Program membership
- **Sign up**: https://developer.apple.com/programs/

### B. App Store Connect Setup
1. **Go to**: https://appstoreconnect.apple.com
2. **Create new app**:
   - Name: "AI Coach"
   - Bundle ID: `com.yourname.aicoach`
   - SKU: `aicoach-001`
   - User Access: Full Access

### C. Archive Your App
In Xcode:
1. **Select**: "Any iOS Device" (not simulator)
2. **Product** → **Archive**
3. **Wait for build** to complete
4. **Distribute App** → **App Store Connect**
5. **Upload** to App Store Connect

## Step 2: TestFlight Distribution

### Internal Testing (Immediate)
- **Up to 100 testers**
- **No review required**
- **Available immediately** after upload
- **Add testers** by email in App Store Connect

### External Testing (Public Beta)
- **Up to 10,000 testers**
- **Apple review required** (1-2 days)
- **Public link** for easy sharing
- **Feedback collection** built-in

## Step 3: Test Your UI

### What Testers Can Test:
✅ **Complete UI flow** - all screens and interactions
✅ **Real camera input** - actual pose detection
✅ **HealthKit integration** - real heart rate data
✅ **Performance** - on actual devices
✅ **Different devices** - iPhone/iPad variants
✅ **iOS versions** - compatibility testing

### What Testers Will See:
- **Full workout experience** with live camera
- **Real-time coaching cues** and feedback
- **Actual heart rate monitoring**
- **Complete app performance**

## Step 4: Collect Feedback

### Built-in Feedback:
- **Screenshot feedback** - testers can annotate screenshots
- **Crash reports** - automatic crash collection
- **Usage analytics** - how testers use the app

### Custom Feedback:
- **In-app feedback** button
- **Email feedback** collection
- **Survey links** for detailed feedback

## Expected Timeline:
- **Day 1**: Upload to TestFlight
- **Day 1**: Internal testing available
- **Day 2-3**: External testing approved
- **Week 1**: Collect feedback and iterate
- **Week 2**: Final version ready for App Store

## Benefits for AI Coach:
✅ **Real camera testing** - actual pose detection
✅ **Device compatibility** - iPhone/iPad testing
✅ **Performance validation** - real-world usage
✅ **User experience** - actual user feedback
✅ **Bug discovery** - issues before public release
