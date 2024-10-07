from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
from gtts import gTTS
import os
import pytesseract
import logging
from PIL import Image
import io
from lib._medico import Medico_
from pymongo import MongoClient
from bson import ObjectId
from apscheduler.schedulers.background import BackgroundScheduler
from datetime import datetime, timedelta

app = Flask(__name__)
CORS(app)
logging.basicConfig(level=logging.ERROR)

# MongoDB setup
client = MongoClient('mongodb://localhost:27017/')
db = client['medico_db']
schedules_collection = db['schedules']

# Scheduler setup
scheduler = BackgroundScheduler()
scheduler.start()

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
        for med in result:
            schedule_id = schedules_collection.insert_one({
                'name': med['name'],
                'quantity': med['quantity'],
                'frequency': med['frequency'],
                'duration': med['duration'],
                'meal': med['meal'],
                'created_at': datetime.now()
            }).inserted_id

            # Schedule announcements
            if med['frequency']:
                times_per_day = 1  # Default
                if 'twice' in med['frequency']:
                    times_per_day = 2
                elif 'thrice' in med['frequency']:
                    times_per_day = 3

                for i in range(times_per_day):
                    scheduler.add_job(
                        play_announcement,
                        'interval',
                        days=1,
                        start_date=datetime.now() + timedelta(hours=i*8),
                        args=[med['name'], med['quantity']]
                    )

        return jsonify({'medicine_details': result, 'extracted_text': extracted_text}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/schedules', methods=['GET', 'POST'])
def get_schedules():
    schedules = list(schedules_collection.find())
    for schedule in schedules:
        schedule['_id'] = str(schedule['_id'])
    return jsonify(schedules), 200

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
            # file_path = os.path.join("src/backend/assets",f"{medicine_name}_{dosage}.mp3")
            file_path = f"/home/pratik/My Projects/Medico_proj/src/backend/assets/{medicine_name}_{dosage}.mp3"
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
