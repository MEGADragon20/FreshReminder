# FreshReminder - Android Testing Guide (Samsung A21 on Linux)

## 🎯 Overview

This guide helps you test the FreshReminder app on a physical Samsung A21 Android phone from your Linux machine.

---

## 📋 Prerequisites

### On Your Linux Machine:
- ✅ Flutter SDK installed and in PATH
- ✅ Android SDK installed (via Android Studio or cmdline-tools)
- ✅ ADB (Android Debug Bridge) installed
- ✅ USB cable for Samsung A21
- ✅ Backend Flask server running

### On Your Samsung A21:
- ✅ USB Debugging enabled
- ✅ Developer Mode enabled
- ✅ Device connected via USB cable

---

## 🔧 Step 1: Enable Developer Mode on Samsung A21

### On your Samsung A21:
1. Go to **Settings** → **About phone**
2. Find **Build number** (scroll down)
3. Tap **Build number** 7 times rapidly
4. You should see "You are now a developer!" message
5. Go back to Settings
6. You should now see **Developer options** menu

### Enable USB Debugging:
1. Go to **Settings** → **Developer options**
2. Find **USB Debugging** toggle
3. Enable it (turn it ON)
4. A dialog may appear asking to allow USB debugging - tap **Allow**

---

## 🔌 Step 2: Connect Phone to Linux via USB

1. **Connect USB cable** from Samsung A21 to Linux computer
2. On phone, you may see "Allow USB debugging?" dialog
3. Check **Always allow from this computer**
4. Tap **Allow**
5. **Optional:** Grant file access permissions if prompted

### Verify Connection

Open terminal on Linux and run:

```bash
adb devices
```

**Expected Output:**
```
List of attached devices
192168a21s2    device
```

If you see `device` (not `offline`), you're connected! ✅

**Troubleshooting if not connected:**

```bash
# Restart ADB daemon
adb kill-server
adb start-server

# Reconnect phone via USB and try again
adb devices
```

---

## 🚀 Step 3: Build and Run App on Phone

### Option A: Direct Flutter Run (Easiest)

```bash
cd /home/md20/Dokumente/FreshReminder/freshreminder

# See available devices
flutter devices

# Should show your Samsung A21 in the list

# Run on your phone (omit -d flag to select device)
flutter run
```

**Select your device when prompted.**

The app will:
- 📦 Build the Android APK
- 📲 Install it on your phone
- 🚀 Launch the app automatically

**Time:** First run takes 3-5 minutes (compiling)

### Option B: Specify Device ID

```bash
cd /home/md20/Dokumente/FreshReminder/freshreminder

# Find your device ID
flutter devices

# Run on specific device
flutter run -d <device_id>

# Example:
flutter run -d 192168a21s2
```

---

## 📱 Step 4: View App on Your Phone

Once the app launches:

1. **Login Screen** should appear
2. You have two options:
   - Register a new account
   - Login with existing account from testing

### Test Registration:
1. Click **Register** link
2. Enter:
   - Email: `phone@example.com`
   - Password: `password123`
   - Confirm: `password123`
3. Click **Register**
4. Should see **Home Screen** with "Produkte" tab selected

### Test Login:
1. Go to **Profile** tab
2. Click **Abmelden** (Logout)
3. Confirm logout
4. Login with: `phone@example.com` / `password123`
5. Should see home screen again

---

## 🔍 Step 5: Monitor App Logs

### View Real-time Logs While App Runs

While `flutter run` is active in terminal, you'll see logs automatically.

### View Logs from Terminal

```bash
# View Flutter app logs
flutter logs

# View Android logs (more detailed)
adb logcat

# Filter for your app only
adb logcat | grep freshreminder

# Save logs to file
adb logcat > /tmp/android_logs.txt
```

### Check for Errors

Look for red lines in logs that indicate:
- API connection failures
- Authentication errors
- Database issues

Example error message:
```
E/flutter (12345): Connection refused: 127.0.0.1:5000
```

This means the backend server isn't running.

---

## 🌐 Step 6: Connect Phone to Backend Server

### Network Setup Required

Your Android phone needs to access the Flask backend running on Linux.

**Key Issue:** Phone can't use `localhost:5000` - needs your Linux machine's IP address

### Option A: Find Your Linux Machine's IP Address

```bash
# Method 1: Get local network IP
hostname -I

# Look for IP starting with 192.168 or 10.0
# Example output: 192.168.1.100

# Method 2: More detailed
ip addr show | grep "inet " | grep -v 127.0.0.1
```

