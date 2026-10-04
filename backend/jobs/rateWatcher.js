import db from "../config/db.js";
import { notifyUser } from "../utils/notifier.js";

const API = "https://api.frankfurter.dev/v1";
const INTERVAL_MS = 30 * 60 * 1000; // ECB publishes once per working day; 30 min catches it soon after

async function getJson(url) {
  const res = await fetch(url, { signal: AbortSignal.timeout(10000) });
  if (!res.ok) throw new Error(`Rates API ${res.status}`);
  return res.json();
}

/** Fires user-created rate alerts whose threshold has been crossed. */
async function checkAlerts() {
  const [alerts] = await db.query(
    `SELECT a.id, a.user_id, a.base_code, a.target_code, a.threshold, a.direction
     FROM rate_alerts a JOIN user_preferences p ON p.user_id = a.user_id
     WHERE a.is_active = TRUE AND p.alert_notifications_enabled = TRUE`
  );
  const byBase = new Map();
  for (const a of alerts) {
    if (!byBase.has(a.base_code)) byBase.set(a.base_code, new Set());
    byBase.get(a.base_code).add(a.target_code);
  }
  for (const [base, targets] of byBase) {
    let data;
    try {
      data = await getJson(`${API}/latest?base=${base}&symbols=${[...targets].join(",")}`);
    } catch (err) {
      console.error(`Alert check skipped for ${base}:`, err.message);
      continue;
    }
    for (const a of alerts.filter((x) => x.base_code === base)) {
      const rate = data.rates?.[a.target_code];
      const threshold = Number(a.threshold);
      if (typeof rate !== "number") continue;
      const hit = a.direction === "ABOVE" ? rate >= threshold : rate <= threshold;
      if (!hit) continue;
      const [upd] = await db.query(
        "UPDATE rate_alerts SET is_active = FALSE, triggered_at = NOW() WHERE id = ? AND is_active = TRUE",
        [a.id]
      );
      if (upd.affectedRows !== 1) continue; // already handled
      await notifyUser(a.user_id, {
        type: "ALERT",
        title: `${a.base_code}/${a.target_code} hit your target`,
        body: `1 ${a.base_code} is now ${rate} ${a.target_code} (your alert: ${a.direction === "ABOVE" ? "at or above" : "at or below"} ${threshold}).`,
      });
    }
  }
}

async function sendDailyUpdates() {
  const [users] = await db.query(
    `SELECT user_id, default_base_currency AS base, default_target_currency AS target,
            DATE_FORMAT(last_digest_date, '%Y-%m-%d') AS lastDigest
     FROM user_preferences
     WHERE alert_notifications_enabled = TRUE AND default_base_currency <> default_target_currency`
  );
  const cache = new Map(); // "USD>EUR" -> { date, rate, prev } | null
  const since = new Date(Date.now() - 8 * 86400000).toISOString().slice(0, 10);

  for (const u of users) {
    const key = `${u.base}>${u.target}`;
    if (!cache.has(key)) {
      try {
        const data = await getJson(`${API}/${since}..?base=${u.base}&symbols=${u.target}`);
        const days = Object.keys(data.rates ?? {}).sort();
        cache.set(
          key,
          days.length >= 2
            ? { date: days.at(-1), rate: data.rates[days.at(-1)][u.target], prev: data.rates[days.at(-2)][u.target] }
            : null
        );
      } catch (err) {
        console.error(`Daily update skipped for ${key}:`, err.message);
        cache.set(key, null);
      }
    }
    const pair = cache.get(key);
    if (!pair || u.lastDigest === pair.date) continue;

    const pct = (pair.rate / pair.prev - 1) * 100;
    await db.query("UPDATE user_preferences SET last_digest_date = ? WHERE user_id = ?", [pair.date, u.user_id]);
    await notifyUser(u.user_id, {
      type: "ALERT",
      title: `${u.base}/${u.target} ${pct >= 0 ? "up" : "down"} ${Math.abs(pct).toFixed(2)}%`,
      body: `1 ${u.base} = ${pair.rate} ${u.target} (previous day ${pair.prev}). ECB reference rate for ${pair.date}.`,
    });
  }
}

export function startRateWatcher() {
  const run = async () => {
    try { await checkAlerts(); } catch (err) { console.error("Rate alert check failed:", err.message); }
    try { await sendDailyUpdates(); } catch (err) { console.error("Daily rate update failed:", err.message); }
  };
  setTimeout(run, 15000);
  setInterval(run, INTERVAL_MS);
}