import cv2
import pickle
import torch
import os
import time
import fnmatch
from ultralytics import YOLO
# from deep_sort_realtime.deepsort_tracker import DeepSort
from heapq import heapify, heappop, heappush, nlargest


q = {
    "person", "bicycle", "motorcycle", "bus", "truck", "traffic light",
    "fire hydrant", "stop sign", "parking meter", "bench", "chair", 
    "couch", "potted plant", "bed", "dining table", "toilet", 
    "refrigerator", "book", "clock", "vase", "teddy bear"
}

model = YOLO("yolo11n.pt")

def priority(area, object):
    return 0.4 * area + 0.6 * (int(object in q))

## for frame-by-frame input:
def process(image_path):
    image = cv2.imread(image_path)
    height, width, channels = image.shape

    heap = []

    results = model(image)

    detected = set()

    for result in results:
        for box in result.boxes:
            if (box.conf.item() >= 0.70):
                direction = " "
                x1, y1, x2, y2 = map(int, box.xyxy[0])
                xcenter = x1 + abs(x1 - x2) / 2
                ycenter = y1 + abs(y1 - y2) / 2

                if xcenter > width/2:
                    direction += "right "
                elif xcenter < width/2:
                    direction += "left "
                
                # if ycenter > height/2:
                #     direction += "up"
                # elif ycenter < height/2:
                #     direction += " down"
                
                cls = int(box.cls[0])
                detected.add(f"{model.names[cls]}")
                cv2.rectangle(image, (x1, y1), (x2, y2), 255, 2)
                area = abs((x1 - x2) * (y1 - y2))
                cv2.putText(image, f"area: {area/100000}", (x1, y1 - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 2)
                p = priority(area, model.names[cls])
                heappush(heap, (p, model.names[cls]))

    print(f"detected the following items: {detected}\n")
    print(f"top priority objects: {[str(x) for x in list(heap[:3])]}")
    cv2.destroyAllWindows()

    return [str(x[1] + direction) for x in list(heap[:3])]