**Example output:**
```
192.168.1.100
```

### Option B: Update API URL in Flutter App

Edit the API service to use your Linux IP:

**File:** `/home/md20/Dokumente/FreshReminder/freshreminder/lib/services/api_service.dart`

Find this line:
```dart
static const String baseUrl = 'http://localhost:5000/api';
```

Replace with (use YOUR IP from above):
```dart
static const String baseUrl = 'http://192.168.1.100:5000/api';
```

Then rebuild the app:
```bash
flutter run -d <device_id>
```

### Verify Connection from Phone

Once app is running:
1. Go to **Login Screen**
2. Try to register or login
3. If successful → Backend is reachable ✅
4. If fails → Check network connection

---

## 📊 Complete Testing Workflow on Android

### Before You Start:
Terminal 1: Start Backend
```bash
cd /home/md20/Dokumente/FreshReminder/backend
source venv/bin/activate
python app.py

# Should show:
# Running on http://127.0.0.1:5000
# Running on http://192.168.1.100:5000
```

Terminal 2: Connect Phone & Run App
```bash
cd /home/md20/Dokumente/FreshReminder/freshreminder

# Check connection
adb devices

# Update API URL in api_service.dart with your Linux IP (see above)

# Run on phone
flutter run
```

### Test Sequence:

**1. Register New Account**
- Click "Register"
- Email: `android_test@example.com`
- Password: `testpass123`
- Confirm: `testpass123`
- Click Register
- ✅ Should see Home Screen

**2. Test Profile Tab**
- Click **Profile** (bottom right)
- Should show email: `android_test@example.com`
- Click **Abmelden** (Logout)
- Confirm logout

**3. Test Login**
- Login with: `android_test@example.com` / `testpass123`
- ✅ Should see Home Screen

**4. Test Error Messages**
- Try wrong password
- ✅ Should show error message
- Try to register with same email again
- ✅ Should show error: "Email bereits registriert"

**5. Test Navigation**
- Click **Produkte** (Home tab) - shows product list
- Click **Scanner** tab - shows QR scanner
- Click **Profile** tab - shows user profile

**6. Test App Exit & Relaunch**
- Press back button to minimize app
- Kill app from recent apps (swipe up on home button)
- Tap app icon again to relaunch
- ✅ Should still be logged in (token persisted)

---

## 🛠️ Troubleshooting Android Testing

### Issue: "adb devices" shows nothing

**Solution:**
```bash
# Make sure phone is in USB Debugging mode
# Reconnect USB cable
# Restart adb daemon
adb kill-server
adb start-server

# Try again
adb devices
```

### Issue: App crashes on startup

**Check logs:**
```bash
flutter logs
adb logcat | grep -E "ERROR|Exception"
```

**Common causes:**
- Backend not running
- API URL pointing to `localhost` instead of Linux IP
- Plugin error (SharedPreferences, etc.)

### Issue: "Cannot connect to backend"

**Solution:**
```bash
# 1. Get your Linux IP
hostname -I

# 2. Update API URL in api_service.dart with that IP

# 3. Make sure backend is running:
curl http://192.168.1.100:5000/health

# 4. From phone browser, try accessing:
# Open phone browser and visit: http://192.168.1.100:5000/health
# Should show: {"status": "ok"}
```

### Issue: "Connection refused" error

This means:
- Backend isn't running
- Wrong IP address in code
- Phone and Linux on different networks

**Fix:**
```bash
# 1. Start backend:
cd backend
source venv/bin/activate
python app.py

# 2. Find Linux IP:
hostname -I

# 3. Update app code with correct IP
# File: lib/services/api_service.dart
# Line: baseUrl = 'http://YOUR_IP:5000/api'

# 4. Rebuild:
flutter run
```

### Issue: USB Cable Not Recognized

```bash
# Install USB tools
sudo apt-get install android-tools-adb

# Check USB connection
lsusb | grep -i samsung

# Restart ADB
adb kill-server
adb start-server
```

---

## 📲 Advanced: Install Pre-built APK

If you want to distribute the app without installing Flutter:

### Build APK

```bash
cd /home/md20/Dokumente/FreshReminder/freshreminder

# Build APK
flutter build apk

# APK will be at:
# build/app/outputs/flutter-apk/app-release.apk
```

### Install APK

