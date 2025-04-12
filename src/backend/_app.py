import zipfile
from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
from gtts import gTTS
import os
import pytesseract
import logging
from PIL import Image
import io
from lib._medico import Medico_

app = Flask(__name__)
CORS(app)
logging.basicConfig(level=logging.ERROR)

@app.route('/ping', methods=['GET'])
def check():
    return "connected",200

@app.route('/process_image', methods=['POST'])
def process_image():
    try:
        if 'image' not in request.files:
            return jsonify({'error': 'No image part in the request'}), 400

        file = request.files['image']
        if file.filename == '':
            return jsonify({'error': 'No selected file'}), 400

        img = Image.open(io.BytesIO(file.read()))
        extracted_text = pytesseract.image_to_string(img)

        if not extracted_text.strip():
            return jsonify({'error': 'No text found in the image'}), 400

        medico = Medico_(extracted_text)
        medicine_details = medico.main(method="nlp")
        result = [med.__dict__ for med in medicine_details if med.name]

        print( result )
        return jsonify({'medicine_details': result}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500       

@app.route('/generate_audio', methods=['POST'])
def generate_audio():
    try:
        data = request.json
        medicines = data.get("medicines")
        
        if not medicines or not isinstance(medicines, list):
            return jsonify({"error": "Invalid or missing medicines data"}), 400

        zip_buffer = io.BytesIO()
        with zipfile.ZipFile(zip_buffer, 'w', zipfile.ZIP_DEFLATED) as zip_file:
            for medicine in medicines:
                id = medicine.get("id")
                name = medicine.get("name")
                quantity = medicine.get("quantity", "")
                
                if not name:
                    continue  # Skip if name is missing
                
                text = f"Take {quantity} of {name}" if quantity else f"Take {name}"
                
                try:
                    tts = gTTS(text)
                    audio_buffer = io.BytesIO()
                    tts.write_to_fp(audio_buffer)
                    audio_buffer.seek(0)
                    
                    file_name = f"{id}.mp3"
                    zip_file.writestr(file_name, audio_buffer.getvalue())
                except Exception as e:
                    logging.error(f"TTS generation error for {name}: {str(e)}", exc_info=True)
        
        zip_buffer.seek(0)
        return send_file(
            zip_buffer,
            mimetype='application/zip',
            as_attachment=True,
            download_name='tts_files.zip'
        )

    except Exception as e:
        logging.error("Unexpected error: ", exc_info=True)
        return jsonify({"error": f"An unexpected error occurred: {str(e)}"}), 500

if __name__ == '__main__':
    # Ensure Flask listens on all interfaces to be accessible on the network
    app.run(host='0.0.0.0', port=5000, debug=True)
