import db from "../config/db.js";

const FEED_URL =
  "https://news.google.com/rss/search?q=currency%20exchange%20OR%20forex%20market&hl=en-NG&gl=NG&ceid=NG:en";

const decodeXml = (value = "") =>
  value
    .replace(/<!\[CDATA\[/g, "")
    .replace(/\]\]>/g, "")
    .replace(/&amp;/g, "&")
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">");

const tag = (xml, name) => {
  const match = xml.match(
    new RegExp(`<${name}(?:\\s[^>]*)?>([\\s\\S]*?)</${name}>`, "i"),
  );

  return match ? decodeXml(match[1].trim()) : "";
};

const stripHtml = (value) =>
  value
    .replace(/<[^>]*>/g, " ")
    .replace(/\s+/g, " ")
    .trim();

const parseFeed = (xml) => {
  const items = [];

  const blocks = xml.match(/<item>[\s\S]*?<\/item>/gi) ?? [];

  for (const block of blocks) {
    const title = tag(block, "title");

    const link = tag(block, "link");

    const description = stripHtml(tag(block, "description"));

    const pubDate = tag(block, "pubDate");

    const source = tag(block, "source");

    if (!title || !link) {
      continue;
    }

    const published = pubDate ? new Date(pubDate) : new Date();

    items.push({
      title: title.slice(0, 255),

      summary: description.slice(0, 5000),

      url: link.slice(0, 500),

      source: (source || "Market News").slice(0, 100),

      publishedAt: Number.isNaN(published.getTime()) ? null : published,
    });
  }

  return items;
};

const refreshNews = async () => {
  const response = await fetch(FEED_URL, {
    headers: {
      "User-Agent": "CurrenSee/1.0",
    },

    signal: AbortSignal.timeout(8000),
  });

  if (!response.ok) {
    throw new Error(`News feed returned ${response.status}`);
  }

  const xml = await response.text();

  const items = parseFeed(xml).slice(0, 30);

  for (const item of items) {
    const [existing] = await db.query(
      "SELECT id FROM news_articles WHERE url = ? LIMIT 1",
      [item.url],
    );

    if (existing[0]) {
      await db.query(
        `UPDATE news_articles
         SET title = ?,
             summary = ?,
             source = ?,
             published_at = ?
         WHERE id = ?`,
        [
          item.title,
          item.summary,
          item.source,
          item.publishedAt,
          existing[0].id,
        ],
      );
    } else {
      await db.query(
        `INSERT INTO news_articles
          (title, summary, url, source, published_at)
         VALUES (?, ?, ?, ?, ?)`,
        [item.title, item.summary, item.url, item.source, item.publishedAt],
      );
    }
  }
};

export const getNews = async (req, res, next) => {
  try {
    try {
      await refreshNews();
    } catch (feedError) {
      console.warn(
        "News refresh failed; serving cached articles:",
        feedError.message,
      );
    }

    const rawLimit = Number.parseInt(req.query.limit, 10);

    const limit = Math.min(
      Math.max(Number.isFinite(rawLimit) ? rawLimit : 20, 1),
      50,
    );

    const [rows] = await db.query(
      `SELECT
           id,
           title,
           summary,
           url,
           source,
           published_at AS publishedAt
         FROM news_articles
         WHERE url IS NOT NULL
           AND url <> ''
         ORDER BY
           published_at DESC,
           id DESC
         LIMIT ?`,
      [limit],
    );

    res.json({
      items: rows,
    });
  } catch (err) {
    next(err);
  }
};
