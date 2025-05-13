import cv2
import pytesseract

class HandwrittenOCR:
    def __init__(self, image_path):
        self.image_path = image_path

    def preprocess_image(self):
        # Read the image
        image = cv2.imread(self.image_path)

        # Convert to grayscale
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

        # Apply Gaussian Blur to reduce noise
        blurred = cv2.GaussianBlur(gray, (5, 5), 0)

        # Apply thresholding to binarize the image (adaptive thresholding works well with handwriting)
        thresh = cv2.adaptiveThreshold(blurred, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY, 11, 2)

        # Return the preprocessed image
        return thresh

    def extract_text(self):
        # Preprocess the image
        preprocessed_image = self.preprocess_image()

        # Use Tesseract to extract text
        text = pytesseract.image_to_string(preprocessed_image, config='--psm 6')  # Use page segmentation mode 6 for uniform text blocks
        return text

# # Example usage:
# ocr = HandwrittenOCR('/content/medical-prescription-rx-form-realistic-paper-sheet_8071-26259~2.jpg')
# extracted_text = ocr.extract_text()
# print(extracted_text)
