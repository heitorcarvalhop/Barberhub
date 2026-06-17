alter table public.barbershops
  add column if not exists working_hours jsonb not null default (
    '{
      "1": {"isOpen": true, "openTime": "09:00", "closeTime": "18:00"},
      "2": {"isOpen": true, "openTime": "09:00", "closeTime": "18:00"},
      "3": {"isOpen": true, "openTime": "09:00", "closeTime": "18:00"},
      "4": {"isOpen": true, "openTime": "09:00", "closeTime": "18:00"},
      "5": {"isOpen": true, "openTime": "09:00", "closeTime": "18:00"},
      "6": {"isOpen": true, "openTime": "09:00", "closeTime": "17:00"},
      "7": {"isOpen": false, "openTime": "09:00", "closeTime": "18:00"}
    }'::jsonb
  );
