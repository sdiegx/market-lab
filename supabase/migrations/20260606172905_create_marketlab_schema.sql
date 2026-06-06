-- MarketLab core schema: profiles, markets, positions, ledger_entries

-- ---------------------------------------------------------------------------
-- profiles (one row per auth user)
-- ---------------------------------------------------------------------------

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  balance_cents bigint not null check (balance_cents >= 0),
  first_name text not null default '',
  last_name text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.profiles is 'Fake-money account per user. Balance changes happen server-side only.';
comment on column public.profiles.balance_cents is 'Spendable fake balance in cents.';

-- ---------------------------------------------------------------------------
-- markets (binary Yes/No only)
-- ---------------------------------------------------------------------------

create table public.markets (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null default '',
  status text not null default 'open' check (status in ('open', 'closed', 'resolved')),
  close_date timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.markets is 'Binary Yes/No prediction markets.';

-- ---------------------------------------------------------------------------
-- positions (one row per user per market)
-- ---------------------------------------------------------------------------

create table public.positions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  market_id uuid not null references public.markets (id) on delete cascade,
  yes_shares_cents bigint not null default 0 check (yes_shares_cents >= 0),
  no_shares_cents bigint not null default 0 check (no_shares_cents >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, market_id)
);

comment on table public.positions is 'User holdings per market. 1 fake cent spent = 1 share cent.';
comment on column public.positions.yes_shares_cents is 'Yes-side shares held, in share cents.';
comment on column public.positions.no_shares_cents is 'No-side shares held, in share cents.';

create index positions_user_id_idx on public.positions (user_id);
create index positions_market_id_idx on public.positions (market_id);

-- ---------------------------------------------------------------------------
-- ledger_entries (append-only activity log)
-- ---------------------------------------------------------------------------

create table public.ledger_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  market_id uuid references public.markets (id) on delete set null,
  amount_cents bigint not null,
  entry_type text not null,
  description text not null default '',
  created_at timestamptz not null default now()
);

comment on table public.ledger_entries is 'Balance history. Writes happen server-side via RPC later.';
comment on column public.ledger_entries.market_id is 'Related market when applicable; null for non-market entries.';

create index ledger_entries_user_id_idx on public.ledger_entries (user_id);
create index ledger_entries_market_id_idx on public.ledger_entries (market_id);

-- ---------------------------------------------------------------------------
-- updated_at helper
-- ---------------------------------------------------------------------------

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row
  execute function public.set_updated_at();

create trigger markets_set_updated_at
  before update on public.markets
  for each row
  execute function public.set_updated_at();

create trigger positions_set_updated_at
  before update on public.positions
  for each row
  execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- profile creation on signup
-- ---------------------------------------------------------------------------

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  starting_balance_cents bigint := 100000; -- $1,000.00 fake starting balance
begin
  insert into public.profiles (
    id,
    balance_cents,
    first_name,
    last_name
  )
  values (
    new.id,
    starting_balance_cents,
    coalesce(new.raw_user_meta_data ->> 'first_name', ''),
    coalesce(new.raw_user_meta_data ->> 'last_name', '')
  );

  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row
  execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- row level security
-- ---------------------------------------------------------------------------

alter table public.profiles enable row level security;
alter table public.markets enable row level security;
alter table public.positions enable row level security;
alter table public.ledger_entries enable row level security;

-- Public market catalog
create policy "markets are publicly readable"
  on public.markets
  for select
  to anon, authenticated
  using (true);

-- Owner-scoped reads (no client writes; balance changes stay server-side)
create policy "users read own profile"
  on public.profiles
  for select
  to authenticated
  using (id = auth.uid());

create policy "users read own positions"
  on public.positions
  for select
  to authenticated
  using (user_id = auth.uid());

create policy "users read own ledger entries"
  on public.ledger_entries
  for select
  to authenticated
  using (user_id = auth.uid());
