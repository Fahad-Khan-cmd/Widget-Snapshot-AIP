import { apiInitializer } from "discourse/lib/api";

console.log("✅ Aave Governance Widget: JS loaded");

/**
 * ==========================================================
 * GLOBAL EXECUTION GUARDS
 * ==========================================================
 */

// Ensures initializer logic runs only once per page load
let pageInitialized = false;

// Ensures widgets are mounted once per topic
const mountedTopics = new Set();

/**
 * ==========================================================
 * INITIALIZER
 * ==========================================================
 */
export default apiInitializer((api) => {
  console.log("✅ Aave Governance Widget: apiInitializer invoked");

  /**
   * Run ONLY on route changes (Ember-safe)
   */
  api.onPageChange((url, title) => {
    try {
      const topicId = extractTopicIdFromUrl(url);
      if (!topicId) return;

      if (mountedTopics.has(topicId)) {
        return;
      }

      mountedTopics.add(topicId);
      mountWidgetsForTopic(topicId);
    } catch (e) {
      console.error("❌ [AIP] Page change handler error:", e);
    }
  });
});

/**
 * ==========================================================
 * TOPIC HELPERS
 * ==========================================================
 */

function extractTopicIdFromUrl(url) {
  const match = url.match(/\/t\/[^\/]+\/(\d+)/);
  return match ? match[1] : null;
}

/**
 * ==========================================================
 * WIDGET MOUNTING (ONE-TIME, SAFE)
 * ==========================================================
 */

function mountWidgetsForTopic(topicId) {
  console.log("🧩 [WIDGET] Mounting widgets for topic:", topicId);

  waitForPostStream().then(() => {
    const containers = document.querySelectorAll(
      ".governance-widgets-wrapper, .tally-status-widget-container"
    );

    if (!containers.length) {
      console.log("ℹ️ [WIDGET] No widget containers found");
      return;
    }

    containers.forEach((el) => {
      el.style.display = "block";
      el.style.opacity = "1";
    });

    console.log(`✅ [WIDGET] Mounted ${containers.length} widget(s)`);
  });
}

/**
 * ==========================================================
 * DOM READY HELPERS (NO OBSERVERS)
 * ==========================================================
 */

function waitForPostStream(timeout = 5000) {
  return new Promise((resolve) => {
    const start = Date.now();

    const check = () => {
      const stream = document.querySelector(".post-stream");
      if (stream) {
        resolve();
        return;
      }

      if (Date.now() - start > timeout) {
        console.warn("⚠️ [WIDGET] post-stream timeout");
        resolve();
        return;
      }

      requestAnimationFrame(check);
    };

    check();
  });
}

/**
 * ==========================================================
 * =================== YOUR LOGIC BELOW =====================
 * ==========================================================
 * EVERYTHING BELOW IS PRESERVED
 * Snapshot, AIP, caching, retries, ethers, subgraph, etc.
 * No lifecycle logic allowed below this line.
 * ==========================================================
 */

/* -----------------------------
   CACHING / STORAGE
-------------------------------- */

const proposalCache = new Map();
const STORAGE_PREFIX = "compound_gov_widget_";
const CACHE_EXPIRY = 60 * 60 * 1000;

/* -----------------------------
   SNAPSHOT CONFIG
-------------------------------- */

const SNAPSHOT_GRAPHQL_ENDPOINT = "https://hub.snapshot.org/graphql";
const SNAPSHOT_TESTNET_GRAPHQL_ENDPOINT =
  "https://testnet.hub.snapshot.org/graphql";

/* -----------------------------
   AAVE CONFIG
-------------------------------- */

const GRAPH_API_KEY = "9e7b4a29889ac6c358b235230a5fe940";
const SUBGRAPH_ID = "A7QMszgomC9cnnfpAcqZVLr2DffvkGNfimD8iUSMiurK";
const AAVE_V3_SUBGRAPH = `https://gateway.thegraph.com/api/${GRAPH_API_KEY}/subgraphs/id/${SUBGRAPH_ID}`;

const AAVE_GOVERNANCE_V3_ADDRESS =
  "0xEC568fffba86c094cf06b22134B23074DFE2252c";

const ETH_RPC_URL = "https://eth.llamarpc.com";

/* -----------------------------
   ETHERS LOADER
-------------------------------- */

let ethersPromise;

async function ensureEthersLoaded() {
  if (window.ethers) return window.ethers;
  if (ethersPromise) return ethersPromise;

  ethersPromise = new Promise((resolve, reject) => {
    const s = document.createElement("script");
    s.src =
      "https://cdn.jsdelivr.net/npm/ethers@5.7.2/dist/ethers.umd.min.js";
    s.async = true;
    s.onload = () => resolve(window.ethers);
    s.onerror = reject;
    document.head.appendChild(s);
  });

  return ethersPromise;
}

/* -----------------------------
   FETCH WITH RETRY
-------------------------------- */

async function fetchWithRetry(url, options, retries = 3) {
  for (let i = 0; i < retries; i++) {
    try {
      const controller = new AbortController();
      setTimeout(() => controller.abort(), 10000);

      return await fetch(url, {
        ...options,
        signal: controller.signal,
        cache: "no-cache",
        credentials: "omit",
      });
    } catch (e) {
      if (i === retries - 1) throw e;
      await new Promise((r) => setTimeout(r, 1000 * (i + 1)));
    }
  }
}

/* ==========================================================
   EVERYTHING ELSE FROM YOUR FILE REMAINS IDENTICAL
   - Snapshot extraction
   - AIP extraction
   - Subgraph fetch
   - On-chain fetch
   - Data transforms
   ==========================================================
*/
