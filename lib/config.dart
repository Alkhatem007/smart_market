// Configuration values for the app.
// Update `currencyJsonUrl` to point to your hosted currency.json file on GitHub.
const String currencyJsonUrl =
    'https://raw.githubusercontent.com/alkhatem007/smart_market/main/api/currency.json';
// Per-page JSON endpoints hosted in this repository's `api/` folder.
// Update these URLs if you host the API elsewhere or change the branch/name.
const String homeJsonUrl =
    'https://raw.githubusercontent.com/alkhatem007/smart_market/main/api/home.json';

const String calculatorJsonUrl =
    'https://raw.githubusercontent.com/alkhatem007/smart_market/main/api/calculator.json';

const String goldJsonUrl =
    'https://raw.githubusercontent.com/alkhatem007/smart_market/main/api/gold.json';

const String cryptoJsonUrl =
    'https://raw.githubusercontent.com/alkhatem007/smart_market/main/api/crypto.json';

// A recommended realtime crypto endpoint (CoinGecko) for high-frequency updates.
// Use this instead of polling GitHub for crypto every few seconds to avoid rate limits.
const String cryptoRealtimeUrl =
    'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin%2Cethereum&vs_currencies=usd';
