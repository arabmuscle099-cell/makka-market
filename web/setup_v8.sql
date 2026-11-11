-- setup_v8: كوبونات خصم + مناطق توصيل + مواعيد توصيل. شغّله كله مرة واحدة في SQL Editor (بعد setup_v7.sql). آمن لو اتشغل أكتر من مرة.
begin;

alter table public.orders add column if not exists discount numeric not null default 0;
alter table public.orders add column if not exists coupon_code text;
alter table public.orders add column if not exists delivery_zone text;
alter table public.orders add column if not exists delivery_slot text;
alter table public.app_settings add column if not exists slots_text text;

-- الإجمالي = المنتجات - الخصم + التوصيل (حتى لو الأدمن عدّل رسوم التوصيل بعدين)
create or replace function public.orders_fix_total() returns trigger language plpgsql as $$
begin
  new.total := coalesce(new.subtotal,0) - coalesce(new.discount,0) + coalesce(new.delivery_fee,0);
  return new;
end $$;
drop trigger if exists orders_fix_total on public.orders;
create trigger orders_fix_total before update of subtotal, delivery_fee, discount on public.orders
  for each row execute function public.orders_fix_total();

-- الكوبونات
create table if not exists public.coupons (
  code text primary key check (code = upper(code) and length(code) between 3 and 30),
  kind text not null check (kind in ('percent','fixed')),
  value numeric not null check (value > 0 and (kind <> 'percent' or value <= 100)),
  min_order numeric not null default 0,
  max_discount numeric,
  max_uses int,
  used_count int not null default 0,
  expires_at timestamptz,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);
alter table public.coupons enable row level security;
drop policy if exists "admin manages coupons" on public.coupons;
create policy "admin manages coupons" on public.coupons for all to authenticated using (is_admin()) with check (is_admin());

-- مناطق التوصيل
create table if not exists public.delivery_zones (
  id bigint generated always as identity primary key,
  name text not null unique,
  fee numeric not null check (fee >= 0),
  is_active boolean not null default true
);
alter table public.delivery_zones enable row level security;
drop policy if exists "admin manages zones" on public.delivery_zones;
create policy "admin manages zones" on public.delivery_zones for all to authenticated using (is_admin()) with check (is_admin());
drop policy if exists "public reads active zones" on public.delivery_zones;
create policy "public reads active zones" on public.delivery_zones for select to anon, authenticated using (is_active);

-- مواعيد التوصيل (بتتكتب في إعدادات الإدارة)
create or replace view public.store_extras as select slots_text from public.app_settings where id = 1;
grant select on public.store_extras to anon, authenticated;

-- حساب الخصم (داخلية، العميل ما يناديهاش مباشرة)
create or replace function public._calc_coupon(p_code text, p_sub numeric, p_lock boolean default false)
returns numeric language plpgsql security definer set search_path = public as $$
declare c coupons%rowtype; d numeric;
begin
  if p_lock then select * into c from coupons where code = upper(trim(p_code)) for update;
  else select * into c from coupons where code = upper(trim(p_code)); end if;
  if not found or not c.is_active then raise exception 'كود الخصم غير صحيح'; end if;
  if c.expires_at is not null and c.expires_at < now() then raise exception 'كود الخصم منتهي'; end if;
  if c.max_uses is not null and c.used_count >= c.max_uses then raise exception 'تم استهلاك كود الخصم'; end if;
  if p_sub < c.min_order then raise exception 'الحد الأدنى لاستخدام الكود % ج.م', c.min_order; end if;
  d := case c.kind when 'percent' then round(p_sub * c.value / 100, 2) else c.value end;
  if c.max_discount is not null then d := least(d, c.max_discount); end if;
  return least(d, p_sub);
end $$;
revoke all on function public._calc_coupon(text, numeric, boolean) from public, anon, authenticated;

-- معاينة الكود في السلة
create or replace function public.check_coupon(p_code text, p_subtotal numeric) returns json
language plpgsql security definer set search_path = public as $$
declare d numeric;
begin
  if p_code is null or length(trim(p_code)) < 3 then
    return json_build_object('ok', false, 'message', 'اكتب كود الخصم'); end if;
  d := public._calc_coupon(p_code, coalesce(p_subtotal, 0), false);
  return json_build_object('ok', true, 'discount', d, 'code', upper(trim(p_code)));
exception when others then
  return json_build_object('ok', false, 'message', sqlerrm);
end $$;
revoke all on function public.check_coupon(text, numeric) from public;
grant execute on function public.check_coupon(text, numeric) to anon, authenticated;

-- الدالة القديمة بنمسحها وننشئ الجديدة (فيها كوبون ومنطقة وموعد)
drop function if exists public.place_order(text,text,text,text,jsonb,text,text);

create or replace function public.place_order(
  p_name text, p_phone text, p_address text, p_notes text, p_items jsonb,
  p_method text default 'cash', p_ref text default null,
  p_coupon text default null, p_zone text default null, p_slot text default null
) returns text
language plpgsql security definer set search_path = public as $$
declare
  v_fee numeric; v_free numeric; v_sub numeric := 0;
  v_order orders.id%type; it jsonb; r record; v_qty numeric; v_price numeric; v_min numeric; v_cfg jsonb;
  v_disc numeric := 0; v_code text; v_zone text; v_base numeric;
