# MyEyes: Real-Time Object Detection with AR Navigation for the Visually Impaired

**Author**: David Chung, Albert Luo, Richie Tran, Alvin Sung  
**Platform**: iOS (UIKit + ARKit) & Python (Flask + YOLOv8)  
**Role**: iOS Frontend + ARKit Integration (Swift)  
**Mentors**: Independently developed with backend model integration via REST APIs

## 🧠 Project Overview

**MyEyes** is an assistive iOS application that functions as an intelligent "visual narrator" for the visually impaired. Using **LiDAR**, **ARKit**, **YOLOv8**, and a real-time **Flask server**, the app:
- Detects and prioritizes real-world objects using the phone's camera.
- Calculates spatial depth to detect nearby obstructions.
- Audibly narrates surroundings and issues proximity-based alerts.

## 🔍 Key Features

### 🧭 Swift AR Navigation Interface (iOS UIKit)
- Leverages **ARKit + SceneDepth** to map 3D space.
- Tracks user movement via device motion and camera transform.
- Uses **AVSpeechSynthesizer** to narrate detected objects in the user’s path.
- Plays vibration + system sound alarm when nearby obstacle detected (`< 2.5 ft`).

### 📷 Object Detection with YOLOv8 + Deep SORT (Python backend)
- Processes camera frames via a REST API and returns top-priority objects.
- Uses **YOLOv8** for detection + **DeepSORT** for multi-object tracking.
- Prioritizes objects “ahead” using bounding box centroids.
- Filters and ranks objects based on size, position, motion delta, and type.

### 👨‍💻 My Contribution

This project was a collaborative effort. I, **David Chung**, was responsible for the development of the iOS application in Swift. My key contributions included:

- **Developed the entire front-end using Swift and UIKit**, including the camera interface, live image preview, and user interaction flow.
- **Integrated real-time communication with the Python Flask server** via HTTP requests for image analysis and voice response.
- **Implemented voice output using `AVSpeechSynthesizer`** to provide accessible spoken feedback for visually impaired users.
- **Engineered efficient view controller logic**, including asynchronous data handling and UI updates to ensure a seamless user experience.
- **Led system integration efforts**, ensuring smooth coordination between client-side (iOS) and server-side (Flask) components. - **Utilized LiDAR technology** for enhanced scene understanding and spatial context recognition.
- **Optimized image capture and transmission pipeline** to minimize latency and maximize reliability, especially in mobile network conditions.
- **Streamlined memory usage and CPU overhead** in the app by profiling key UI interactions and leveraging lazy loading where applicable.
- **Focused on clean architecture, code reusability, and responsiveness**, adhering to iOS best practices for accessibility and performance.
  
## 🛠️ Technical Stack

| Component | Technology |
|----------|------------|
| iOS Frontend | Swift, ARKit, AVFoundation, UIKit |
| Server Backend | Flask, OpenCV, Ultralytics YOLOv8 |
| AI Model | YOLOv8m, DeepSort |
| Communication | HTTP POST (image bytes via `URLSession`) |
| Deployment | Local server + mobile client (tested on-device) |


## 📦 File Structure (Swift-side)

```
myEyes/
├── ViewController.swift       # ARKit scene logic, image capture, server calls, speech feedback
├── speakWords.swift           # Speech synthesis for detected object list
├── CurrentImage.swift         # Global image state (optional)
├── AppDelegate.swift          # Standard iOS app lifecycle
├── SceneDelegate.swift        # Scene routing setup
```


## 📈 System Flow

```text
[User holds phone] → [ARKit captures scene]
           ↓
[Depth map analyzed for obstacle warning]
           ↓
[Frame captured & sent to Python server]
           ↓
[YOLOv8 detects objects → ranks → returns JSON]
           ↓
[iOS reads top objects aloud & alerts user if needed]
```


## 🚀 How to Run

### iOS App (Swift)
1. Open `myEyes.xcodeproj` in Xcode.
2. Ensure you’re using a physical device (LiDAR supported).
3. Run the app.

### Python Server (Backend)
```bash
pip install -r requirements.txt
python sample_server.py
```
- Flask app listens on `http://<ip>:5058/detect`
- Accepts `POST` requests with JPEG image bytes.


## 🧠 Engineering Highlights

- ✅ Real-time depth sensing using `ARSceneDepth` and optimized pixel buffer traversal.
- ✅ Server communication throttled based on camera movement using `simd_distance()`.
- ✅ Efficient Swift concurrency with non-blocking LiDAR parsing.
- ✅ Fully modular object detection backend using YOLOv8 + Deep SORT.
- ✅ Custom heap prioritization in Python for object importance ranking.
- ✅ Speech synthesis with AVSpeechSynthesizer tuned for clarity and natural pacing.


## 💬 Why It Matters

> MyEyes empowers visually impaired users to better understand their surroundings using only a mobile phone—turning passive vision into active guidance. It’s built with performance, accessibility, and real-world application in mind.


