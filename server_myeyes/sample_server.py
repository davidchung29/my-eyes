from flask import Flask, request, jsonify
from PIL import Image
import io
import os
import uuid
import processing
import json

app = Flask(__name__)

# Directory to temporarily store uploaded images
UPLOAD_FOLDER = "uploads"
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

received = 0

@app.route('/detect', methods=['POST'])
def detect_objects():
    global received
    received += 1
    # Handle file uploads or raw image bytes
    if 'image' in request.files:
        image = Image.open(request.files['image'])
    elif request.data:
        image_data = request.data
        image = Image.open(io.BytesIO(image_data))
    else:
        return jsonify({"error": "No image data received"}), 400

    # Generate a unique filename
    if received % 2 == 0:
        image_path = os.path.join(UPLOAD_FOLDER, f'received_image_{uuid.uuid4().hex}.jpg')
        
        # Save the image

        image.save(image_path)

        detected_objects = processing.process(image_path)
        
        print(f"Image saved at {image_path}")
        
        # Dummy processing (just for example)
        
        # Return a JSON response
        print(list(set(detected_objects)))
        print({"detected_objects": detected_objects})
        os.remove(image_path)
        return jsonify({"detected_objects": detected_objects})
    
    else:
        return []
    


if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5058)
