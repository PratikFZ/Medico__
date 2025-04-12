from flask import Flask, request, jsonify
import time
import random
import threading
from flask_cors import CORS
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException, NoSuchElementException, StaleElementReferenceException
import concurrent.futures
import os
import queue

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Base URL for 1mg
BASE_URL = "https://www.1mg.com"
SEARCH_URL = f"{BASE_URL}/search/all"

# Advanced WebDriver pool with pre-warming
MAX_POOL_SIZE = 5  # Adjust based on server resources
driver_pool = queue.Queue(maxsize=MAX_POOL_SIZE)
pool_lock = threading.Lock()

# Configure Chrome options for maximum performance
def create_optimized_driver():
    chrome_options = Options()
    chrome_options.add_argument("--headless")
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    chrome_options.add_argument("--disable-gpu")
    chrome_options.add_argument("--window-size=1920,1080")  # Larger window for better content loading
    chrome_options.add_argument("--disable-extensions")
    chrome_options.add_argument("--disable-infobars")
    chrome_options.add_argument("--disable-notifications")
    chrome_options.add_argument("--disable-popup-blocking")
    
    # Only disable images, keep CSS and JS enabled for proper page rendering
    chrome_prefs = {
        "profile.default_content_setting_values": {
            "images": 2,  # 2 = block images
            "javascript": 1,  # 1 = allow JavaScript (needed for dynamic content)
        },
        "profile.managed_default_content_settings.images": 2
    }
    chrome_options.add_experimental_option("prefs", chrome_prefs)
    
    # Add user agent to appear more like a regular browser
    chrome_options.add_argument("--user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Safari/537.36")
    
    # Create and return the driver
    driver = webdriver.Chrome(options=chrome_options)
    driver.set_page_load_timeout(20)  # Increased timeout for better loading
    driver.set_script_timeout(15)  # Increased script timeout
    
    return driver

# Initialize the driver pool
def initialize_driver_pool():
    for _ in range(MAX_POOL_SIZE):
        try:
            driver = create_optimized_driver()
            # Pre-warm by loading the base site
            driver.get(BASE_URL)
            driver_pool.put(driver)
            print(f"Added driver to pool (size: {driver_pool.qsize()})")
        except Exception as e:
            print(f"Error initializing driver: {str(e)}")

# Get a driver from the pool or create a new one if needed
def get_driver():
    try:
        return driver_pool.get(block=False)
    except queue.Empty:
        print("Pool empty, creating new driver")
        return create_optimized_driver()

# Return a driver to the pool
def return_driver(driver):
    try:
        # Clear cookies and cache before returning
        driver.delete_all_cookies()
        driver_pool.put(driver, block=False)
        print(f"Returned driver to pool (size: {driver_pool.qsize()})")
    except queue.Full:
        print("Pool full, quitting driver")
        driver.quit()

# Cache system to avoid repeated scraping
medicine_cache = {}
CACHE_EXPIRY = 3600  # 1 hour cache expiry

@app.route('/api/search', methods=['GET'])
def search_medicine():
    query = request.args.get('query')
    if not query:
        return jsonify({"error": "Query parameter is required"}), 400
    
    # Check cache first
    cache_key = f"search_{query}"
    if cache_key in medicine_cache and time.time() - medicine_cache[cache_key]['timestamp'] < CACHE_EXPIRY:
        print(f"Returning cached results for {query}")
        return jsonify({"results": medicine_cache[cache_key]['data'], "fromCache": True})
    
    driver = None
    try:
        driver = get_driver()
        results = scrape_search_results(driver, query)
        
        # Update cache
        medicine_cache[cache_key] = {
            'data': results,
            'timestamp': time.time()
        }
        
        return jsonify({"results": results})
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        if driver:
            return_driver(driver)

