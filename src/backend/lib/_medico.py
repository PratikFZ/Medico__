import random
import string
import spacy
from spacy.tokens import Span
import pandas as pd
import re
from typing import List, Tuple, Dict, Optional
from dataclasses import dataclass, field
import json
from datetime import time
from lib.MedicineInfo import MedicineInfo

class Medico_:
    def __init__(self, text: str) -> None:
        self.text = text
        self.nlp = spacy.load('en_core_web_sm')
        self.ruler = self.nlp.add_pipe("entity_ruler", before="ner")
        self.LABELS = ["MEDICINE", "QUANTITY", "DURATION", "MEAL", "FREQUENCY"]
        self.file_path = 'src/backend/dataset/names.csv'
        df = pd.read_csv(self.file_path)
        self.medicine_list = set(df['name'].str.lower())

    def setSchedule( self, medilist: List[MedicineInfo] ) -> None:
        for med in medilist:
            if '3' in med.frequency or 'thrice' in med.frequency:
                med.schedules = [{ 'hrs': 8, 'min': 0}, { 'hrs': 12, 'min': 30}, { 'hrs': 20, 'min': 0} ]
            elif '2' in med.frequency or 'twice' in med.frequency:
                med.schedules = [{ 'hrs': 8, 'min': 0}, { 'hrs': 20, 'min': 0}]
            elif '1' in med.frequency or 'once' in med.frequency:
                med.schedules = [{ 'hrs': 8, 'min': 0} ]
            else :
                med.schedules = [{ 'hrs': 20, 'min': 0}]

    def _preprocess_text(self) -> str:
        # Convert to lowercase and remove extra whitespace
        return re.sub(r'\s+', ' ', self.text.lower().strip())

    def extractMedicineName(self) -> List[str]:
        words = re.findall(r'\b\w+\b', self.text.lower())
        # drug_matches = find_drugs([t.text for t in doc], is_ignore_case=True)
        # return list(set([drug[0]['name'] for drug in drug_matches]))
        results = []

        for i, word in enumerate(words):
            for j in range(i, min(i + 4, len(words))):
                phrase = ' '.join(words[i:j+1])
                if phrase in self.medicine_list:
                    results.append(phrase)

        return results

    def _create_regex_pattern(self, medicine_names: List[str]) -> str:
        medicine_pattern = '|'.join(re.escape(medicine) for medicine in medicine_names)
        return fr'\b({medicine_pattern})\s*(\d+(?:\.\d+)?(?:\s*mg|\s*ml|\s*g)|\d+\s*(?:tablet|tab|capsule|cap)|single|half)?\s*(\d+\s*(?:days?|weeks?|months?))?\s*(before|after|with|anytime)?\s*((?:once|twice|thrice|(\d+\s*times?))\s*(?:daily|a day|weekly|monthly))?'

    def extractThroughRegex(self, medicine_names: List[str]) -> List[MedicineInfo]:
        pattern = self._create_regex_pattern(medicine_names)
        matches = re.findall(pattern, self._preprocess_text())
        return [MedicineInfo(
            name=match[0],
            quantity=match[1] if match[1] else '',
            duration=match[2] if match[2] else '',
            meal=match[3] if match[3] else 'anytime',
            frequency=match[4] if match[4] else '',
            id=MedicineInfo.genId(),
        ) for match in matches]

    def _create_nlp_patterns(self, medicine_names: List[str]) -> List[Dict]:
        patterns = []
        for medicine in medicine_names:
            patterns.append({"label": "MEDICINE", "pattern": medicine.lower()})

        patterns.extend([
            {"label": "QUANTITY", "pattern": [{"IS_DIGIT": True}, {"LOWER": {"IN": ["mg", "ml", "g", "tab", "tabs", "tbs", "tps", "tablet", "tablets", "capsule", "capsules"]}}]},
            {"label": "QUANTITY", "pattern": [{"LOWER": {"IN": ["single", "half"]}}]},
            {"label": "DURATION", "pattern": [{"IS_DIGIT": True}, {"LOWER": {"IN": ["day", "days", "week", "weeks", "month", "months"]}}]},
            {"label": "MEAL", "pattern": [{"LOWER": {"IN": [ "before","after", "with", "on empty stomach","anytime"]}}, {"LOWER": {"IN": [ "meals", "breakfast", "lunch", "dinner"]}} ]},
            {"label": "FREQUENCY", "pattern": [{"LOWER": {"IN": ["once", "twice", "thrice"]}}, {"LOWER": {"IN": ["daily", "a day", "weekly", "monthly"]}}]},
            {"label": "FREQUENCY", "pattern": [{"IS_DIGIT": True}, {"LOWER": "times"}, {"LOWER": {"IN": ["daily", "a day", "weekly", "monthly"]}}]}
        ])
        return patterns

    def extractThroughNLP(self, medicine_names: List[str]) -> List[MedicineInfo]:
        self.ruler.clear()
        self.ruler.add_patterns(self._create_nlp_patterns(medicine_names))
        doc = self.nlp(self._preprocess_text())

        medicine_details: Dict[str, MedicineInfo] = {med.lower(): MedicineInfo(name=med, id=MedicineInfo.genId()) for med in medicine_names}

        current_medicine = None
        for ent in doc.ents:
            if ent.label_ == "MEDICINE":
                current_medicine = ent.text.lower()
            elif current_medicine:
                if ent.label_ == "QUANTITY":
                    medicine_details[current_medicine].quantity = ent.text
                elif ent.label_ == "DURATION":
                    medicine_details[current_medicine].duration = ent.text
                elif ent.label_ == "MEAL":
                    medicine_details[current_medicine].meal = ent.text
                elif ent.label_ == "FREQUENCY":
                    medicine_details[current_medicine].frequency = ent.text

        self.setSchedule(list(medicine_details.values()))
            
        return list(medicine_details.values())

    def extractMedicineDetails(self, medicine_names: List[str], method: str = "nlp") -> List[MedicineInfo]:
        if method.lower() == "nlp":
            return self.extractThroughNLP(medicine_names)
        elif method.lower() == "regex":
            return self.extractThroughRegex(medicine_names)
        else:
            raise ValueError("Invalid method. Choose 'nlp' or 'regex'.")

    def main(self, method: str = "nlp") -> List[MedicineInfo]:
        medicine_names = self.extractMedicineName()
        return self.extractMedicineDetails(medicine_names, method)

# Example usage
if __name__ == "__main__":
    text = '''
    Take Augmentin 625 Duo Tablet 2 tab after meals for 7 days twice daily.
    Sucraday O Syrup 60 ml once daily 3 days .
    '''
    medico = Medico_(text)
    results = medico.main()
    for result in results:
        print(result)