```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Share APK with Others

The APK file can be:
- Copied to other phones via Bluetooth
- Emailed as attachment
- Uploaded to cloud storage

---

## 🔐 Security Considerations

### For Testing Only:
- Current setup uses HTTP (not HTTPS)
- API URL hardcoded in app
- Not suitable for production

### For Production:
- Use HTTPS with SSL certificates
- Store API URL in secure config file
- Implement certificate pinning
- Use proper key management

---

## 📈 Performance Testing on Android

### Monitor App Performance

```bash
# Memory usage
adb shell dumpsys meminfo | grep freshreminder

# CPU usage
adb shell top

# Battery stats
adb shell dumpsys batterystats
```

### Test Different Scenarios

1. **Slow Network:** 
   - Go to Developer Options → Simulate Networks
   - Select "EDGE" or "2G" network
   - Test app responsiveness

2. **Low Memory:**
   - Open many apps to reduce available memory
   - Test if app handles low memory gracefully

3. **Poor Connection:**
   - Disable WiFi
   - Use 4G data only
   - Test timeout handling

---

## 📋 Android Testing Checklist

### Setup
- [ ] USB Debugging enabled on phone
- [ ] Phone connected to Linux via USB
- [ ] `adb devices` shows your phone
- [ ] Backend running on Linux
- [ ] API URL updated to Linux IP
- [ ] Flutter app built successfully

### Functionality Tests
- [ ] App launches without crash
- [ ] Login screen appears
- [ ] Can register new account
- [ ] Can login with registered account
- [ ] Profile shows correct email
- [ ] Can logout
- [ ] Error messages appear for invalid input
- [ ] Can navigate between tabs
- [ ] Stays logged in after app restart

### Network Tests
- [ ] Can communicate with backend
- [ ] Registration successful
- [ ] Login successful
- [ ] API calls complete without timeout
- [ ] Error messages for connection failures

### Device Tests
- [ ] App works in landscape mode
- [ ] App works in portrait mode
- [ ] Permissions handled correctly
- [ ] Works with phone screen rotation
- [ ] No memory leaks (check logs)

---

## 🎓 Useful ADB Commands

```bash
# List connected devices
adb devices

# Install APK
adb install path/to/app.apk

# Uninstall app
adb uninstall com.freshreminder.app

# Clear app data
adb shell pm clear com.freshreminder.app

# View logs
adb logcat

# Take screenshot
adb shell screencap /sdcard/screenshot.png

# Pull screenshot to computer
adb pull /sdcard/screenshot.png

# Restart ADB
adb kill-server && adb start-server

# Check app permissions
adb shell pm list permissions
```

---

## 🎉 Success Indicators

Everything is working when:

✅ Phone connects via USB (shows in `adb devices`)
✅ App installs and launches on phone
✅ Login/Register screens appear
✅ Can create account successfully
✅ Can login and see profile
✅ App stays logged in after restart
✅ No error messages in logs
✅ All tabs navigate correctly

---

## 📞 Next Steps

After successful Android testing:

1. **Test on Multiple Devices** (if available)
   - Different Android versions
   - Different phone brands
   - Different screen sizes

2. **Test Edge Cases**
   - Very long product names
   - Many products (100+)
   - Slow network conditions
   - App backgrounding

3. **Prepare for Release**
   - Sign APK with production key
   - Test on Firebase Test Lab
   - Publish to Google Play Store

---

## ⚠️ Important Notes

### Network Access:
- Phone and Linux must be on same WiFi network
- Or use USB network tethering
- Or ensure routing between networks is configured

### API URL:
- **Linux:** `http://localhost:5000/api` (only works on desktop)
- **Android:** `http://192.168.1.100:5000/api` (replace with your Linux IP)
- Get your IP with: `hostname -I`

### Token Storage:
- Android uses SharedPreferences (native secure storage)
- Tokens automatically persisted
- Survives app restart

---

## 💡 Pro Tips

1. **Use WiFi Hotspot:**
   If your phone and Linux aren't on same network, use phone's hotspot to connect Linux to phone's WiFi.

2. **View Device Screen on Linux:**
   ```bash
   sudo apt-get install scrcpy
   scrcpy
   ```
   Shows your phone screen on Linux (useful for screenshots/recording).

3. **Save Logs for Analysis:**
   ```bash
   flutter logs > /tmp/flutter_logs.txt &
   adb logcat > /tmp/android_logs.txt &
   # Run your tests
   # Ctrl+C to stop logging
   ```

4. **Multiple Device Testing:**
   Connect multiple phones via USB hub
   ```bash
   adb devices  # shows all connected devices
   flutter run -d <device_id>  # run on specific device
   ```

---

**Happy Testing on Android! 🚀**

Generated: 28 November 2025
