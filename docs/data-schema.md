# データスキーマ（P0実装用・`architecture.md §6` の具体化）

| 項目 | 内容 |
|---|---|
| ローカル | SQLite（GRDB）＝オフラインの正。当日ボードはここを読む |
| 同期/クラウド | Supabase Postgres（PowerSync または GRDB+自作同期で WS2 確定）。**全テーブル RLS でテナント分離** |
| 規約 | 主キー ULID(text)。全行 `tenant_id`(text)・`created_at`/`updated_at`(timestamptz)・`deleted_at`(nullable=soft delete)。列は snake_case |

> P0で**作るテーブルは★印**。それ以外は後フェーズ（スキーマ予約のみ）。材料(Ingredient)テーブルは作らない（§2.2）。

## ★ コア（P0）
```
restaurant★        (id, tenant_id, name, seats, default_theme, default_view, created_at, updated_at, deleted_at)
owner_account★     (id, tenant_id, email, auth_provider['apple'|'magiclink'], display_name, role['owner'|'staff'], created_at, ...)
section★           (id, tenant_id, restaurant_id→restaurant, name, sort, ...)             -- 例: シャリ場/親方/ガルド
course_template★   (id, tenant_id, restaurant_id, name, version, archived bool, ...)       -- FR-01/30
dish★              (id, tenant_id, course_template_id→course_template, name, sort, ...)
component★         (id, tenant_id, dish_id→dish, name, sort, ...)
prep_task★         (id, tenant_id, component_id→component, name,
                    scale_mode['per_cover'|'per_portion'|'fixed_batch'],
                    coeff_per_cover real, coeff_per_portion real, yield real default 1.0,
                    round_step real, covers_per_batch int, batch_size real, unit text,
                    duration_min int, lead_min_before_open int, shelf_life_days int,
                    section_id→section, default_storage_zone text, sort, ...)               -- FR-37/03/06
media_asset        (id, tenant_id, prep_task_id→prep_task, type['manual'|'photo'|'video'], url, ...)  -- FR-01（P1）
service_day★       (id, tenant_id, restaurant_id, date, service_period['lunch'|'dinner'|'part1'|'part2'],
                    open_time text /*=T0 "HH:mm"*/, note, created_at, ...)                  -- FR-02/41
service_cover★     (id, tenant_id, service_day_id→service_day, course_template_id, covers int)  -- コース別人数
task_instance★     (id, tenant_id, service_day_id→service_day, prep_task_id→prep_task,
                    status['not_started'|'in_progress'|'done'], assignee_section_id,
                    completed_by text /*任意*/, checked_at timestamptz,
                    prep_day date /*=提供日−リード（営業日カレンダー考慮）*/,
                    planned_qty real, unit text, start_at text, finish_at text, sort)        -- FR-04/05/40/43 / A-2
waste_log★         (id, tenant_id, service_day_id, prep_task_id, covers int,
                    planned_qty real, made_qty real, leftover_qty real,
                    waste_reason['overmade'|'expiry'|'quality'|'other'] null,
                    carryover_to_next bool, unit text, recorded_by text, created_at, ...)    -- FR-08/09/42/68
business_calendar★ (id, tenant_id, restaurant_id, closed_dates jsonb /*["2026-06-16"]*/,
                    closed_weekdays jsonb, holidays jsonb, ...)                              -- FR-17/40基礎
device★            (id, tenant_id, name, restaurant_id, default_view_override, ...)          -- FR-53
settings★          (id, tenant_id, restaurant_id, key, value jsonb, ...)                     -- 自己補正既定/閾値/繰越/先読み等（§4.7）
entitlement★       (id, tenant_id, plan['free'|'lite'|'standard'|'pro'|'connect'],
                    features jsonb /*機能フラグ表 A-8*/, valid_until, ...)
event_log★         (id, tenant_id, type text /*§14語彙*/, payload jsonb, occurred_at, actor)  -- A-1 in-process＋監査
```

## 予約（P0は手入力のみ・構造は用意）
```
reservation★       (id, tenant_id, service_day_id, source['manual'|'csv'|'email'|'api'|'direct'],
                    visit_time text, covers int, course_template_id null,
                    course_text null /*memo由来*/, party_name null,
                    structured bool /*構造化済か*/, dup_group null, created_at, ...)          -- FR-34（P0は手入力）
guest_omotenashi   (id, tenant_id, reservation_id, allergies jsonb, preferences jsonb,
                    anniversary text, vip_rank text, staff_memo text, ...)                   -- FR-13/26/47/57（P2-3・参考のみ NFR-06）
```

## 後フェーズ（スキーマ予約のみ・P0で作らない）
```
label              (task_instance_id, printed_at, made_qty, expire_at, qr_token, status, remaining_qty, storage_unit_id)  -- FR-20/45/46（ラベルモード）
printer            (model, conn, paper_size, is_default)                                      -- FR-48
storage_unit       (name, zone, qr_token, temp_min, temp_max)                                 -- FR-49
temp_log           (storage_unit_id, kind['fridge'|'heating'], value, logged_at, by)          -- FR-51
checklist_template / checklist_item / checklist_record                                        -- FR-16（HACCPモード）
direct_*           (allotment, booking, deposit, waitlist)                                    -- FR-35/36/55/56（P3.5）
store_membership   (owner_account_id, restaurant_id, role)                                    -- FR-66 多店舗（P3）
```

## RLS / テナント分離（必須・WS3受入）
- 全テーブルに `tenant_id`。Supabase RLS：`tenant_id = auth.jwt() ->> 'tenant_id'`（または membership 経由）で select/insert/update を制限。
- 多店舗（FR-66）に備え、`owner_account` ↔ `restaurant` は将来 `store_membership` で多対多化できる形に（P0は1オーナー=1店でよいが tenant 設計を壊さない）。

## 主要インデックス
- `task_instance(service_day_id, status)`、`task_instance(prep_day)`、`waste_log(prep_task_id, created_at)`、`reservation(service_day_id, visit_time)`、全テーブル `(tenant_id)`。

## マイグレーション順（WS3）
1. テナント/アカウント/restaurant/section → 2. course_template→dish→component→prep_task → 3. service_day/service_cover/reservation → 4. task_instance/waste_log → 5. business_calendar/device/settings/entitlement/event_log。