# Optimized search function with improved selectors
def scrape_search_results(driver, query):
    search_url = f"{SEARCH_URL}?name={query}"
    print(f"Searching for: {query} at URL: {search_url}")
    
    driver.get(search_url)
    
    # Wait for page to load properly - use a more generic selector
    try:
        WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.CSS_SELECTOR, "div.style__product-box___3oEU6, div.style__container___cTDz0, div[class*='product-card'], div[class*='style__product-box']"))
        )
    except TimeoutException:
        print("Timed out waiting for product elements, attempting extraction anyway")
    
    # Scroll down to load more results (1mg uses lazy loading)
    for _ in range(3):
        driver.execute_script("window.scrollTo(0, document.body.scrollHeight);")
        time.sleep(0.5)  # Small pause to allow content to load
    
    # Scroll back to top
    driver.execute_script("window.scrollTo(0, 0);")
    
    # Try multiple selectors to find product cards
    selectors = [
        "div.style__product-box___3oEU6",  # Common 1mg selector
        "div.style__container___cTDz0",    # Another common 1mg container
        "div[class*='product-card']",      # Generic product card
        "div[class*='style__product-box']", # Style-based selector
        "div[class*='ProductCard']",       # CamelCase naming
        "div[class*='product-grid'] > div", # Grid items
        "div[class*='search-card']",       # Search result cards
        "div[class*='row'] > div[class*='col'] > div"  # Bootstrap-style grid
    ]
    
    medicine_cards = []
    for selector in selectors:
        try:
            cards = driver.find_elements(By.CSS_SELECTOR, selector)
            print(f"Selector '{selector}' found {len(cards)} elements")
            if cards:
                medicine_cards = cards
                break
        except Exception as e:
            print(f"Error with selector {selector}: {str(e)}")
            continue
    
    if not medicine_cards:
        print("No cards found with standard selectors, trying JavaScript fallback")
        try:
            # More robust JavaScript approach to find product elements
            medicine_cards = driver.execute_script("""
                // First try to identify the main product container
                let productContainers = document.querySelectorAll('div[class*="product-grid"], div[class*="search-result"], div[class*="product-list"]');
                
                if (productContainers.length === 0) {
                    // If no container found, look for product cards directly
                    return Array.from(document.querySelectorAll('div')).filter(el => {
                        if (!el.className) return false;
                        const className = el.className.toLowerCase();
                        const hasProductClass = className.includes('product') || className.includes('card') || className.includes('item');
                        const hasImage = el.querySelector('img') !== null;
                        const hasText = el.textContent.trim().length > 0;
                        const isDeep = el.querySelectorAll('*').length > 5; // Must have some depth
                        return hasProductClass && hasImage && hasText && isDeep;
                    });
                } else {
                    // Find child elements that are likely product cards
                    let allCards = [];
                    productContainers.forEach(container => {
                        // Try direct children first
                        let directChildren = Array.from(container.children).filter(child => 
                            child.tagName === 'DIV' && 
                            child.querySelectorAll('*').length > 5
                        );
                        
                        if (directChildren.length > 0) {
                            allCards = allCards.concat(directChildren);
                        } else {
                            // Try deeper children if direct ones don't look like cards
                            let deeperCards = Array.from(container.querySelectorAll('div')).filter(el =>
                                el.querySelectorAll('*').length > 5 &&
                                el.querySelectorAll('div').length > 2 &&
                                el.querySelector('img') !== null
                            );
                            allCards = allCards.concat(deeperCards);
                        }
                    });
                    return allCards;
                }
            """)
            print(f"JavaScript fallback found {len(medicine_cards)} elements")
        except Exception as e:
            print(f"JavaScript extraction failed: {str(e)}")
            medicine_cards = []
    
    print(f"Total medicine cards found: {len(medicine_cards)}")
    
    # Take up to 15 cards to ensure we get at least 10 valid results
    cards_to_process = medicine_cards[:15]
    
    results = []
    for index, card in enumerate(cards_to_process):
        try:
            print(f"Processing card {index+1}/{len(cards_to_process)}")
            
            # First try with high-level JavaScript extraction
            card_data = driver.execute_script("""
                function extractCardData(card) {
                    // Find title/name - test multiple patterns
                    let name = null;
                    const nameSelectors = [
                        'h2', 'h3', 'h4',
                        '[class*="product-title"]', '[class*="pro-title"]', 
                        '[class*="name"]', '[class*="title"]',
                        'a[class*="product"]', 'a strong', 'div[class*="name"]'
                    ];
                    
                    for (let selector of nameSelectors) {
                        let nameElem = card.querySelector(selector);
                        if (nameElem && nameElem.textContent.trim()) {
                            name = nameElem.textContent.trim();
                            break;
                        }
                    }
                    
                    // If no name found, try getting the most prominent text
                    if (!name) {
                        const textNodes = Array.from(card.querySelectorAll('*'))
                            .filter(el => el.textContent.trim() && el.children.length < 3)
                            .map(el => el.textContent.trim())
                            .filter(text => text.length > 5 && text.length < 100);
                        
                        if (textNodes.length > 0) {
                            name = textNodes[0];
                        }
                    }
                    
                    if (!name) name = "Unknown Product";
                    
                    // Find link and ID
                    let link = null;
                    let medicine_id = null;
                    
                    // First check if the card itself is a link or has a main link
                    if (card.tagName === 'A' && card.href) {
                        link = card.href;
                    } else {
                        const linkSelectors = ['a', 'a[href*="product"]', 'a[href*="medicine"]', 'a[href*="/"]'];
                        for (let selector of linkSelectors) {
                            const linkElem = card.querySelector(selector);
                            if (linkElem && linkElem.href) {
                                link = linkElem.href;
                                break;
                            }
                        }
                    }
                    
                    if (link) {
                        // Extract ID from URL
                        const urlParts = link.split('/');
                        medicine_id = urlParts.pop() || urlParts.pop(); // Get last non-empty segment
                        
                        // Clean up ID if it has query parameters
                        if (medicine_id.includes('?')) {
                            medicine_id = medicine_id.split('?')[0];
                        }
                    }
                    
                    // Find price with multiple patterns
                    let price = null;
                    const priceSelectors = [
                        '[class*="price"]', '[class*="mrp"]', '[class*="amount"]',
                        'span[class*="style__price"]', 'span[class*="discount"]',
                        'div[class*="price"]', 'span[class*="final"]'
                    ];
                    
                    for (let selector of priceSelectors) {
                        const priceElems = card.querySelectorAll(selector);
                        for (let priceElem of priceElems) {
                            const text = priceElem.textContent.trim();
                            // Look for currency symbol or typical price pattern
                            if (text && (text.includes('₹') || text.includes('Rs') || /^\s*[₹R₨]\.?\s*\d+/.test(text))) {
                                price = text;
                                break;
                            }
                        }
                        if (price) break;
                    }
                    
                    if (!price) price = "Price not available";
                    
                    // Find manufacturer/maker with multiple patterns
                    let manufacturer = null;
                    const mfrSelectors = [
                        '[class*="manufacturer"]', '[class*="company"]', '[class*="maker"]',
                        '[class*="seller"]', '[class*="brand"]', 'span.product-name'
                    ];
                    
                    for (let selector of mfrSelectors) {
                        const mfrElem = card.querySelector(selector);
                        if (mfrElem && mfrElem.textContent.trim()) {
                            manufacturer = mfrElem.textContent.trim();
                            break;
                        }
                    }
                    
                    // If no specific manufacturer found, try identifying secondary text that might be it
                    if (!manufacturer) {
                        const allTexts = Array.from(card.querySelectorAll('*'))
                            .map(el => el.textContent.trim())
                            .filter(text => text.length > 0 && text !== name && text !== price);
                            
                        // Often the manufacturer is a short text different from name and price
                        const possibleMfrs = allTexts.filter(t => t.length < 50 && t.length > 2);
                        if (possibleMfrs.length > 0) {
                            manufacturer = possibleMfrs[0];
                        }
                    }
                    
                    if (!manufacturer) manufacturer = "Unknown Manufacturer";
                    
                    // Find image URL
                    let image_url = null;
                    const imgElems = card.querySelectorAll('img');
                    
                    for (let img of imgElems) {
                        // Get the image source (trying multiple possible attributes)
                        const src = img.src || img.dataset.src || img.getAttribute('src') || img.getAttribute('data-src');
                        if (src && (src.includes('.jpg') || src.includes('.png') || src.includes('.webp'))) {
                            image_url = src;
                            break;
                        }
                    }
                    
                    // Format image URL if needed
                    if (image_url) {
                        if (image_url.startsWith('//')) {
                            image_url = "https:" + image_url;
                        } else if (!image_url.startsWith('http')) {
                            image_url = "https://www.1mg.com" + (image_url.startsWith('/') ? '' : '/') + image_url;
                        }
                    } else {
                        image_url = ""; // No image found
                    }
                    
                    // Clean up URL if it has one
                    if (link && !link.startsWith('http')) {
                        link = "https://www.1mg.com" + (link.startsWith('/') ? '' : '/') + link;
                    }
                    
                    return {
                        id: medicine_id || `product-${Date.now()}-${Math.floor(Math.random() * 1000)}`,
                        name: name,
                        price: price,
                        manufacturer: manufacturer,
                        image_url: image_url,
                        product_url: link || ""
                    };
                }
                
                return extractCardData(arguments[0]);
            """, card)
            
            # Validate the data and add to results
            if card_data and card_data['name'] != "Unknown Product":
                print(f"Found valid product: {card_data['name']}")
                results.append(card_data)
            else:
                print("Skipping invalid product data")
            
        except Exception as e:
            print(f"Error extracting card data: {str(e)}")
            continue
    
    # Ensure we have unique results by ID or name
    unique_results = []
    seen_ids = set()
    seen_names = set()
    
    for result in results:
        # Generate a composite key from name and ID
        key = result['id'] + '|' + result['name']
        
        if key not in seen_ids and result['name'] not in seen_names:
            seen_ids.add(key)
            seen_names.add(result['name'])
            unique_results.append(result)
    
    print(f"Final unique results count: {len(unique_results)}")
    return unique_results[:10]  # Limit to 10 results

