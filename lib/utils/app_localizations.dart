class AppLocalizations {
  final String languageCode;

  AppLocalizations(this.languageCode);

  static AppLocalizations of(String languageCode) {
    return AppLocalizations(languageCode);
  }

  // Hàm helper để lấy translation
  String translate(String key) {
    return _localizedValues[languageCode]?[key] ?? key;
  }

  // All translations
  static final Map<String, Map<String, String>> _localizedValues = {
    'vi': {
      // Common
      'app_name': 'FastNews',
      'ok': 'OK',
      'cancel': 'Hủy',
      'save': 'Lưu',
      'delete': 'Xóa',
      'edit': 'Chỉnh sửa',
      'search': 'Tìm kiếm',
      'loading': 'Đang tải...',
      'error': 'Lỗi',
      'success': 'Thành công',
      'confirm': 'Xác nhận',
      'back': 'Quay lại',
      'retry': 'Thử lại',
      'close': 'Đóng',

      // Authentication
      'login': 'Đăng nhập',
      'logout': 'Đăng xuất',
      'signup': 'Đăng ký',
      'email': 'Email',
      'password': 'Mật khẩu',
      'forgot_password': 'Quên mật khẩu?',
      'login_with_google': 'Đăng nhập bằng Google',
      'login_with_email': 'Đăng nhập bằng Email',
      'dont_have_account': 'Chưa có tài khoản?',
      'already_have_account': 'Đã có tài khoản?',
      'logout_confirm': 'Bạn có chắc chắn muốn đăng xuất?',
      'logout_success': 'Đăng xuất thành công',

      // Navigation
      'home': 'Trang chủ',
      'discover': 'Khám phá',
      'bookmarks': 'Đã lưu',
      'profile': 'Hồ sơ',

      // Settings
      'settings': 'Cài đặt',
      'account': 'Tài khoản',
      'notifications': 'Thông báo',
      'dark_mode': 'Chế độ tối',
      'language': 'Ngôn ngữ',
      'security': 'Bảo mật',
      'terms_and_conditions': 'Điều khoản & Điều kiện',
      'privacy_policy': 'Chính sách bảo mật',
      'help': 'Trợ giúp',
      'invite_friends': 'Mời bạn bè',
      'select_language': 'Chọn ngôn ngữ',
      'vietnamese': 'Tiếng Việt',
      'english': 'English',

      // Notifications
      'notification_enabled': '✅ Đã bật thông báo tin tức mới',
      'notification_disabled': '🔕 Đã tắt thông báo tin tức mới',
      'test_notification': 'Thử nghiệm',

      // Profile Screen
      'logout_dialog_title': 'Đăng xuất',
      'logout_dialog_content': 'Bạn có chắc chắn muốn đăng xuất không?',
      'cancel': 'Hủy',
      'logout': 'Đăng xuất',
      'logout_tooltip': 'Đăng xuất',
      'user': 'Người dùng',
      'no_email': 'Không có email',
      'name_label': 'Tên',
      'email_label': 'Email',
      'status_label': 'Trạng thái',
      'joined_label': 'Tham gia',
      'not_updated': 'Chưa cập nhật',
      'not_determined': 'Chưa xác định',
      'email_verified_tooltip': 'Email đã xác thực',
      'verified': 'Đã xác thực',
      'not_verified': 'Chưa xác thực',

      // Sidebar/Drawer
      'today': 'Hôm nay',
      'read_later': 'Đọc sau',
      'categories': 'Thể loại',
      'all': 'Tất cả',
      'technology': 'Công nghệ',
      'add_content': 'Thêm nội dung',
      'recently_read': 'Đã đọc gần đây',
      'your_topics': 'Chủ đề của bạn',

      // Reading History Screen
      'reading_history_title': 'Đã đọc gần đây',
      'clear_history': 'Xóa lịch sử',
      'clear_history_dialog_title': 'Xóa lịch sử',
      'clear_history_dialog_content': 'Bạn có chắc chắn muốn xóa toàn bộ lịch sử đọc?',
      'delete': 'Xóa',
      'history_cleared': 'Đã xóa lịch sử đọc',
      'cannot_clear_history': 'Không thể xóa lịch sử đọc',
      'no_reading_history': 'Chưa có lịch sử đọc',
      'reading_history_subtitle': 'Các bài báo bạn đọc sẽ xuất hiện ở đây',

      // Features coming soon
      'security_coming_soon': 'Cài đặt bảo mật sắp ra mắt',
      'terms_opening': 'Đang mở Điều khoản & Điều kiện...',
      'privacy_opening': 'Đang mở Chính sách bảo mật...',
      'help_opening': 'Đang mở Trợ giúp...',
      'invite_coming_soon': 'Tính năng mời bạn bè sắp ra mắt',

      // Home Screen
      'latest_news': 'Tin mới nhất',
      'featured_news': 'Tin nổi bật',
      'global_news': 'Tin toàn cầu',
      'view_all': 'Xem tất cả',
      'favorite_topics': 'Danh mục yêu thích',
      'no_favorite_topics': 'Chưa có chủ đề yêu thích',
      'add_favorite_topics': 'Thêm chủ đề yêu thích',
      'all': 'Tất cả',

      // Article
      'read_more': 'Đọc thêm',
      'share': 'Chia sẻ',
      'bookmark': 'Lưu',
      'bookmarked': 'Đã lưu',
      'reading_history': 'Lịch sử đọc',
      'no_articles': 'Không có bài viết',
      'load_more': 'Tải thêm',

      // Profile
      'edit_profile': 'Chỉnh sửa hồ sơ',
      'change_password': 'Đổi mật khẩu',
      'reading_statistics': 'Thống kê đọc',
      'articles_read': 'Bài đã đọc',
      'favorites': 'Yêu thích',

      // Discover
      'trending': 'Xu hướng',
      'categories': 'Danh mục',
      'topics': 'Chủ đề',

      // Bookmarks
      'bookmarks_title': 'Đã lưu',
      'saved_articles': 'Bài viết đã lưu',
      'no_bookmarks': 'Chưa có bài viết được lưu',
      'remove_bookmark': 'Bỏ lưu',

      // Topics Selection
      'select_topics': 'Chọn chủ đề yêu thích',
      'choose_interests': 'Chọn sở thích của bạn',
      'topics_description': 'Chọn ít nhất 3 chủ đề để cá nhân hóa tin tức của bạn',
      'topics_personalize_description': 'Chọn các chủ đề bạn quan tâm để cá nhân hóa nguồn cấp tin tức của bạn',
      'topics_selected': 'đã chọn',
      'continue': 'Tiếp tục',
      'skip': 'Bỏ qua',
      'skip_for_now': 'Bỏ qua',
      'select_at_least_one': 'Vui lòng chọn ít nhất một chủ đề',
      'topics_saved_success': 'Đã lưu thành công {count} chủ đề!',
      'error_saving_topics': 'Lỗi khi lưu chủ đề: {error}',

      // Categories
      'category_all': 'Tất cả',
      'category_latest': 'Mới nhất',
      'category_politics': 'Chính trị',
      'category_business': 'Kinh doanh',
      'category_technology': 'Công nghệ',
      'category_sports': 'Thể thao',
      'category_entertainment': 'Giải trí',
      'category_health': 'Sức khỏe',
      'category_science': 'Khoa học',
      'category_world': 'Thế giới',

      // Error messages
      'error_loading': 'Không thể tải dữ liệu',
      'error_network': 'Lỗi kết nối mạng',
      'error_unknown': 'Đã xảy ra lỗi',
      'error_login': 'Đăng nhập thất bại',
      'error_signup': 'Đăng ký thất bại',

      // Success messages
      'save_success': 'Lưu thành công',
      'update_success': 'Cập nhật thành công',
      'delete_success': 'Xóa thành công',

      // Empty state messages
      'no_articles_in_category': 'Không có bài viết trong danh mục này',
      'select_favorite_topics_hint': 'Vui lòng chọn chủ đề yêu thích trong phần Cài đặt để xem bài viết',

      // Article Detail Screen
      'article_detail': 'Chi tiết bài viết',
      'related_articles': 'Bài viết liên quan',
      'comments': 'Bình luận',
      'share_article': 'Chia sẻ bài viết',

      // Categories (Sidebar)
      'category_politics': 'Chính trị',
      'category_business': 'Kinh doanh',
      'category_sports': 'Thể thao',
      'category_entertainment': 'Giải trí',
      'category_health': 'Sức khỏe',
      'category_science': 'Khoa học',
      'category_world': 'Thế giới',
      'category_education': 'Giáo dục',
      'category_culture': 'Văn hóa',
      'category_law': 'Pháp luật',

      // Terms & Conditions
      'terms_title': 'Điều khoản & Điều kiện',
      'terms_intro': 'Chào mừng bạn đến với FastNews',
      'terms_content_1': '1. Chấp nhận điều khoản',
      'terms_content_1_detail': 'Bằng cách truy cập và sử dụng ứng dụng FastNews, bạn đồng ý tuân thủ các điều khoản và điều kiện được nêu trong tài liệu này.',
      'terms_content_2': '2. Sử dụng dịch vụ',
      'terms_content_2_detail': 'Bạn đồng ý sử dụng dịch vụ của chúng tôi một cách hợp pháp và không vi phạm quyền của bất kỳ bên thứ ba nào.',
      'terms_content_3': '3. Quyền sở hữu trí tuệ',
      'terms_content_3_detail': 'Tất cả nội dung, nhãn hiệu và dữ liệu trên FastNews đều thuộc quyền sở hữu của chúng tôi hoặc các đối tác cấp phép.',
      'terms_content_4': '4. Giới hạn trách nhiệm',
      'terms_content_4_detail': 'FastNews không chịu trách nhiệm về bất kỳ thiệt hại trực tiếp hoặc gián tiếp nào phát sinh từ việc sử dụng dịch vụ.',
      'terms_content_5': '5. Thay đổi điều khoản',
      'terms_content_5_detail': 'Chúng tôi có quyền thay đổi các điều khoản này bất kỳ lúc nào. Việc tiếp tục sử dụng dịch vụ sau khi có thay đổi đồng nghĩa với việc bạn chấp nhận các điều khoản mới.',

      // Privacy Policy
      'privacy_title': 'Chính sách bảo mật',
      'privacy_intro': 'Chính sách bảo mật của FastNews',
      'privacy_content_1': '1. Thu thập thông tin',
      'privacy_content_1_detail': 'Chúng tôi thu thập thông tin cá nhân như tên, email và thông tin đăng nhập để cung cấp dịch vụ tốt hơn.',
      'privacy_content_2': '2. Sử dụng thông tin',
      'privacy_content_2_detail': 'Thông tin của bạn được sử dụng để cải thiện trải nghiệm người dùng, gửi thông báo và cá nhân hóa nội dung.',
      'privacy_content_3': '3. Bảo mật thông tin',
      'privacy_content_3_detail': 'Chúng tôi cam kết bảo vệ thông tin của bạn bằng các biện pháp bảo mật tiên tiến.',
      'privacy_content_4': '4. Chia sẻ thông tin',
      'privacy_content_4_detail': 'Chúng tôi không chia sẻ thông tin cá nhân của bạn với bên thứ ba mà không có sự đồng ý của bạn.',
      'privacy_content_5': '5. Quyền của bạn',
      'privacy_content_5_detail': 'Bạn có quyền truy cập, chỉnh sửa hoặc xóa thông tin cá nhân của mình bất kỳ lúc nào.',

      // Help Screen
      'help_title': 'Trợ giúp',
      'help_intro': 'Chúng tôi sẵn sàng hỗ trợ bạn',
      'help_section_1': 'Câu hỏi thường gặp',
      'help_faq_1': 'Làm thế nào để đăng ký tài khoản?',
      'help_faq_1_answer': 'Bạn có thể đăng ký bằng email hoặc đăng nhập nhanh qua Google.',
      'help_faq_2': 'Làm thế nào để lưu bài viết yêu thích?',
      'help_faq_2_answer': 'Nhấn vào biểu tượng bookmark trên bài viết để lưu vào danh sách đã lưu.',
      'help_faq_3': 'Làm thế nào để thay đổi ngôn ngữ?',
      'help_faq_3_answer': 'Vào Cài đặt > Ngôn ngữ để chọn ngôn ngữ mong muốn.',
      'help_section_2': 'Liên hệ hỗ trợ',
      'help_contact_email': 'Email: support@fastnews.com',
      'help_contact_phone': 'Hotline: 1900-xxxx',
      'help_section_3': 'Phiên bản ứng dụng',
      'help_version': 'Phiên bản 1.0.0',
    },
    'en': {
      // Common
      'app_name': 'FastNews',
      'ok': 'OK',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'search': 'Search',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'confirm': 'Confirm',
      'back': 'Back',
      'retry': 'Retry',
      'close': 'Close',

      // Authentication
      'login': 'Login',
      'logout': 'Logout',
      'signup': 'Sign Up',
      'email': 'Email',
      'password': 'Password',
      'forgot_password': 'Forgot Password?',
      'login_with_google': 'Login with Google',
      'login_with_email': 'Login with Email',
      'dont_have_account': "Don't have an account?",
      'already_have_account': 'Already have an account?',
      'logout_confirm': 'Are you sure you want to logout?',
      'logout_success': 'Logout successful',

      // Navigation
      'home': 'Home',
      'discover': 'Discover',
      'bookmarks': 'Bookmarks',
      'profile': 'Profile',

      // Settings
      'settings': 'Settings',
      'account': 'Account',
      'notifications': 'Notifications',
      'dark_mode': 'Dark Mode',
      'language': 'Language',
      'security': 'Security',
      'terms_and_conditions': 'Terms & Conditions',
      'privacy_policy': 'Privacy Policy',
      'help': 'Help',
      'invite_friends': 'Invite Friends',
      'select_language': 'Select Language',
      'vietnamese': 'Tiếng Việt',
      'english': 'English',

      // Notifications
      'notification_enabled': '✅ News notifications enabled',
      'notification_disabled': '🔕 News notifications disabled',
      'test_notification': 'Test',

      // Profile Screen
      'logout_dialog_title': 'Logout',
      'logout_dialog_content': 'Are you sure you want to logout?',
      'cancel': 'Cancel',
      'logout': 'Logout',
      'logout_tooltip': 'Logout',
      'user': 'User',
      'no_email': 'No email',
      'name_label': 'Name',
      'email_label': 'Email',
      'status_label': 'Status',
      'joined_label': 'Joined',
      'not_updated': 'Not updated',
      'not_determined': 'Not determined',
      'email_verified_tooltip': 'Email verified',
      'verified': 'Verified',
      'not_verified': 'Not verified',

      // Sidebar/Drawer
      'today': 'Today',
      'read_later': 'Read Later',
      'categories': 'Categories',
      'all': 'All',
      'technology': 'Technology',
      'add_content': 'Add Content',
      'recently_read': 'Recently Read',
      'your_topics': 'Your Topics',

      // Reading History Screen
      'reading_history_title': 'Recently Read',
      'clear_history': 'Clear History',
      'clear_history_dialog_title': 'Clear History',
      'clear_history_dialog_content': 'Are you sure you want to clear all reading history?',
      'delete': 'Delete',
      'history_cleared': 'Reading history cleared',
      'cannot_clear_history': 'Cannot clear reading history',
      'no_reading_history': 'No reading history',
      'reading_history_subtitle': 'Articles you read will appear here',

      // Features coming soon
      'security_coming_soon': 'Security settings coming soon',
      'terms_opening': 'Opening Terms & Conditions...',
      'privacy_opening': 'Opening Privacy Policy...',
      'help_opening': 'Opening Help...',
      'invite_coming_soon': 'Invite friends feature coming soon',

      // Home Screen
      'latest_news': 'Latest News',
      'featured_news': 'Featured News',
      'global_news': 'Global News',
      'view_all': 'View All',
      'favorite_topics': 'Favorite Topics',
      'no_favorite_topics': 'No favorite topics',
      'add_favorite_topics': 'Add favorite topics',
      'all': 'All',

      // Article
      'read_more': 'Read More',
      'share': 'Share',
      'bookmark': 'Bookmark',
      'bookmarked': 'Bookmarked',
      'reading_history': 'Reading History',
      'no_articles': 'No articles',
      'load_more': 'Load More',
      'search_news': 'Search news...',
      'news': 'News',
      'articles': 'articles',
      'search_results': 'Search Results',
      'no_search_results': 'No results found for',
      'saved_articles': 'Saved Articles',
      'error_loading_bookmarks': 'Error loading bookmarks',
      'please_try_again': 'Please try again later or contact support',
      'start_saving_articles': 'Start saving your favorite articles!',

      // Profile
      'edit_profile': 'Edit Profile',
      'change_password': 'Change Password',
      'reading_statistics': 'Reading Statistics',
      'articles_read': 'Articles Read',
      'favorites': 'Favorites',

      // Discover
      'trending': 'Trending',
      'categories': 'Categories',
      'topics': 'Topics',

      // Bookmarks
      'bookmarks_title': 'Bookmarks',
      'no_bookmarks': 'No bookmarked articles',
      'remove_bookmark': 'Remove Bookmark',

      // Topics Selection
      'select_topics': 'Select Favorite Topics',
      'choose_interests': 'Choose Your Interests',
      'topics_description': 'Choose at least 3 topics to personalize your news feed',
      'topics_personalize_description': 'Select topics you\'re interested in to personalize your news feed',
      'topics_selected': 'selected',
      'continue': 'Continue',
      'skip': 'Skip',
      'skip_for_now': 'Skip for now',
      'select_at_least_one': 'Please select at least one topic',
      'topics_saved_success': 'Successfully saved {count} topics!',
      'error_saving_topics': 'Error saving topics: {error}',

      // Categories
      'category_all': 'All',
      'category_latest': 'Latest',
      'category_politics': 'Politics',
      'category_business': 'Business',
      'category_technology': 'Technology',
      'category_sports': 'Sports',
      'category_entertainment': 'Entertainment',
      'category_health': 'Health',
      'category_science': 'Science',
      'category_world': 'World',

      // Error messages
      'error_loading': 'Failed to load data',
      'error_network': 'Network connection error',
      'error_unknown': 'An error occurred',
      'error_login': 'Login failed',
      'error_signup': 'Sign up failed',

      // Success messages
      'save_success': 'Saved successfully',
      'update_success': 'Updated successfully',
      'delete_success': 'Deleted successfully',

      // Empty state messages
      'no_articles_in_category': 'No articles in this category',
      'select_favorite_topics_hint': 'Please select favorite topics in Settings to view articles',

      // Article Detail Screen
      'article_detail': 'Article Detail',
      'related_articles': 'Related Articles',
      'comments': 'Comments',
      'share_article': 'Share Article',

      // Categories (Sidebar)
      'category_politics': 'Politics',
      'category_business': 'Business',
      'category_sports': 'Sports',
      'category_entertainment': 'Entertainment',
      'category_health': 'Health',
      'category_science': 'Science',
      'category_world': 'World',
      'category_education': 'Education',
      'category_culture': 'Culture',
      'category_law': 'Law',

      // Terms & Conditions
      'terms_title': 'Terms & Conditions',
      'terms_intro': 'Welcome to FastNews',
      'terms_content_1': '1. Acceptance of Terms',
      'terms_content_1_detail': 'By accessing and using the FastNews app, you agree to comply with the terms and conditions outlined in this document.',
      'terms_content_2': '2. Use of Service',
      'terms_content_2_detail': 'You agree to use our service legally and not violate the rights of any third party.',
      'terms_content_3': '3. Intellectual Property Rights',
      'terms_content_3_detail': 'All content, trademarks and data on FastNews are owned by us or our licensing partners.',
      'terms_content_4': '4. Limitation of Liability',
      'terms_content_4_detail': 'FastNews is not responsible for any direct or indirect damages arising from the use of the service.',
      'terms_content_5': '5. Changes to Terms',
      'terms_content_5_detail': 'We reserve the right to change these terms at any time. Continued use of the service after changes constitutes acceptance of the new terms.',

      // Privacy Policy
      'privacy_title': 'Privacy Policy',
      'privacy_intro': 'FastNews Privacy Policy',
      'privacy_content_1': '1. Information Collection',
      'privacy_content_1_detail': 'We collect personal information such as name, email and login credentials to provide better service.',
      'privacy_content_2': '2. Use of Information',
      'privacy_content_2_detail': 'Your information is used to improve user experience, send notifications and personalize content.',
      'privacy_content_3': '3. Information Security',
      'privacy_content_3_detail': 'We are committed to protecting your information with advanced security measures.',
      'privacy_content_4': '4. Information Sharing',
      'privacy_content_4_detail': 'We do not share your personal information with third parties without your consent.',
      'privacy_content_5': '5. Your Rights',
      'privacy_content_5_detail': 'You have the right to access, edit or delete your personal information at any time.',

      // Help Screen
      'help_title': 'Help',
      'help_intro': 'We are here to help you',
      'help_section_1': 'Frequently Asked Questions',
      'help_faq_1': 'How to register an account?',
      'help_faq_1_answer': 'You can register with email or login quickly via Google.',
      'help_faq_2': 'How to save favorite articles?',
      'help_faq_2_answer': 'Tap the bookmark icon on the article to save it to your saved list.',
      'help_faq_3': 'How to change language?',
      'help_faq_3_answer': 'Go to Settings > Language to select your preferred language.',
      'help_section_2': 'Contact Support',
      'help_contact_email': 'Email: support@fastnews.com',
      'help_contact_phone': 'Hotline: 1900-xxxx',
      'help_section_3': 'App Version',
      'help_version': 'Version 1.0.0',
    },
  };

  // Helper methods to get specific translations
  String get appName => translate('app_name');
  String get ok => translate('ok');
  String get cancel => translate('cancel');
  String get save => translate('save');
  String get delete => translate('delete');
  String get edit => translate('edit');
  String get search => translate('search');
  String get loading => translate('loading');
  String get error => translate('error');
  String get success => translate('success');
  String get confirm => translate('confirm');
  String get back => translate('back');
  String get retry => translate('retry');
  String get close => translate('close');

  // Authentication
  String get login => translate('login');
  String get logout => translate('logout');
  String get signup => translate('signup');
  String get email => translate('email');
  String get password => translate('password');
  String get forgotPassword => translate('forgot_password');
  String get loginWithGoogle => translate('login_with_google');
  String get loginWithEmail => translate('login_with_email');
  String get dontHaveAccount => translate('dont_have_account');
  String get alreadyHaveAccount => translate('already_have_account');
  String get logoutConfirm => translate('logout_confirm');
  String get logoutSuccess => translate('logout_success');

  // Navigation
  String get home => translate('home');
  String get discover => translate('discover');
  String get bookmarks => translate('bookmarks');
  String get profile => translate('profile');

  // Settings
  String get settings => translate('settings');
  String get account => translate('account');
  String get notifications => translate('notifications');
  String get darkMode => translate('dark_mode');
  String get language => translate('language');
  String get security => translate('security');
  String get termsAndConditions => translate('terms_and_conditions');
  String get privacyPolicy => translate('privacy_policy');
  String get help => translate('help');
  String get inviteFriends => translate('invite_friends');
  String get selectLanguage => translate('select_language');
  String get vietnamese => translate('vietnamese');
  String get english => translate('english');

  // Notifications
  String get notificationEnabled => translate('notification_enabled');
  String get notificationDisabled => translate('notification_disabled');
  String get testNotification => translate('test_notification');

  // Features coming soon
  String get securityComingSoon => translate('security_coming_soon');
  String get termsOpening => translate('terms_opening');
  String get privacyOpening => translate('privacy_opening');
  String get helpOpening => translate('help_opening');
  String get inviteComingSoon => translate('invite_coming_soon');

  // Home Screen
  String get latestNews => translate('latest_news');
  String get favoriteTopics => translate('favorite_topics');
  String get noFavoriteTopics => translate('no_favorite_topics');
  String get addFavoriteTopics => translate('add_favorite_topics');
  String get all => translate('all');

  // Article
  String get readMore => translate('read_more');
  String get share => translate('share');
  String get bookmark => translate('bookmark');
  String get bookmarked => translate('bookmarked');
  String get readingHistory => translate('reading_history');
  String get noArticles => translate('no_articles');
  String get loadMore => translate('load_more');

  // Profile
  String get editProfile => translate('edit_profile');
  String get changePassword => translate('change_password');
  String get readingStatistics => translate('reading_statistics');
  String get articlesRead => translate('articles_read');
  String get favorites => translate('favorites');

  // Discover
  String get trending => translate('trending');
  String get categories => translate('categories');
  String get topics => translate('topics');

  // Bookmarks
  String get bookmarksTitle => translate('bookmarks_title');
  String get noBookmarks => translate('no_bookmarks');
  String get removeBookmark => translate('remove_bookmark');

  // Topics Selection
  String get selectTopics => translate('select_topics');
  String get chooseInterests => translate('choose_interests');
  String get topicsDescription => translate('topics_description');
  String get topicsPersonalizeDescription => translate('topics_personalize_description');
  String get topicsSelected => translate('topics_selected');
  String get continueText => translate('continue');
  String get skip => translate('skip');
  String get skipForNow => translate('skip_for_now');
  String get selectAtLeastOne => translate('select_at_least_one');
  String topicsSavedSuccess(int count) => translate('topics_saved_success').replaceAll('{count}', count.toString());
  String errorSavingTopics(String error) => translate('error_saving_topics').replaceAll('{error}', error);

  // Categories
  String get categoryAll => translate('category_all');
  String get categoryLatest => translate('category_latest');
  String get categoryPolitics => translate('category_politics');
  String get categoryBusiness => translate('category_business');
  String get categoryTechnology => translate('category_technology');
  String get categorySports => translate('category_sports');
  String get categoryEntertainment => translate('category_entertainment');
  String get categoryHealth => translate('category_health');
  String get categoryScience => translate('category_science');
  String get categoryWorld => translate('category_world');

  // Error messages
  String get errorLoading => translate('error_loading');
  String get errorNetwork => translate('error_network');
  String get errorUnknown => translate('error_unknown');
  String get errorLogin => translate('error_login');
  String get errorSignup => translate('error_signup');

  // Success messages
  String get saveSuccess => translate('save_success');
  String get updateSuccess => translate('update_success');
  String get deleteSuccess => translate('delete_success');
}

