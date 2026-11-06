# مكّة ماركت — حزمة متابعة الربط (مصدر برمجي)

هذه الحزمة تجمع مشروع Flutter الحالي مع Laravel API starter، وتضيف طبقة REST مشتركة في Flutter ونقطة جلب المندوبين للإدارة.

## ما أُضيف في هذه الجولة
- `lib/services/makka_api.dart`: عميل API لتسجيل الدخول، جلب المنتجات، إنشاء الطلب، عرض طلبات العميل/الإدارة/المندوب، جلب المندوبين، إسناد الطلب، وتحديث الحالة.
- `lib/services/api_config.dart`: عنوان API قابل للتحديد وقت البناء عبر `--dart-define=MAKKA_API_URL=...`.
- إضافة اعتماد `http` إلى Flutter.
- `GET /api/admin/couriers` للإدارة.
- ملف `deploy/docker-compose.yml` لتشغيل PostgreSQL محلياً.

## ما لم يكتمل بعد (بشفافية)
- واجهات Flutter القديمة ما زالت Prototype وتستخدم بيانات محلية؛ لم تُحوّل كل الشاشات بعد لاستخدام MakkaApi.
- بث Reverb اللحظي يحتاج إعداد مشروع Laravel الفعلي، مصادقة broadcast، وإضافة عميل WebSocket مناسب في Flutter ولوحة الإدارة.
- لا يوجد مشروع Laravel كامل هنا؛ هذه ملفات تُركّب داخل Laravel 11/12 حسب تعليمات backend/README.md.
- لا يوجد APK مبني أو خادم منشور في هذه البيئة. PHP متاح لكن Flutter/Dart وComposer وDocker غير متاحة هنا، لذلك لا يمكن إجراء build أو تشغيل قاعدة البيانات/الخادم من هذه الجلسة.
- بيانات المنتجات الحالية تجريبية وليست قائمة 1000 منتج معتمدة.

## إعداد Flutter
من مجلد `flutter/makka_market_full_source` بعد تثبيت Flutter:
```bash
flutter create . --platforms=android
flutter pub get
flutter analyze
flutter run --dart-define=MAKKA_API_URL=https://YOUR_DOMAIN/api
flutter build apk --release --dart-define=MAKKA_API_URL=https://YOUR_DOMAIN/api
```
للمحاكي Android مع Laravel على نفس الكمبيوتر استخدم `http://10.0.2.2:8000/api`.
للهاتف الحقيقي استخدم عنوان IP محلي أو نطاق HTTPS يمكن للهاتف الوصول إليه.

## تسلسل تجهيز Backend
1. أنشئ Laravel 11/12 وثبّت Sanctum وBroadcasting/Reverb.
2. انسخ مجلد `backend/makka_market_backend` إلى مشروع Laravel مع تطبيق تعديل `bootstrap/app.php.patch.txt`.
3. اضبط PostgreSQL وبيانات Reverb في `.env`، ولا تستخدم كلمات المرور التجريبية في الإنتاج.
4. شغّل migrations وseeder حسب README داخل backend.
5. اختبر تسجيل الدخول والمنتجات وإنشاء الطلب والإسناد وتحديث الحالة بحسابات الأدوار.

## حالات الطلب الموحدة في API
`new` → `assigned` → `preparing` → `out_for_delivery` → `delivered`

الإسناد يتم بواسطة الإدارة وينقل الحالة إلى `assigned`. المندوب لا يستطيع تحديث الطلب إلا إذا كان مسنداً إليه، ولا يسمح API بتخطي المراحل.

## تنبيه نشر
قبل تشغيل حقيقي: HTTPS، أسرار قوية، CORS محدود، rate limiting، نسخ احتياطي، مراقبة، سجل تدقيق للمخزون، رسوم توصيل حقيقية حسب مناطق العجمي، سياسة خصوصية، واختبار أمني.
