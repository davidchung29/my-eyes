import cv2
import pickle
from ultralytics import YOLO
from deep_sort_realtime.deepsort_tracker import DeepSort

model = YOLO("yolov8n.pt")

## for frame-by-frame input:
image_path = "/Users/albertluo/Desktop/edu/cmu/my-eyes/random-test-stuff/105000590_prevstillhigh.jpeg"
image = cv2.imread(image_path)

results = model(image)

detected = set()

for result in results:
    for box in result.boxes:
        x1, y1, x2, y2 = map(int, box.xyxy[0])
        cls = int(box.cls[0])
        detected.add(f"{model.names[cls]}")
        cv2.rectangle(image, (x1, y1), (x2, y2), 255, 2)
        area = abs((x1 - x2) * (y1 - y2))
        cv2.putText(image, f"area: {area/1000}", (x1, y1 - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 2)

print(detected)
cv2.imwrite("output.jpg", image)
while cv2.waitKey(1) & 0xFF != ord('q'):
    cv2.imshow("YOLO Detection", image)
cv2.destroyAllWindows()

## for video input:

# # Open the video file
# video_path = "/Users/albertluo/Desktop/edu/cmu/my-eyes/random-test-stuff/People Walking Free Stock Footage, Royalty-Free No Copyright Content 720.mp4"
# cap = cv2.VideoCapture(video_path)

# # Get video properties
# frame_width = int(cap.get(3))
# frame_height = int(cap.get(4))
# fps = int(cap.get(cv2.CAP_PROP_FPS))

# # Define the codec and create VideoWriter to save output
# out = cv2.VideoWriter("random_people_walking_output_video.mp4", cv2.VideoWriter_fourcc(*'mp4v'), fps, (frame_width, frame_height))

# # Process video frame by frame
# while cap.isOpened():
#     success, frame = cap.read()
#     if not success:
#         break  # Break if video ends

#     # Run YOLO on the frame
#     results = model(frame)

#     # Draw bounding boxes
#     for result in results:
#         for box in result.boxes:
#             x1, y1, x2, y2 = map(int, box.xyxy[0])  # Bounding box coordinates
#             conf = box.conf[0].item()  # Confidence score
#             cls = int(box.cls[0])  # Class index
#             label = f"{model.names[cls]} {conf:.2f}"

#             # Draw rectangle and label
#             cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 255, 0), 2)
#             cv2.putText(frame, label, (x1, y1 - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 2)

#     # Write the frame to output video
#     out.write(frame)

#     # Display the frame (optional)
#     cv2.imshow("YOLO Video", frame)
#     if cv2.waitKey(1) & 0xFF == ord('q'):  # Press 'q' to exit early
#         break

# # Release resources
# cap.release()
# out.release()
# cv2.destroyAllWindows()