begin
  if length(trim(coalesce(p_name,''))) < 2 or length(trim(coalesce(p_phone,''))) < 8
     or length(trim(coalesce(p_address,''))) < 5 then raise exception 'بيانات العميل غير مكتملة'; end if;
  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0
     or jsonb_array_length(p_items) > 100 then raise exception 'السلة فارغة'; end if;
  if p_method not in ('cash','instapay','wallet','visa') then raise exception 'طريقة دفع غير صحيحة'; end if;
  -- حماية من السبام: حد أقصى 5 طلبات في الساعة لنفس رقم الهاتف، و30 طلب في الدقيقة للمتجر كله
  if (select count(*) from orders where customer_phone = trim(p_phone) and created_at > now() - interval '1 hour') >= 5 then
    raise exception 'تم تجاوز الحد المسموح من الطلبات لهذا الرقم، حاول بعد قليل'; end if;
  if (select count(*) from orders where created_at > now() - interval '1 minute') >= 30 then
    raise exception 'النظام مشغول حاليًا، حاول بعد دقيقة'; end if;
  select pay_cfg into v_cfg from app_settings where id = 1;
  if coalesce((v_cfg->>p_method)::boolean, p_method = 'cash') is not true then raise exception 'طريقة الدفع غير متاحة'; end if;
  if p_method in ('instapay','wallet') and length(trim(coalesce(p_ref,''))) < 4 then raise exception 'اكتب رقم عملية التحويل'; end if;
  insert into orders(customer_name, customer_phone, delivery_address, notes, status, subtotal, delivery_fee, total, payment_method, payment_ref, payment_status)
  values (trim(p_name), trim(p_phone), trim(p_address), nullif(trim(coalesce(p_notes,'')),''), 'new', 0, 0, 0, p_method, nullif(trim(coalesce(p_ref,'')),''), 'pending')
  returning id into v_order;
  for it in select * from jsonb_array_elements(p_items) loop
    v_qty := (it->>'qty')::numeric;
    if v_qty is null or v_qty <= 0 or v_qty > 50 then raise exception 'كمية غير صحيحة'; end if;
    select * into r from products where id::text = it->>'id' and is_active for update;
    if not found then raise exception 'منتج غير متاح'; end if;
    if r.sell_mode = 'unit' then
      if v_qty <> floor(v_qty) then raise exception 'كمية غير صحيحة'; end if;
    elsif abs(v_qty / r.qty_step - round(v_qty / r.qty_step)) > 0.0001 then
      raise exception 'الكمية لازم تكون من مضاعفات %', r.qty_step;
    end if;
    if r.stock < v_qty then raise exception 'الكمية المطلوبة من "%" غير متوفرة', r.name; end if;
    v_price := case when r.sale_price is not null and r.sale_price < r.price
                     and (r.sale_ends_at is null or r.sale_ends_at > now())
                    then r.sale_price else r.price end;
    update products set stock = stock - v_qty where id = r.id;
    -- line_total عمود محسوب، بيتحسب لوحده
    insert into order_items(order_id, product_id, product_name, unit_price, quantity, unit_name)
    values (v_order, r.id, r.name, v_price, v_qty, case when r.sell_mode <> 'unit' then r.unit end);
    v_sub := v_sub + round(v_price * v_qty, 2);
  end loop;
  select delivery_fee, free_delivery_over, coalesce(min_order, 0) into v_base, v_free, v_min from app_settings where id = 1;
  if v_min > 0 and v_sub < v_min then raise exception 'الحد الأدنى للطلب % ج.م', v_min; end if;
  -- كود الخصم (بيتحسب من السيرفر)
  if nullif(trim(coalesce(p_coupon,'')),'') is not null then
    v_code := upper(trim(p_coupon));
    v_disc := public._calc_coupon(v_code, v_sub, true);
    update coupons set used_count = used_count + 1 where code = v_code;
  end if;
  -- منطقة التوصيل
  v_fee := null;
  if exists (select 1 from delivery_zones where is_active) then
    if nullif(trim(coalesce(p_zone,'')),'') is null then raise exception 'اختر منطقة التوصيل'; end if;
    select fee into v_fee from delivery_zones where name = trim(p_zone) and is_active;
    if v_fee is null then raise exception 'منطقة التوصيل غير متاحة'; end if;
    v_zone := trim(p_zone);
  end if;
  v_fee := coalesce(v_fee, v_base, 20);
  if coalesce(v_free, 0) > 0 and v_sub >= v_free then v_fee := 0; end if;
  update orders set subtotal = v_sub, delivery_fee = v_fee, discount = v_disc, coupon_code = v_code,
    delivery_zone = v_zone, delivery_slot = left(nullif(trim(coalesce(p_slot,'')),''), 60),
    total = v_sub - v_disc + v_fee where id = v_order;
  return v_order::text;
end $$;

revoke all on function public.place_order(text,text,text,text,jsonb,text,text,text,text,text) from public;
grant execute on function public.place_order(text,text,text,text,jsonb,text,text,text,text,text) to anon, authenticated;

commit;