@app.route('/api/popular', methods=['GET'])
def get_popular_medicines():
    """Endpoint to get popular medicines (pre-cached for speed)"""
    # Check if we have cached popular medicines
    cache_key = "popular_medicines"
    if cache_key in medicine_cache and time.time() - medicine_cache[cache_key]['timestamp'] < CACHE_EXPIRY:
        return jsonify({"results": medicine_cache[cache_key]['data']})
    
    # Popular medicine search terms
    popular_terms = ["paracetamol", "vitamin", "crocin", "dolo", "aspirin", "cough syrup"]
    
    # Randomly select one term for variety
    term = random.choice(popular_terms)
    
    driver = None
    try:
        driver = get_driver()
        results = scrape_search_results(driver, term)
        
        # Cache the results
        medicine_cache[cache_key] = {
            'data': results,
            'timestamp': time.time()
        }
        
        return jsonify({"results": results})
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        if driver:
            return_driver(driver)

@app.route('/api/clear-cache', methods=['POST'])
def clear_cache():
    """Endpoint to clear the cache"""
    global medicine_cache
    medicine_cache = {}
    return jsonify({"message": "Cache cleared successfully"})

@app.route('/api/health', methods=['GET'])
def health_check():
    """Endpoint to check the health of the service"""
    return jsonify({
        "status": "healthy",
        "active_drivers": driver_pool.qsize(),
        "max_pool_size": MAX_POOL_SIZE,
        "cache_entries": len(medicine_cache),
        "uptime": time.time() - start_time
    })

# Track application start time
start_time = time.time()

if __name__ == '__main__':
    # Start a thread to initialize the driver pool
    threading.Thread(target=initialize_driver_pool, daemon=True).start()
    
    # Register cleanup handler for when the application exits
    import atexit
    
    def cleanup_on_exit():
        print("Cleaning up WebDriver instances...")
        while not driver_pool.empty():
            try:
                driver = driver_pool.get(block=False)
                driver.quit()
            except:
                pass
    
    atexit.register(cleanup_on_exit)
    
    # Run the Flask app
    app.run(debug=True, host='0.0.0.0', port=5000)