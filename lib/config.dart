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

// How often to poll the currency JSON for SDG manual updates (seconds).
// Keep this low (e.g. 30s) so manual edits on GitHub propagate fast to running apps.
const int sdgPollIntervalSeconds = 30;

// When SDG is manually changed via the GitHub JSON, keep that value locked
// locally for this many days before allowing automatic sources to overwrite it.
const int sdgLockDays = 3;
