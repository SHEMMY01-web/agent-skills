---
name: database-concurrency-atomic-rpc
description: >-
  PostgreSQL and Supabase concurrency control, atomic stored procedures (RPCs), row-level locks
  (SELECT FOR UPDATE), transaction rollbacks, race condition mitigation for stock/balance mutations,
  and formula injection sanitization distilled from CIH Inventory. Use when designing transactional
  backends, inventory checkouts, financial balances, or data export routines.
---

# Database Concurrency & Atomic RPC Architecture

A production-proven guide for handling concurrent mutations, eliminating negative balance race conditions, and enforcing database-level integrity in PostgreSQL and Supabase backends.

---

## 1. When to Activate This Skill
- Multiple users or background workers concurrently update counters, inventory balances, or ledger records.
- Eliminating race conditions between `SELECT` and `UPDATE` statements.
- Authoring PostgreSQL stored procedures (RPCs) with explicit transaction boundaries.
- Graceful client-side handling of check constraint violations (PostgreSQL error `23514`).
- Sanitizing tabular data exports (CSV/Excel) against Formula Injection attacks.

---

## 2. The Concurrency Problem: Read-Modify-Write Anti-Pattern

```
User A: Reads Stock = 1 ──────────> Deducts 1 (Stock = 0) ──> Saves (Stock = 0)
User B: Reads Stock = 1 (RACE!) ──> Deducts 1 (Stock = 0) ──> Saves (Negative Stock / Duplicate Item!)
```

### The Solution: Atomic RPC with `SELECT ... FOR UPDATE`

```sql
CREATE OR REPLACE FUNCTION execute_inventory_transaction(
    p_item_id UUID,
    p_user_id UUID,
    p_qty INTEGER,
    p_tx_type TEXT,
    p_notes TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_current_stock INTEGER;
    v_item_name TEXT;
    v_tx_id UUID;
BEGIN
    -- 1. Lock the specific row for update across concurrent transactions
    SELECT quantity, name INTO v_current_stock, v_item_name
    FROM inventory_items
    WHERE id = p_item_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Item with ID % not found.', p_item_id USING ERRCODE = 'P0002';
    END IF;

    -- 2. Validate stock boundary
    IF p_tx_type = 'checkout' THEN
        IF v_current_stock < p_qty THEN
            RAISE EXCEPTION 'Insufficient stock. Available: %, Requested: %', v_current_stock, p_qty
                USING ERRCODE = '23514'; -- Check violation
        END IF;

        UPDATE inventory_items
        SET quantity = quantity - p_qty,
            updated_at = NOW()
        WHERE id = p_item_id;

    ELSIF p_tx_type = 'return' THEN
        UPDATE inventory_items
        SET quantity = quantity + p_qty,
            updated_at = NOW()
        WHERE id = p_item_id;
    ELSE
        RAISE EXCEPTION 'Invalid transaction type: %', p_tx_type;
    END IF;

    -- 3. Log the transaction ledger record
    INSERT INTO inventory_transactions (item_id, user_id, quantity, tx_type, notes, created_at)
    VALUES (p_item_id, p_user_id, p_qty, p_tx_type, p_notes, NOW())
    RETURNING id INTO v_tx_id;

    RETURN jsonb_build_object(
        'success', true,
        'transaction_id', v_tx_id,
        'item_name', v_item_name,
        'previous_stock', v_current_stock,
        'new_stock', CASE WHEN p_tx_type = 'checkout' THEN v_current_stock - p_qty ELSE v_current_stock + p_qty END
    );
END;
$$;
```

---

## 3. Client-Side RPC Integration & Rollback Handling

When invoking the atomic procedure from the frontend, catch specific constraint violations and handle fallback states:

```javascript
export async function executeCheckout(supabase, itemId, userId, quantity, notes) {
  try {
    const { data, error } = await supabase.rpc('execute_inventory_transaction', {
      p_item_id: itemId,
      p_user_id: userId,
      p_qty: Number(quantity),
      p_tx_type: 'checkout',
      p_notes: notes
    });

    if (error) {
      // PostgreSQL check_violation or custom error code
      if (error.code === '23514' || error.message?.includes('Insufficient stock')) {
        throw new Error(`Insufficient stock for checkout. ${error.message}`);
      }
      throw error;
    }

    return data;
  } catch (err) {
    console.error('[Transaction Error]', err.message);
    throw err;
  }
}
```

---

## 4. Database Schema Hardening Check Constraints
Always place an uncircumventable constraint directly on the database table:

```sql
-- Guarantees quantity can NEVER drop below zero, even if application logic is bypassed
ALTER TABLE inventory_items
ADD CONSTRAINT chk_inventory_quantity_non_negative CHECK (quantity >= 0);
```

---

## 5. Security Guardrail: CSV / Excel Formula Injection Sanitization
When allowing users to export inventory or transaction logs to CSV/Excel, malicious input starting with `=`, `+`, `-`, or `@` will execute arbitrary commands on client machines:

```javascript
/**
 * Sanitizes cell values to prevent CSV / Excel Formula Injection (CWE-1236).
 */
export function sanitizeForCsv(value) {
  if (value === null || value === undefined) return '""';
  let str = String(value).trim();

  // If the cell begins with dangerous formula characters, prefix with single-quote
  if (/^[=+\-@\t\r]/.test(str)) {
    str = `'${str}`;
  }

  // Escape internal double quotes and wrap in quotes
  return `"${str.replace(/"/g, '""')}"`;
}

export function generateSafeCsv(rows, headers) {
  const headerLine = headers.map(h => `"${h.label.replace(/"/g, '""')}"`).join(',');
  const dataLines = rows.map(row => {
    return headers.map(h => sanitizeForCsv(row[h.key])).join(',');
  });

  return [headerLine, ...dataLines].join('\n');
}
```

---

## 6. Verification Checklist
- [ ] Concurrency Test: Trigger 5 simultaneous checkout requests for an item with only 1 unit remaining. Verify that exactly 1 succeeds and 4 receive clean "Insufficient stock" errors.
- [ ] Constraint Verification: Verify that direct raw `UPDATE` attempting negative values fails with error `23514`.
- [ ] Export Test: Insert test data starting with `=SUM(1+1)` and verify exported CSV prefixes the cell with `'` to prevent command execution.
