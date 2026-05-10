/**
 * IPFS utility for uploading and fetching transaction descriptions.
 *
 * Uploads description JSON to Pinata (IPFS pinning service) and retrieves
 * it via public IPFS gateways.
 *
 * Authentication supports two modes:
 *   1. JWT — set VITE_PINATA_JWT (long eyJ... token)
 *   2. Legacy API key + secret — set VITE_PINATA_API_KEY and VITE_PINATA_API_SECRET
 */

const PINATA_JWT = import.meta.env.VITE_PINATA_JWT || '';
const PINATA_API_KEY = import.meta.env.VITE_PINATA_API_KEY || '';
const PINATA_API_SECRET = import.meta.env.VITE_PINATA_API_SECRET || '';

const PINATA_PIN_URL = 'https://api.pinata.cloud/pinning/pinJSONToIPFS';

// Multiple gateways for reliability when fetching content
const IPFS_GATEWAYS = [
  'https://gateway.pinata.cloud/ipfs/',
  'https://ipfs.io/ipfs/',
  'https://cloudflare-ipfs.com/ipfs/',
  'https://dweb.link/ipfs/',
];

/**
 * Builds the Pinata auth headers based on available credentials.
 * Prefers JWT if available, otherwise falls back to API key + secret.
 */
function getPinataAuthHeaders() {
  if (PINATA_JWT) {
    return { Authorization: `Bearer ${PINATA_JWT}` };
  }
  if (PINATA_API_KEY && PINATA_API_SECRET) {
    return {
      pinata_api_key: PINATA_API_KEY,
      pinata_secret_api_key: PINATA_API_SECRET,
    };
  }
  throw new Error(
    'Pinata credentials not configured. Set either VITE_PINATA_JWT, or both VITE_PINATA_API_KEY and VITE_PINATA_API_SECRET in frontend/.env'
  );
}

/**
 * Uploads a transaction description to IPFS via Pinata.
 *
 * @param {string} description - The human-readable transaction description.
 * @returns {Promise<string>} The IPFS URI in the format "ipfs://<CID>".
 * @throws {Error} If the upload fails or no credentials are configured.
 */
export async function uploadToIPFS(description) {
  const authHeaders = getPinataAuthHeaders();

  const body = {
    pinataContent: {
      description,
      timestamp: new Date().toISOString(),
    },
    pinataMetadata: {
      name: `multisig-tx-${Date.now()}`,
    },
  };

  const response = await fetch(PINATA_PIN_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...authHeaders,
    },
    body: JSON.stringify(body),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`IPFS upload failed (${response.status}): ${errorText}`);
  }

  const data = await response.json();
  return `ipfs://${data.IpfsHash}`;
}

/**
 * Extracts the raw CID from an IPFS URI string.
 *
 * @param {string} ipfsURI - An IPFS URI (e.g. "ipfs://Qm..." or a raw CID).
 * @returns {string} The extracted CID.
 */
function extractCID(ipfsURI) {
  if (ipfsURI.startsWith('ipfs://')) {
    return ipfsURI.slice(7);
  }
  return ipfsURI;
}

// In-memory cache to avoid redundant gateway fetches
const descriptionCache = new Map();

/**
 * Fetches a transaction description from IPFS using multiple gateway fallbacks.
 *
 * @param {string} ipfsURI - An IPFS URI (e.g. "ipfs://Qm...").
 * @returns {Promise<string>} The resolved description text, or a fallback message.
 */
export async function fetchFromIPFS(ipfsURI) {
  if (!ipfsURI || ipfsURI === '') {
    return '';
  }

  // Return cached result if available
  if (descriptionCache.has(ipfsURI)) {
    return descriptionCache.get(ipfsURI);
  }

  const cid = extractCID(ipfsURI);

  for (const gateway of IPFS_GATEWAYS) {
    try {
      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), 8000);

      const response = await fetch(`${gateway}${cid}`, {
        signal: controller.signal,
      });
      clearTimeout(timeout);

      if (!response.ok) continue;

      const data = await response.json();
      const description = data.description || JSON.stringify(data);

      // Cache the result
      descriptionCache.set(ipfsURI, description);
      return description;
    } catch {
      // Try next gateway
      continue;
    }
  }

  // All gateways failed — return the raw URI as fallback
  return `[IPFS] ${ipfsURI}`;
}
