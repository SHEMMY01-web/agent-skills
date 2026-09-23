---
name: supabase-postgresql-mastery
description: >-
  Production-grade Supabase and PostgreSQL architecture, connection pool resilience,
  Row Level Security (RLS) enforcement, idempotent upserts, resilient table fallbacks,
  and real-time subscription lifecycle management. Use when designing, querying,
  migrating, or debugging Supabase backends and relational database workflows.
---

# Supabase & PostgreSQL Mastery

A battle-tested engineering runbook for architecting resilient, production-ready Supabase backends. Covers connection pooling, Row Level Security, schema alignment, idempotent mutations, and real-time subscription leak prevention.

---

## 1. When to Use
- Designing or auditing database schemas, tables, relationships, and foreign key constraints.
- Implementing Row Level Security (RLS) policies and user permission boundaries.
- Resolving cold-start connection timeouts, PgBouncer pool limits, or dropped connections.
- Implementing idempotent database writes (`onConflict`, upserts) and transaction handling.
- Structuring resilient multi-table query fallbacks during schema migrations.
- Managing real-time WebSocket subscriptions without leaking client memory or saturating server connection limits.

---

## 2. Core Guidelines & Best Practices

### 1. Connection Pool Sizing & Port Routing
- **Transaction Mode (Port 6543 / PgBouncer):** Always use for serverless functions, Edge Functions, and containerized backends (e.g. Render, Vercel) where connections open and close rapidly. Never use prepared statements in transaction mode unless explicitly supported.
- **Session Mode (Port 5432 / Direct):** Reserve exclusively for long-lived migrations, direct schema alterations, or dedicated microservices that manage their own connection pooling.
- **Connection Guards:** Always wrap database calls with explicit client-side timeouts (e.g., 10-30s) to prevent frozen requests when instances resume from cold storage.

### 2. Strict Row Level Security (RLS) & Definer Rules
- **Enable RLS Unconditionally:** Every created table MUST have `ALTER TABLE <table> ENABLE ROW LEVEL SECURITY;`.
- **Policy Enforcement:** Use `auth.uid()` for user-bound rows:
  ```sql
  CREATE POLICY "Users can only read their own records"
    ON contracts FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);
  ```
- **Security Definer vs. Invoker:** Mark stored procedures `SECURITY INVOKER` by default. Only use `SECURITY DEFINER` when executing privileged system tasks (e.g. audit logs, user creation hooks), and always set an explicit `search_path`:
  ```sql
  CREATE OR REPLACE FUNCTION handle_new_user()
  RETURNS trigger
  LANGUAGE plpgsql
  SECURITY DEFINER SET search_path = public
  AS $$ ... $$;
  ```

### 3. Idempotent Upserts & Conflict Boundaries
- Never assume single-record inserts succeed unconditionally in distributed systems.
- Use explicit conflict targets:
  ```javascript
  const { data, error } = await supabase
    .from('strategy_playbooks')
    .upsert({
      user_id: user.id,
      playbook_data: settings,
      updated_at: new Date().toISOString()
    }, { onConflict: 'user_id' });
  ```
- Guard against schema discrepancies: If an older client writes to a deprecated table name (e.g. `user_profiles`), establish an automatic query fallback to the canonical table (`strategy_playbooks`) to prevent data loss.

### 4. Resilient Table Fallbacks & Schema Evolution
- When evolving schemas in production, provide graceful fallback paths in service layers:
  ```javascript
  let { data, error } = await client.from('primary_table').select('id').limit(1);
  if (error && error.code === 'PGRST204') { // Schema or relation error
    const fallback = await client.from('legacy_or_secondary_table').select('id').limit(1);
    if (!fallback.error) {
      data = fallback.data;
      error = null;
    }
  }
  ```

### 5. Real-Time Channel Lifecycle & Leak Prevention
- Always store channel references and unsubscribe cleanly on component teardown or page transition:
  ```javascript
  useEffect(() => {
    const channel = supabase
      .channel('table-db-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'items' }, handleChange)
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, []);
  ```
- Never create ad-hoc anonymous channels inside high-frequency render loops or polling intervals.

---

## 3. Recommended Workflow & Procedures

### Step 1: Schema Migration & Constraint Verification
1. Author migration scripts with idempotent guards (`IF NOT EXISTS`, `ON CONFLICT DO NOTHING`).
2. Add foreign keys with explicit cascade policies (`ON DELETE CASCADE` or `ON DELETE SET NULL`).
3. Create indexes on frequently queried foreign keys and composite filter columns:
   ```sql
   CREATE INDEX IF NOT EXISTS idx_contracts_user_id ON contracts(user_id);
   CREATE INDEX IF NOT EXISTS idx_contracts_created_at ON contracts(created_at DESC);
   ```

### Step 2: Client Initialization & Error Wrapping
Wrap client initialization with credential validation and environment guards:
```javascript
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseKey) {
  console.warn('[Supabase] Warning: Missing credentials. Operating in degraded mode.');
}

const supabase = createClient(supabaseUrl || 'https://placeholder.supabase.co', supabaseKey || 'placeholder', {
  auth: { persistSession: false, autoRefreshToken: false },
  db: { schema: 'public' }
});
```

---

## 4. Verification & Validation
- **RLS Verification:** Test querying tables as an anonymous client, an authenticated user, and a service role. Verify unauthenticated queries return 0 rows or 403 Forbidden.
- **Connection Leak Test:** Run concurrent request tests (e.g. 20-50 simultaneous reads) and inspect connection metrics in Supabase dashboard to verify pool stability.
- **Teardown Test:** Mount and unmount real-time components rapidly; assert active channel count in `supabase.getChannels()` remains 0 after exit.
