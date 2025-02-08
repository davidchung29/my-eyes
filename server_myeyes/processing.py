import cv2
import pickle
import torch
import os
import time
import fnmatch
from PIL import Image
from ultralytics import YOLO
from deep_sort_realtime.deepsort_tracker import DeepSort
import heapq

class H:
    def __init__(self):
        self.heap = []
        self.lookup = {}

    def push(self, item):
        priority, key, value = item  
        if key in self.lookup:

            self.heap.remove(self.lookup[key])
            heapq.heapify(self.heap) 

        heapq.heappush(self.heap, item)
        self.lookup[key] = item

    def pop(self):
        if self.heap:
            item = heapq.heappop(self.heap)
            del self.lookup[item[1]]
            return item
        return None

    def __repr__(self):
        return str(self.heap)

q = {
    "person", "bicycle", "motorcycle", "bus", "truck", "traffic light",
    "fire hydrant", "stop sign", "parking meter", "bench", "chair", 
    "couch", "potted plant", "bed", "dining table", "toilet", 
    "book", "clock"
}

tracker = DeepSort(max_age = 3)

model = YOLO("yolov8m.pt")

def priority(area, object, d_area):
    if d_area:
        return round(area/100000 * max(1, (1 + 0.5*d_area)) * (1 + 0.25*(int(object in q))), 2)
    else:
        return round(0.4 * area / 100000 + 0.6 * (int(object in q)), 2)

## for frame-by-frame input:
def process(image_path):
    image = cv2.imread(image_path)
    height, width, channels = image.shape

    id_map = {}

    heap = H()

    results = model(image)

    detected = set()
    all_detected = []

    for result in results:
        for box in result.boxes:
            if (box.conf.item() >= 0.50):
                direction = " "
                x1, y1, x2, y2 = [int(x) for x in box.xyxy[0]]
                conf = box.conf.item()
                cls = int(box.cls[0])

                if (model.names[cls] == "tv" or model.names[cls] == "airplane" or model.names[cls] == "refrigerator" or model.names[cls] == "laptop" or model.names[cls] == "cell phone"):
                    continue
                
                else:
                    xcenter = x1 + abs(x1 - x2) / 2

                    all_detected.append(([x1, y1, x2, y2], conf, cls))
                    tracked_objects = tracker.update_tracks(all_detected, frame=image)

                    id = 0

                    if tracked_objects:
                        curr_track = tracked_objects[-1]
                        if curr_track.is_confirmed():
                            id = curr_track.track_id
                    
                    
                    if (xcenter > 0.25*width and xcenter < 0.75*width) or (xcenter < 0.25*width and x2 > 0.25*width) or (xcenter > 0.25*width and x1 < 0.75*width):
                        direction = " ahead"

                    else:
                        if xcenter > width/2:
                            direction = " right"
                        elif xcenter < width/2:
                            direction = " left"

                    area = abs((x1 - x2) * (y1 - y2))
                    d_area = None

                    if (id in id_map):
                        d_area = area - id_map[id]
                    detected.add(f"{model.names[cls] + direction}")
                    p = priority(area, model.names[cls], d_area)
                    cv2.rectangle(image, (x1, y1), (x2, y2), (255, 0, 0), 2) 
                    cv2.putText(image, f"{model.names[cls]+ direction} -- {p}", (x1, y1 - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 2)
                    cv2.imwrite(f'/Users/albertluo/Desktop/edu/cmu/my-eyes/server_myeyes/outputs/{image_path.split("/")[-1]}', image)

                    heap.push((p, model.names[cls], direction))

                    id_map[id] = area

        print(f"detected the following items: {detected}\n")

        l = []
        added = 0

        while heap.heap and added < 2:
            x = heap.pop()
            print(x)
            if x[2] != " ahead":
                continue
            else:
                if (x[1] == "dining table"):
                    l.append("table" + x[2])
                else:
                    l.append(x[1] + x[2])
                added += 1

        print(l)
        return list(set(l))