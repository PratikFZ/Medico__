FROM python:3.11-rc-slim-bullseye

WORKDIR /app
COPY . /app

RUN pip install -r requirements.txt
RUN apt-get update && apt-get install tesseract-ocr -y
RUN python -m spacy download en_core_web_sm

CMD ["python", "_app.py"]