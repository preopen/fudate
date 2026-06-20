@preconcurrency import GRDB

extension PrepFlowDatabase {
    static let schemaStatements: [String] = [
        """
        create table if not exists restaurant (
          id text primary key,
          tenant_id text not null,
          name text not null,
          seats integer not null default 0,
          default_theme text,
          default_view text,
          created_at text not null default current_timestamp,
          updated_at text not null default current_timestamp,
          deleted_at text
        )
        """,
        """
        create table if not exists owner_account (
          id text primary key,
          tenant_id text not null,
          email text not null,
          auth_provider text not null check (auth_provider in ('apple', 'magiclink')),
          display_name text not null,
          role text not null check (role in ('owner', 'staff')),
          created_at text not null default current_timestamp,
          updated_at text not null default current_timestamp,
          deleted_at text
        )
        """,
        """
        create table if not exists section (
          id text primary key,
          tenant_id text not null,
          restaurant_id text not null references restaurant(id),
          name text not null,
          sort integer not null default 0,
          created_at text not null default current_timestamp,
          updated_at text not null default current_timestamp,
          deleted_at text
        )
        """,
        """
        create table if not exists course_template (
          id text primary key,
          tenant_id text not null,
          restaurant_id text not null references restaurant(id),
          name text not null,
          version integer not null default 1,
          archived integer not null default 0,
          created_at text not null default current_timestamp,
          updated_at text not null default current_timestamp,
          deleted_at text
        )
        """,
        """
        create table if not exists dish (
          id text primary key,
          tenant_id text not null,
          course_template_id text not null references course_template(id),
          name text not null,
          sort integer not null default 0,
          created_at text not null default current_timestamp,
          updated_at text not null default current_timestamp,
          deleted_at text
        )
        """,
        """
        create table if not exists component (
          id text primary key,
          tenant_id text not null,
          dish_id text not null references dish(id),
          name text not null,
          sort integer not null default 0,
          created_at text not null default current_timestamp,
          updated_at text not null default current_timestamp,
          deleted_at text
        )
        """,
        """
        create table if not exists prep_task (
          id text primary key,
          tenant_id text not null,
          component_id text not null references component(id),
          name text not null,
          scale_mode text not null check (scale_mode in ('per_cover', 'per_portion', 'fixed_batch')),
          coeff_per_cover real,
          coeff_per_portion real,
          yield real not null default 1.0,
          round_step real,
          covers_per_batch integer,
          batch_size real,
          unit text not null,
          duration_min integer not null default 0,
          lead_min_before_open integer not null default 0,
          shelf_life_days integer,
          section_id text references section(id),
          default_storage_zone text,
          instruction text,
          sort integer not null default 0,
          created_at text not null default current_timestamp,
          updated_at text not null default current_timestamp,
          deleted_at text
        )
        """,
        """
        create table if not exists service_day (
          id text primary key,
          tenant_id text not null,
          restaurant_id text not null references restaurant(id),
          date text not null,
          service_period text not null check (service_period in ('lunch', 'dinner', 'part1', 'part2')),
          open_time text not null,
          note text,
          created_at text not null default current_timestamp,
          updated_at text not null default current_timestamp,
          deleted_at text
        )
        """,
        """
        create table if not exists service_cover (
          id text primary key,
          tenant_id text not null,
          service_day_id text not null references service_day(id),
          course_template_id text not null references course_template(id),
          covers integer not null,
          created_at text not null default current_timestamp,
          updated_at text not null default current_timestamp,
          deleted_at text
        )
        """,
        """
        create table if not exists task_instance (
          id text primary key,
          tenant_id text not null,
          service_day_id text not null references service_day(id),
          prep_task_id text not null references prep_task(id),
          status text not null check (status in ('not_started', 'in_progress', 'done')),
          assignee_section_id text references section(id),
          completed_by text,
          checked_at text,
          prep_day text not null,
          planned_qty real not null,
          unit text not null,
          start_at text,
          finish_at text,
          sort integer not null default 0,
          created_at text not null default current_timestamp,
          updated_at text not null default current_timestamp,
          deleted_at text
        )
        """,
        """
        create table if not exists waste_log (
          id text primary key,
          tenant_id text not null,
          service_day_id text not null references service_day(id),
          prep_task_id text not null references prep_task(id),
          covers integer not null,
          planned_qty real not null,
          made_qty real not null,
          leftover_qty real not null,
          waste_reason text check (waste_reason in ('overmade', 'expiry', 'quality', 'other')),
          carryover_to_next integer not null default 0,
          unit text not null,
          recorded_by text,
          created_at text not null default current_timestamp,
          updated_at text not null default current_timestamp,
          deleted_at text
        )
        """,
        """
        create table if not exists business_calendar (
          id text primary key,
          tenant_id text not null,
          restaurant_id text not null references restaurant(id),
          closed_dates text not null default '[]',
          closed_weekdays text not null default '[]',
          holidays text not null default '[]',
          created_at text not null default current_timestamp,
          updated_at text not null default current_timestamp,
          deleted_at text
        )
        """,
        """
        create table if not exists device (
          id text primary key,
          tenant_id text not null,
          name text not null,
          restaurant_id text not null references restaurant(id),
          default_view_override text,
          created_at text not null default current_timestamp,
          updated_at text not null default current_timestamp,
          deleted_at text
        )
        """,
        """
        create table if not exists settings (
          id text primary key,
          tenant_id text not null,
          restaurant_id text not null references restaurant(id),
          key text not null,
          value text not null,
          created_at text not null default current_timestamp,
          updated_at text not null default current_timestamp,
          deleted_at text
        )
        """,
        """
        create table if not exists entitlement (
          id text primary key,
          tenant_id text not null,
          plan text not null check (plan in ('free', 'lite', 'standard', 'pro', 'connect')),
          features text not null default '{}',
          valid_until text,
          created_at text not null default current_timestamp,
          updated_at text not null default current_timestamp,
          deleted_at text
        )
        """,
        """
        create table if not exists event_log (
          id text primary key,
          tenant_id text not null,
          type text not null,
          payload text not null default '{}',
          occurred_at text not null,
          actor text,
          created_at text not null default current_timestamp,
          updated_at text not null default current_timestamp,
          deleted_at text
        )
        """,
        """
        create table if not exists reservation (
          id text primary key,
          tenant_id text not null,
          service_day_id text not null references service_day(id),
          source text not null check (source in ('manual', 'csv', 'email', 'api', 'direct')),
          visit_time text not null,
          covers integer not null,
          course_template_id text references course_template(id),
          course_text text,
          party_name text,
          note text,
          structured integer not null default 0,
          dup_group text,
          created_at text not null default current_timestamp,
          updated_at text not null default current_timestamp,
          deleted_at text
        )
        """,
        """
        create table if not exists service_period (
          id text primary key,
          tenant_id text not null,
          restaurant_id text not null references restaurant(id),
          label text not null,
          service_period text not null check (service_period in ('lunch', 'dinner', 'part1', 'part2')),
          open_time text not null,
          sort integer not null default 0,
          created_at text not null default current_timestamp,
          updated_at text not null default current_timestamp,
          deleted_at text
        )
        """,
        """
        create table if not exists carryover (
          id text primary key,
          tenant_id text not null,
          from_service_day_id text not null references service_day(id),
          to_service_day_id text references service_day(id),
          prep_task_id text not null references prep_task(id),
          qty real not null,
          unit text not null,
          expire_at text,
          status text not null check (status in ('available', 'used', 'wasted', 'expired')),
          created_at text not null default current_timestamp,
          updated_at text not null default current_timestamp,
          deleted_at text
        )
        """,
        """
        create table if not exists temp_log (
          id text primary key,
          tenant_id text not null,
          storage_unit_id text,
          kind text not null check (kind in ('fridge', 'heating')),
          value real not null,
          logged_at text not null,
          by_account_id text,
          created_at text not null default current_timestamp,
          updated_at text not null default current_timestamp,
          deleted_at text
        )
        """,
        """
        create table if not exists storage_unit (
          id text primary key,
          tenant_id text not null,
          restaurant_id text not null references restaurant(id),
          name text not null,
          kind text not null check (kind in ('fridge', 'freezer', 'chiller', 'room')),
          temp_min real,
          temp_max real,
          qr_token text not null,
          created_at text not null default current_timestamp,
          updated_at text not null default current_timestamp,
          deleted_at text
        )
        """,
        """
        create table if not exists printer (
          id text primary key,
          tenant_id text not null,
          restaurant_id text not null references restaurant(id),
          name text not null,
          connection text not null check (connection in ('network', 'bluetooth', 'usb', 'pdf')),
          paper_size text not null,
          status text not null check (status in ('connected', 'offline', 'pdf')),
          is_default integer not null default 0,
          last_tested_at text,
          created_at text not null default current_timestamp,
          updated_at text not null default current_timestamp,
          deleted_at text
        )
        """,
        """
        create table if not exists label (
          id text primary key,
          tenant_id text not null,
          task_instance_id text not null references task_instance(id),
          printed_at text,
          made_qty real not null,
          expire_at text,
          qr_token text not null,
          status text not null check (status in ('active', 'remaining', 'used', 'wasted')),
          remaining_qty real,
          storage_unit_id text,
          created_at text not null default current_timestamp,
          updated_at text not null default current_timestamp,
          deleted_at text
        )
        """,
        """
        create table if not exists larder_item (
          id text primary key,
          tenant_id text not null,
          label_id text references label(id),
          prep_task_id text not null references prep_task(id),
          qty real not null,
          unit text not null,
          expire_at text,
          status text not null check (status in ('available', 'used', 'wasted', 'expired')),
          created_at text not null default current_timestamp,
          updated_at text not null default current_timestamp,
          deleted_at text
        )
        """,
        """
        create table if not exists connector_account (
          id text primary key,
          tenant_id text not null,
          provider text not null check (provider in ('tablecheck', 'toreta', 'pos', 'kds')),
          status text not null check (status in ('mock', 'pending', 'connected', 'disabled')),
          external_account_id text,
          last_sync_at text,
          created_at text not null default current_timestamp,
          updated_at text not null default current_timestamp,
          deleted_at text
        )
        """,
        """
        create table if not exists source_event (
          id text primary key,
          tenant_id text not null,
          connector_account_id text references connector_account(id),
          source text not null,
          external_id text,
          type text not null,
          payload text not null default '{}',
          occurred_at text not null,
          processed_at text,
          created_at text not null default current_timestamp,
          updated_at text not null default current_timestamp,
          deleted_at text
        )
        """,
        """
        create table if not exists direct_booking (
          id text primary key,
          tenant_id text not null,
          service_day_id text references service_day(id),
          status text not null check (status in ('request', 'confirmed', 'cancelled', 'noshow')),
          visit_time text not null,
          covers integer not null,
          course_text text,
          guest_note text,
          stripe_checkout_id text,
          created_at text not null default current_timestamp,
          updated_at text not null default current_timestamp,
          deleted_at text
        )
        """,
        """
        create table if not exists waitlist_entry (
          id text primary key,
          tenant_id text not null,
          service_day_id text references service_day(id),
          direct_booking_id text references direct_booking(id),
          visit_time text not null,
          covers integer not null,
          guest_name text not null,
          status text not null check (status in ('waiting', 'offered', 'confirmed', 'expired')),
          created_at text not null default current_timestamp,
          updated_at text not null default current_timestamp,
          deleted_at text
        )
        """,
        """
        create table if not exists special_prep (
          id text primary key,
          tenant_id text not null,
          service_day_id text not null references service_day(id),
          reservation_id text,
          title text not null,
          note text,
          status text not null check (status in ('not_started', 'in_progress', 'done')),
          created_at text not null default current_timestamp,
          updated_at text not null default current_timestamp,
          deleted_at text
        )
        """,
        """
        create table if not exists allergen_label (
          id text primary key,
          tenant_id text not null,
          service_day_id text not null references service_day(id),
          reservation_id text,
          seat_ref text not null,
          display_text text not null,
          language text not null default 'ja',
          created_at text not null default current_timestamp,
          updated_at text not null default current_timestamp,
          deleted_at text
        )
        """,
        """
        create table if not exists guest_message (
          id text primary key,
          tenant_id text not null,
          service_day_id text not null references service_day(id),
          reservation_id text,
          channel text not null,
          language text not null default 'ja',
          body text not null,
          status text not null check (status in ('draft', 'queued', 'sent', 'failed')),
          created_at text not null default current_timestamp,
          updated_at text not null default current_timestamp,
          deleted_at text
        )
        """,
        """
        create table if not exists pass_seat_flag (
          id text primary key,
          tenant_id text not null,
          service_day_id text not null references service_day(id),
          reservation_id text,
          seat_ref text not null,
          kind text not null check (kind in ('allergy', 'vip', 'special')),
          display_text text not null,
          created_at text not null default current_timestamp,
          updated_at text not null default current_timestamp,
          deleted_at text
        )
        """,
        """
        create table if not exists service_event (
          id text primary key,
          tenant_id text not null,
          service_day_id text not null references service_day(id),
          type text not null,
          payload text not null default '{}',
          occurred_at text not null,
          source text not null check (source in ('prepflow', 'pos', 'kds', 'manual')),
          created_at text not null default current_timestamp,
          updated_at text not null default current_timestamp,
          deleted_at text
        )
        """,
        """
        create table if not exists dayrail_item (
          id text primary key,
          tenant_id text not null,
          service_day_id text not null references service_day(id),
          kind text not null check (kind in ('prep', 'service', 'close')),
          ref_id text not null,
          title text not null,
          prep_day_offset integer not null default 0,
          start_at text not null,
          finish_at text not null,
          status text not null check (status in ('not_started', 'in_progress', 'done')),
          sort integer not null default 0,
          created_at text not null default current_timestamp,
          updated_at text not null default current_timestamp,
          deleted_at text
        )
        """,
        """
        create table if not exists subrecipe_aggregate (
          id text primary key,
          tenant_id text not null,
          service_day_id text not null references service_day(id),
          prep_task_id text not null references prep_task(id),
          total_covers integer not null,
          total_qty real not null,
          unit text not null,
          sources text not null default '[]',
          status text not null check (status in ('not_started', 'in_progress', 'done')),
          created_at text not null default current_timestamp,
          updated_at text not null default current_timestamp,
          deleted_at text
        )
        """,
        """
        create table if not exists subrecipe_reference (
          id text primary key,
          tenant_id text not null,
          aggregate_id text not null references subrecipe_aggregate(id),
          course_key text not null,
          covers integer not null,
          rollup_status text not null check (rollup_status in ('not_started', 'in_progress', 'done')),
          created_at text not null default current_timestamp,
          updated_at text not null default current_timestamp,
          deleted_at text
        )
        """,
        "create index if not exists restaurant_tenant_idx on restaurant(tenant_id)",
        "create index if not exists owner_account_tenant_idx on owner_account(tenant_id)",
        "create index if not exists section_tenant_idx on section(tenant_id)",
        "create index if not exists course_template_tenant_idx on course_template(tenant_id)",
        "create index if not exists dish_tenant_idx on dish(tenant_id)",
        "create index if not exists component_tenant_idx on component(tenant_id)",
        "create index if not exists prep_task_tenant_idx on prep_task(tenant_id)",
        "create index if not exists service_day_tenant_idx on service_day(tenant_id)",
        "create index if not exists service_cover_tenant_idx on service_cover(tenant_id)",
        "create index if not exists task_instance_tenant_idx on task_instance(tenant_id)",
        "create index if not exists task_instance_service_status_idx on task_instance(service_day_id, status)",
        "create index if not exists task_instance_prep_day_idx on task_instance(prep_day)",
        "create index if not exists waste_log_tenant_idx on waste_log(tenant_id)",
        "create index if not exists waste_log_task_created_idx on waste_log(prep_task_id, created_at)",
        "create index if not exists business_calendar_tenant_idx on business_calendar(tenant_id)",
        "create index if not exists device_tenant_idx on device(tenant_id)",
        "create index if not exists settings_tenant_idx on settings(tenant_id)",
        "create index if not exists entitlement_tenant_idx on entitlement(tenant_id)",
        "create index if not exists event_log_tenant_idx on event_log(tenant_id)",
        "create index if not exists reservation_tenant_idx on reservation(tenant_id)",
        "create index if not exists reservation_service_visit_idx on reservation(service_day_id, visit_time)",
        "create index if not exists service_period_tenant_idx on service_period(tenant_id)",
        "create index if not exists carryover_tenant_idx on carryover(tenant_id)",
        "create index if not exists temp_log_tenant_idx on temp_log(tenant_id)",
        "create index if not exists label_tenant_idx on label(tenant_id)",
        "create index if not exists larder_item_tenant_idx on larder_item(tenant_id)",
        "create index if not exists connector_account_tenant_idx on connector_account(tenant_id)",
        "create index if not exists source_event_tenant_idx on source_event(tenant_id)",
        "create index if not exists direct_booking_tenant_idx on direct_booking(tenant_id)",
        "create index if not exists waitlist_entry_tenant_idx on waitlist_entry(tenant_id)",
        "create index if not exists special_prep_tenant_idx on special_prep(tenant_id)",
        "create index if not exists allergen_label_tenant_idx on allergen_label(tenant_id)",
        "create index if not exists guest_message_tenant_idx on guest_message(tenant_id)",
        "create index if not exists pass_seat_flag_tenant_idx on pass_seat_flag(tenant_id)",
        "create index if not exists service_event_tenant_idx on service_event(tenant_id)",
        "create index if not exists dayrail_item_tenant_idx on dayrail_item(tenant_id)",
        "create index if not exists dayrail_item_service_sort_idx on dayrail_item(service_day_id, sort)",
        "create index if not exists subrecipe_aggregate_tenant_idx on subrecipe_aggregate(tenant_id)",
        "create index if not exists subrecipe_reference_tenant_idx on subrecipe_reference(tenant_id)",
    ]
}
