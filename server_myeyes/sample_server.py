from flask import Flask, request, jsonify
from PIL import Image
import io
import os

app = Flask(__name__)

# Directory to temporarily store uploaded images
UPLOAD_FOLDER = "uploads"
os.makedirs(UPLOAD_FOLDER, exist_ok=True)


@app.route('/detect', methods=['POST'])
def detect_objects():
    # Check if image data is in the request
    image_count= 0 
    if 'image' not in request.files and request.data:
        # Extract the image from raw byte stream
        image_data = request.data
        image = Image.open(io.BytesIO(image_data))
        
        # Save image to the temporary folder
        image_path = os.path.join(UPLOAD_FOLDER, 'received_image.jpg' + image_count)
        image_count +=1
        image.save(image_path)
        
        # Open the saved image to simulate processing
        print(f"Image saved at {image_path}")
        
        # Dummy processing (just for example)
        detected_objects = ["car", "person", "tree"]
        
        # Return a JSON response
        return jsonify({"detected_objects": detected_objects})
    
    return jsonify({"error": "No image data received"}), 400


if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5011)
