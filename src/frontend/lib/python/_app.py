# ocr_tts_server.py
from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
from gtts import gTTS
import os
import pytesseract
import logging
from PIL import Image
import io
from _medico import Medico_  # Ensure medico.py is in the same directory or properly referenced

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes
logging.basicConfig(level=logging.ERROR)

@app.route('/process_image', methods=['POST'])
def process_image():
    try:
        # Check if the post request has the file part
        if 'image' not in request.files:
            return jsonify({'error': 'No image part in the request'}), 400

        file = request.files['image']
        if file.filename == '':
            return jsonify({'error': 'No selected file'}), 400

        # Read image file
        img = Image.open(io.BytesIO(file.read()))
        # Perform OCR using Tesseract
        extracted_text = pytesseract.image_to_string(img)

        if not extracted_text.strip():
            return jsonify({'error': 'No text found in the image'}), 400

        # Initialize Medico class with extracted text
        medico = Medico_(extracted_text)
        # Extract medicine details using NLP method (default)
        medicine_details = medico.main(method="nlp")

        # Convert dataclass instances to dictionaries
        result = [med.__dict__ for med in medicine_details if med.name]

        return jsonify({'medicine_details': result, 'extracted_text': extracted_text}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/generate_audio', methods=['POST'])
def generate_audio():
    try:
        data = request.json
        medicine_name = data.get("medicine_name")
        dosage = data.get("dosage")

        if not medicine_name or not dosage:
            return jsonify({"error": "MedicineName and dosage are required"}), 400

        text = f"Take {dosage} of {medicine_name}"
        
        try:
            tts = gTTS(text)
            file_path = os.path.join("/home/pratik/My Projects/Medico_proj/Flutter/medico/lib/python/assets",f"{medicine_name}_{dosage}.mp3")
            tts.save(file_path)
        except Exception as e:
            logging.error("TTS generation error: ", exc_info=True)
            return jsonify({"error": f"Text-to-Speech generation failed: {str(e)}"}), 500
        
        if not os.path.exists(file_path):
            logging.error("TTS generation error: ", exc_info=True)
            return jsonify({"error": "MP3 file not found"}), 404

        return send_file(file_path, as_attachment=True)

    except Exception as e:
        logging.error("Unexpected error: ", exc_info=True)
        return jsonify({"error": f"An unexpected error occurred: {str(e)}"}), 500


if __name__ == '__main__':
    # Ensure Flask listens on all interfaces to be accessible on the network
    app.run(host='0.0.0.0', port=5000, debug=True)
