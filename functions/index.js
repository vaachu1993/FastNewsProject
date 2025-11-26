const functions = require('firebase-functions');
const admin = require('firebase-admin');
const fetch = require('node-fetch');
const xml2js = require('xml2js');

admin.initializeApp();

// RSS Feed URLs
const RSS_FEEDS = {
  'all_users': 'https://vnexpress.net/rss/tin-moi-nhat.rss',
  'chinh_tri': 'https://vnexpress.net/rss/thoi-su.rss',
  'kinh_te': 'https://vnexpress.net/rss/kinh-doanh.rss',
  'the_gioi': 'https://vnexpress.net/rss/the-gioi.rss',
  'the_thao': 'https://vnexpress.net/rss/the-thao.rss',
  'cong_nghe': 'https://vnexpress.net/rss/so-hoa.rss',
  'giai_tri': 'https://vnexpress.net/rss/giai-tri.rss',
  'suc_khoe': 'https://vnexpress.net/rss/suc-khoe.rss',
  'du_lich': 'https://vnexpress.net/rss/du-lich.rss',
};

/**
 * Cloud Function: Kiểm tra tin tức mới và gửi notification
 * Chạy mỗi 1 giờ
 */
exports.checkNewArticles = functions.pubsub
  .schedule('every 1 hours')
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

      // Gửi notification đến tất cả users
      const message = {
        notification: {
          title: '📰 Tin tức mới',
          body: latestArticle.title,
        },
        data: {
          articleUrl: latestArticle.link,
          articleTitle: latestArticle.title,
          source: 'VnExpress',
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

        // Gửi notification
        const message = {
          notification: {
            title: `📰 ${getCategoryName(topic)}`,
            body: latestArticle.title,
          },
          data: {
            articleUrl: latestArticle.link,
            articleTitle: latestArticle.title,
            category: topic,
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
 * Fetch articles from RSS feed
 */
async function fetchLatestArticles(rssUrl) {
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
    }));

    return articles;
  } catch (error) {
    console.error('❌ Error fetching RSS:', error);
    return [];
  }
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

