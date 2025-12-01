const functions = require('firebase-functions');
const admin = require('firebase-admin');
const fetch = require('node-fetch');
const xml2js = require('xml2js');

admin.initializeApp();

// RSS Feed URLs - Giống với app (3 nguồn: VnExpress, Tuổi Trẻ, Thanh Niên)
const RSS_FEEDS = {
  'all_users': [
    'https://vnexpress.net/rss/tin-moi-nhat.rss',
    'https://tuoitre.vn/rss/tin-moi-nhat.rss',
    'https://thanhnien.vn/rss/home.rss',
  ],
  'the_thao': [
    'https://vnexpress.net/rss/the-thao.rss',
    'https://tuoitre.vn/rss/the-thao.rss',
    'https://thanhnien.vn/rss/the-thao.rss',
  ],
  'cong_nghe': [
    'https://vnexpress.net/rss/so-hoa.rss',
    'https://tuoitre.vn/rss/nhip-song-so.rss',
    'https://thanhnien.vn/rss/cong-nghe.rss',
  ],
  'kinh_te': [
    'https://vnexpress.net/rss/kinh-doanh.rss',
    'https://tuoitre.vn/rss/kinh-doanh.rss',
    'https://thanhnien.vn/rss/kinh-te.rss',
  ],
  'chinh_tri': [
    'https://vnexpress.net/rss/thoi-su.rss',
    'https://tuoitre.vn/rss/thoi-su.rss',
    'https://thanhnien.vn/rss/thoi-su.rss',
  ],
  'suc_khoe': [
    'https://vnexpress.net/rss/suc-khoe.rss',
    'https://tuoitre.vn/rss/suc-khoe.rss',
    'https://thanhnien.vn/rss/suc-khoe.rss',
  ],
  'giai_tri': [
    'https://vnexpress.net/rss/giai-tri.rss',
  ],
  'the_gioi': [
    'https://vnexpress.net/rss/the-gioi.rss',
  ],
  'du_lich': [
    'https://vnexpress.net/rss/du-lich.rss',
  ],
};

/**
 * Cloud Function: Kiểm tra tin tức mới và gửi notification
 * Chạy mỗi 2 giờ
 */
