
import zipfile
from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
from gtts import gTTS
import os
import pytesseract
import logging
from PIL import Image
import io
from lib._medico import Medico_, MedicineInfo
from pymongo import MongoClient
from bson import ObjectId
from datetime import datetime, timedelta

app = Flask(__name__)
CORS(app)
logging.basicConfig(level=logging.ERROR)

# MongoDB setup
client = MongoClient('mongodb://localhost:27017/')
db = client['medico_db']
schedules_collection = db['schedules']



def play_announcement(medicine_name, dosage):
    # This function would trigger the audio play on the device
    # For now, we'll just print a message
    print(f"Playing announcement for {medicine_name}: {dosage}")

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes
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

        # Save schedules to MongoDB
        # for med in result:
        #     schedule_id = schedules_collection.insert_one({
        #         'id': med['id'],
        #         'name': med['name'],
        #         'quantity': med['quantity'],
        #         'frequency': med['frequency'],
        #         'duration': med['duration'],
        #         'meal': med['meal'],
        #     })

        return jsonify({'medicine_details': result, 'extracted_text': extracted_text}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/schedules', methods=['GET', 'POST'])
def get_schedules():
    if request.method == 'GET' :
        schedules = list(schedules_collection.find())
        for schedule in schedules:
            schedule['_id'] = str(schedule['_id'])
        return jsonify(schedules), 200
    else:
        data = request.json
        if str(data.get("operation")) == "delete":
            medicine_id =data.get("id")
            schedules_collection.delete_one( { 'id': medicine_id})
        
        elif str(data.get("operation")) == "save":
            schedules_collection.insert_one({
                'id': MedicineInfo.genId(),
                'name': data.get("name"),
                'quantity': data['quantity'],
                'frequency': data['frequency'],
                'duration': data['duration'],
                'meal': data['meal'],
            })

        elif str(data.get("operation")) == "edit":
            schedules_collection.update_one(
                { 'id': data.get('id') }, 
                { "$set": {
                    'name': data.get("name"),
                    'quantity': data['quantity'],
                    'frequency': data['frequency'],
                    'duration': data['duration'],
                    'meal': data['meal'],
                  }
                },
            )
        return "Medicine is deleted", 200
            

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
                    
                    file_name = f"{name}_{quantity}.mp3" if quantity else f"{name}.mp3"
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
