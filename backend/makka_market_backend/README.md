# مكّة ماركت — Laravel API + PostgreSQL + Realtime

هذا مجلد Backend starter قابل للإضافة إلى مشروع Laravel جديد. يوفّر:
- PostgreSQL schema للمستخدمين والمنتجات والطلبات وعناصر الطلب.
- أدوار `customer`, `admin`, `courier`.
- تسجيل دخول عبر Laravel Sanctum.
- إنشاء طلب من العميل مع حجز/خصم المخزون داخل DB transaction.
- عرض الطلبات للإدارة، وإسناد الطلب لمندوب.
- تحديث حالة الطلب من المندوب.
- بث أحداث الطلبات عبر Laravel Broadcasting / Reverb إلى لوحة الإدارة والعميل والمندوب.
- قنوات خاصة مع صلاحيات وصول.

## المتطلبات
- PHP 8.2+
- Composer
- Laravel 11 أو 12
- PostgreSQL
- Laravel Sanctum
- Laravel Reverb (للاتصال اللحظي)
- Flutter app أو لوحة ويب تتصل بالـ API

## 1) إنشاء مشروع Laravel
```bash
composer create-project laravel/laravel makka-market-api
cd makka-market-api
php artisan install:api
php artisan install:broadcasting
```
اختر Reverb عند إعداد broadcasting إن ظهر الاختيار. بعد ذلك انسخ ملفات هذا المجلد إلى المسارات المناظرة داخل مشروع Laravel.

## 2) إعداد PostgreSQL و Reverb
أنشئ قاعدة بيانات ثم عدّل `.env`:
```env
APP_NAME="Makka Market"
APP_URL=http://127.0.0.1:8000

DB_CONNECTION=pgsql
DB_HOST=127.0.0.1
DB_PORT=5432
DB_DATABASE=makka_market
DB_USERNAME=postgres
DB_PASSWORD=YOUR_PASSWORD

BROADCAST_CONNECTION=reverb
REVERB_APP_ID=local-makka
REVERB_APP_KEY=local-makka-key
REVERB_APP_SECRET=replace-this-secret
REVERB_HOST=127.0.0.1
REVERB_PORT=8080
REVERB_SCHEME=http
```
لا تستخدم بيانات الاعتماد التجريبية في الإنتاج. استخدم HTTPS وأسراراً قوية.

## 3) تثبيت وتشغيل
```bash
php artisan migrate
php artisan db:seed --class=Database\\Seeders\\MakkaDemoSeeder
php artisan serve
```
في نافذة أخرى:
```bash
php artisan reverb:start
```
وفي نافذة ثالثة:
```bash
php artisan queue:work
```
للتجربة المحلية يمكن ضبط `QUEUE_CONNECTION=database` وتشغيل worker. في الإنتاج استخدم Supervisor أو خدمة إدارة عمليات موثوقة.

## 4) الحسابات التجريبية
بعد تشغيل seeder:
- الإدارة: `admin@makka.test` / `password`
- المندوب: `courier@makka.test` / `password`
- العميل: `customer@makka.test` / `password`

هذه بيانات محلية للاختبار فقط ويجب تغييرها وحذفها قبل الإنتاج.

## 5) نقاط API
كل المسارات تحت `/api`:

| Method | Endpoint | الدور | الوظيفة |
|---|---|---|---|
| POST | `/login` | عام | تسجيل الدخول وإرجاع Sanctum token |
| POST | `/logout` | مسجل | إلغاء التوكن الحالي |
| GET | `/me` | مسجل | بيانات المستخدم |
| GET | `/products` | عام | قائمة المنتجات |
| POST | `/products` | admin | إضافة منتج |
| PUT | `/products/{id}` | admin | تعديل منتج |
| POST | `/orders` | customer | إنشاء طلب |
| GET | `/orders/my` | customer | طلبات العميل |
| GET | `/admin/orders` | admin | جميع الطلبات |
| POST | `/admin/orders/{id}/assign` | admin | إسناد الطلب لمندوب |
| GET | `/courier/orders` | courier | طلبات المندوب |
| PATCH | `/courier/orders/{id}/status` | courier | تحديث حالة الطلب |

## 6) أحداث Realtime
تُبث أحداث `OrderUpdated` على قنوات خاصة:
- `private-admin.orders` للإدارة.
- `private-orders.{orderId}` للعميل صاحب الطلب.
- `private-courier.{courierId}` للمندوب المسند إليه الطلب.

الواجهة تستمع إلى الحدث ثم تعيد جلب الطلب من API. القنوات خاصة ويجري التحقق من صلاحية المستخدم في `routes/channels.php`.

## 7) مثال إنشاء طلب
```json
{
  "address": "البيطاش، العجمي، الإسكندرية",
  "notes": "الاتصال قبل الوصول",
  "items": [
    {"product_id": 1, "quantity": 2},
    {"product_id": 4, "quantity": 1}
  ]
}
```

## حدود مهمة قبل التشغيل التجاري
هذا Backend starter وليس خدمة مستضافة أو نظاماً منشوراً. يجب اختباره وتوصيله فعلياً بتطبيق Flutter ولوحة الإدارة وتطبيق المندوب. ما زال يلزم:
- ضبط CORS وHTTPS و rate limiting وسياسات كلمات المرور.
- بوابة دفع مرخصة، خرائط، وإشعارات Push.
- إدارة رسوم التوصيل ومناطق العجمي بدقة.
- إدارة الاستبدال/الوزن الفعلي للمنتجات الموزونة.
- سجل تدقيق للمخزون والمرتجعات والإلغاء والاسترداد.
- نسخ احتياطي ومراقبة وأمن واختبارات تحميل.