exports.checkNewArticles = functions.pubsub
  .schedule('every 2 hours')
  .timeZone('Asia/Ho_Chi_Minh')
  .onRun(async (context) => {
    console.log('🔍 Starting news check at:', new Date().toISOString());

    try {
      // Lấy tin tức mới nhất từ RSS feed
      const articles = await fetchLatestArticles(RSS_FEEDS['all_users']);

      if (articles.length === 0) {
        console.log('📭 No articles found');
        return null;
      }

      // Lấy bài viết mới nhất
      const latestArticle = articles[0];
      console.log('📰 Latest article:', latestArticle.title);

      // Kiểm tra xem đã gửi notification cho bài này chưa
      const db = admin.firestore();
      const lastNotifiedDoc = await db.collection('system').doc('last_notified').get();
      const lastNotifiedLink = lastNotifiedDoc.exists ? lastNotifiedDoc.data().link : null;

      if (lastNotifiedLink === latestArticle.link) {
        console.log('✅ Already notified about this article');
        return null;
      }

      // Tạo article object đầy đủ để có thể navigate vào trang chi tiết
      const articleData = {
        id: generateArticleId(latestArticle.link),
        title: latestArticle.title,
        link: latestArticle.link,
        description: latestArticle.description || '',
        imageUrl: extractImageUrl(latestArticle.description) || '',
        time: latestArticle.pubDate || new Date().toISOString(),
        source: latestArticle.source || 'Tin tức',
      };

      // Gửi notification đến tất cả users
      const message = {
        notification: {
          title: '📰 Tin tức mới',
          body: latestArticle.title,
        },
        data: {
          // Gửi toàn bộ article dưới dạng JSON string
          article: JSON.stringify(articleData),
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        topic: 'all_users',
      };

      await admin.messaging().send(message);
      console.log('✅ Notification sent successfully');

      // Lưu lại link bài viết đã gửi
      await db.collection('system').doc('last_notified').set({
        link: latestArticle.link,
        title: latestArticle.title,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      return null;
    } catch (error) {
      console.error('❌ Error in checkNewArticles:', error);
      return null;
    }
  });

/**
 * Cloud Function: Gửi notification theo category
 * Chạy mỗi 2 giờ
 */
exports.checkNewArticlesByCategory = functions.pubsub
  .schedule('every 2 hours')
  .timeZone('Asia/Ho_Chi_Minh')
  .onRun(async (context) => {
    console.log('🔍 Starting category news check at:', new Date().toISOString());

    try {
      const db = admin.firestore();

      // Duyệt qua tất cả các category
      for (const [topic, feedUrl] of Object.entries(RSS_FEEDS)) {
        if (topic === 'all_users') continue; // Skip all_users

        console.log(`📋 Checking ${topic}...`);

        const articles = await fetchLatestArticles(feedUrl);
        if (articles.length === 0) continue;

        const latestArticle = articles[0];

        // Kiểm tra đã gửi chưa
        const lastDoc = await db.collection('system').doc(`last_notified_${topic}`).get();
        const lastLink = lastDoc.exists ? lastDoc.data().link : null;

        if (lastLink === latestArticle.link) {
          console.log(`✅ ${topic}: Already notified`);
          continue;
        }

        // Tạo article object đầy đủ
        const articleData = {
          id: generateArticleId(latestArticle.link),
          title: latestArticle.title,
          link: latestArticle.link,
          description: latestArticle.description || '',
          imageUrl: extractImageUrl(latestArticle.description) || '',
          time: latestArticle.pubDate || new Date().toISOString(),
          source: latestArticle.source || 'Tin tức',
        };

        // Gửi notification
        const message = {
          notification: {
            title: `📰 ${getCategoryName(topic)}`,
            body: latestArticle.title,
          },
          data: {
            // Gửi toàn bộ article dưới dạng JSON string
            article: JSON.stringify(articleData),
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
          },
          topic: topic,
        };

        await admin.messaging().send(message);
        console.log(`✅ ${topic}: Notification sent`);

        // Lưu lại
        await db.collection('system').doc(`last_notified_${topic}`).set({
          link: latestArticle.link,
          title: latestArticle.title,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      return null;
    } catch (error) {
      console.error('❌ Error in checkNewArticlesByCategory:', error);
      return null;
    }
  });

/**
 * Fetch articles from RSS feed (hỗ trợ cả single URL và array of URLs)
 */
async function fetchLatestArticles(rssUrlOrArray) {
  const urls = Array.isArray(rssUrlOrArray) ? rssUrlOrArray : [rssUrlOrArray];
  const allArticles = [];

  for (const rssUrl of urls) {
    try {
      const response = await fetch(rssUrl);
      const xml = await response.text();
      const result = await xml2js.parseStringPromise(xml);

      const items = result.rss.channel[0].item || [];
      const articles = items.slice(0, 5).map(item => ({
        title: item.title[0],
        link: item.link[0],
        description: item.description ? item.description[0] : '',
        pubDate: item.pubDate ? item.pubDate[0] : '',
        source: detectSource(rssUrl),
      }));

      allArticles.push(...articles);
    } catch (error) {
      console.error(`❌ Error fetching RSS from ${rssUrl}:`, error);
    }
  }

  // Sort by pubDate (newest first)
  allArticles.sort((a, b) => {
    const dateA = new Date(a.pubDate || 0);
    const dateB = new Date(b.pubDate || 0);
    return dateB - dateA;
  });

  return allArticles;
}

/**
 * Detect source from RSS URL
 */
function detectSource(url) {
  if (url.includes('vnexpress')) return 'VNExpress';
  if (url.includes('tuoitre')) return 'Tuổi Trẻ';
  if (url.includes('thanhnien')) return 'Thanh Niên';
  return 'Tin tức';
}

/**
 * Generate article ID from link (same as Flutter app)
 */
function generateArticleId(link) {
  const crypto = require('crypto');
  return crypto.createHash('sha256').update(link).digest('hex').substring(0, 16);
}

/**
 * Extract image URL from description HTML
 */
function extractImageUrl(description) {
  if (!description) return '';

  const imgRegex = /<img[^>]+src="([^">]+)"/i;
  const match = description.match(imgRegex);
  return match ? match[1] : '';
}

/**
 * Get category display name
 */
function getCategoryName(topic) {
  const names = {
    'chinh_tri': 'Chính trị',
    'kinh_te': 'Kinh tế',
    'the_gioi': 'Thế giới',
    'the_thao': 'Thể thao',
    'cong_nghe': 'Công nghệ',
    'giai_tri': 'Giải trí',
    'suc_khoe': 'Sức khỏe',
    'du_lich': 'Du lịch',
  };
  return names[topic] || 'Tin tức mới';
}

/**
 * Test function: Gửi test notification
 */
exports.sendTestNotification = functions.https.onRequest(async (req, res) => {
  try {
    const message = {
      notification: {
        title: '🧪 Test Notification',
        body: 'Firebase Cloud Functions hoạt động tốt! 🎉',
      },
      data: {
        test: 'true',
        timestamp: new Date().toISOString(),
      },
      topic: 'all_users',
    };

    await admin.messaging().send(message);
    res.json({ success: true, message: 'Test notification sent!' });
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

