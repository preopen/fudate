# WS3 スキーマ + RLS 結果

## 結論

P0 のデータ層は **GRDB ローカル正 + Supabase Postgres/RLS migration** で実装する。

WS2で採用した GRDB + 自作同期を前提に、端末側は `packages/Data` の SQLite schema を当日ボード/設定/シミュレーションのローカル正とする。Supabase 側は `supabase/migrations/202606170001_ws3_p0_schema_rls.sql` で `docs/data-schema.md` の ★ テーブルのみを作成し、全テーブルに tenant RLS を適用する。

## 実装

- ローカルデータ層: `packages/Data`
- Supabase migration: `supabase/migrations/202606170001_ws3_p0_schema_rls.sql`
- P0対象: `restaurant` / `owner_account` / `section` / `course_template` / `dish` / `component` / `prep_task` / `service_day` / `service_cover` / `task_instance` / `waste_log` / `business_calendar` / `device` / `settings` / `entitlement` / `event_log` / `reservation`
- P1+対象: label / printer / storage_unit / temp_log / HACCP / Direct / store_membership は作成しない

## RLS

Supabase migration は `auth.jwt() ->> 'tenant_id'` を `public.current_tenant_id()` として参照し、各P0テーブルに以下を付与する。

- `alter table ... enable row level security`
- select: `tenant_id = public.current_tenant_id()`
- insert: `with check (tenant_id = public.current_tenant_id())`
- update: `using` + `with check`
- delete: `using`

## 検証

```bash
swift test --package-path packages/Data
```

検証内容:

- ★テーブル全件の作成
- 全★テーブルの `tenant_id` / `created_at` / `updated_at` / `deleted_at` 存在
- 全★テーブルに対する create/read/update/soft delete
- tenant A/B のローカル可視性分離
- Supabase migration のRLS条件とP1+テーブル未作成を機械検査

## 未実施/後続

Supabase CLI / Docker / psql がローカルに無いため、実Postgresへのmigration applyは未実施。資格情報またはローカルSupabase実行環境が揃い次第、同migrationを実DBへ適用してRLS経路を再確認する。
