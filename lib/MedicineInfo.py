import random
from typing import List, Dict
import re
from dataclasses import dataclass, field
import json

@dataclass
class MedicineInfo:
    name: str
    id: int 
    quantity: str = ""
    duration: int = 1
    meal: str = "anytime"
    frequency: str = ""
    schedules: List[Dict] = field(default_factory=list)

    def fromJson( self, data ) -> None:
        self.id = data.get("id")
        self.name = data.get("name")
        self.quantity = data.get("quantity")
        self.duration = data.get("duration")
        self.meal = data.get("meal")
        self.frequency = data.get("frequency")
    
    # def toJson( self) -> str:
    #     return json.dumps({
    #         'id': self.id,
    #         'name': self.name,
    #         'quantity': self.quantity,
    #         'frequency': self.frequency,
    #         'duration': self.duration,
    #         'meal': self.meal,
    #         'schedules': [{"hour": t['hrs'], "minute": t['min']} for t in self.schedules]
    #     })

    def genId() -> int:
        return random.randint(1000000, 9999999)
    
    def toJson(self) -> str:
        # Extract numeric value from duration string and convert to int
        duration_int = self._parse_duration_to_int(self.duration)
        
        return json.dumps({
            'id': self.id,
            'name': self.name,
            'quantity': self.quantity,
            'frequency': self.frequency,
            'duration': duration_int,  # Now sending an integer
            'meal': self.meal,
            'schedules': [{"hour": t['hrs'], "minute": t['min']} for t in self.schedules]
        })

    def _parse_duration_to_int(self, duration_str: str) -> int:
        """Convert duration string to integer (in days)"""
        if not duration_str:
            return 1  # Default value when duration is not specified
            
        # Remove any leading/trailing whitespace
        duration_str = duration_str.strip().lower()
        
        # Handle word numbers
        word_to_number = {
            'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5,
            'six': 6, 'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10
        }
        
        if duration_str in word_to_number:
            return word_to_number[duration_str]
        
        # Extract numeric part using regex
        match = re.search(r'(\d+)', duration_str)
        if match:
            number = int(match.group(1))
            
            # Check if weeks or months and convert to days
            if 'week' in duration_str:
                return number * 7
            elif 'month' in duration_str:
                return number * 30
            else:
                return number  # Assume days if not specified
                
        return 1  # Return default if no number found