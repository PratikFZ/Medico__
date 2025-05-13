import sys
from flask import Flask, request, jsonify
import requests
from bs4 import BeautifulSoup
from flask_cors import CORS

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Base URL for 1mg
BASE_URL = "https://www.1mg.com"
SEARCH_URL = f"{BASE_URL}/search/all"
HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
    "Accept-Language": "en-US,en;q=0.9",
}

def scrape_search_results(query):
    params = {"name": query}
    response = requests.get(SEARCH_URL, params=params, headers=HEADERS)
    
    if response.status_code != 200:
        raise Exception(f"Failed to fetch search results. Status code: {response.status_code}")
    
    soup = BeautifulSoup(response.text, 'html.parser')    
    # Try multiple potential selectors for product cards
    potential_selectors = [
        '.style__product-box___3oEU6',  # Original selector
        '.style__product-card___1gbex',  # Potential new selector
        '.style__product-grid___pPmE7',  # Another potential selector
        '.ProductCard__product-card___2OWfa',  # Another naming pattern
        'div[class*="product-card"]',  # Flexible CSS selector
        'div[class*="product-box"]',   # Flexible CSS selector
    ]
    
    medicine_cards = []
    for selector in potential_selectors:
        medicine_cards = soup.select(selector)
        if len(medicine_cards) > 0:
            print(f"Found medicine cards with selector: {selector}")
            break
    
    # If no cards found with specific selectors, try a more generic approach
    if len(medicine_cards) == 0:
        # Look for all div elements that have an image and might be product cards
        all_divs = soup.find_all('div')
        for div in all_divs:
            if div.find('img') and div.find('a'):
                medicine_cards.append(div)
        
        print(f"Found {len(medicine_cards)} potential product cards using generic approach")
    
    results = []
    for card in medicine_cards[:10]:  # Limit to first 10 results
        try:
            
            # Try multiple potential selectors for price
            price_elem = None
            for selector in ['.style__price-tag___KzOkY', '[class*="price"]', '[class*="mrp"]']:
                price_elem = card.select_one(selector)
                if price_elem:
                    break
                
            price = price_elem.text.strip() if price_elem else "Price not available"
            
            image_url =""
            container = card.select_one('.style__product-image___1bkgA')
            if container:
                image_elem = container.find('img')  # Find img inside this div
                print(f"Image element found: {image_elem}")
                image_url = image_elem['src'] if image_elem and 'src' in image_elem.attrs else "Image not available"
            
            # Only add to results if we have at least an ID and name
            if price != "Price not available":
                results.append({
                    "price": price,
                    "image_url": image_url,
                })
        except Exception as e:
            # Skip this item and continue with the next one
            print(f"Error processing item: {str(e)}")
            continue
    
    return results

if __name__ == "__main__":
    print(scrape_search_results("condoms"))