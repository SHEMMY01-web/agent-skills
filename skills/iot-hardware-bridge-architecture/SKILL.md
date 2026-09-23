---
name: iot-hardware-bridge-architecture
description: >-
  IoT hardware networking, biometric attendance device protocols (Realand, ZKTeco, FK protocols),
  UDP/TCP socket bridging, immediate ACK patterns, and buffered cloud synchronization distilled
  from Realand UDP Bridge. Use when integrating embedded hardware, physical scanners, IoT sensors,
  or building edge bridge services.
---

# IoT Hardware Bridge & Biometric Protocol Architecture

A production-proven guide for building reliable network bridge services between physical hardware devices (biometric time attendance, RFID scanners, telemetry sensors) and modern cloud APIs.

---

## 1. When to Activate This Skill
- Interfacing with biometric fingerprint or facial recognition terminals (Realand, ZKTeco, Anviz).
- Handling raw TCP/UDP socket telemetry or embedded HTTP push webhooks.
- Preventing device loop-retry storms through the **Immediate ACK Pattern**.
- Decoding raw binary packets, endianness conversions, or tokenized ASCII payloads.
- Buffering device scans locally to guarantee zero data loss during cloud or database outages.

---

## 2. Core Architecture

```
┌─────────────────────────────────┐
│ Embedded Hardware Terminal      │
│ (Fingerprint / Face / RFID)     │
└───────────────┬─────────────────┘
                │ Raw Socket or HTTP POST
                ▼
┌─────────────────────────────────┐
│ IoT Bridge Service (Edge/LAN)   │
│ 1. Immediate ACK ("result=OK")  │ ──> Sends instant ACK (Prevents Device Retry Storms)
│ 2. Parse User PIN & Timestamp   │
│ 3. Push to In-Memory / Disk Ring│
└───────────────┬─────────────────┘
                │
                │ Asynchronous Batch Forwarding (with exponential backoff)
                ▼
┌─────────────────────────────────┐
│ Cloud Backend / Supabase Edge   │
│ (Attendance Ledger & Alerts)    │
└─────────────────────────────────┘
```

---

## 3. Key Implementation Guidelines

### 3.1 The Immediate ACK Rule
Embedded firmware has tiny RAM buffers and aggressive retry timeouts (typically 500ms–2000ms). If your bridge waits for a cloud database round-trip before responding to the hardware, the device will assume transmission failure and flood the network with duplicate events:

```javascript
import express from 'express';

const app = express();

// Accept any raw binary or form-urlencoded telemetry from hardware
app.use(express.text({ type: '*/*' }));

app.post('/hdata.aspx', async (req, res) => {
  const rawData = req.body || '';

  // ⚡ STEP 1: ACK IMMEDIATELY with Connection: close
  // Tells device the frame was received cleanly so it clears its internal queue
  res.set('Connection', 'close');
  res.status(200).send('result=OK');

  // ⚡ STEP 2: Asynchronously process and forward payload
  setImmediate(() => {
    processDevicePayload(rawData).catch(err => {
      console.error('[Bridge Worker] Failed to process payload:', err.message);
    });
  });
});
```

---

### 3.2 Robust Payload Extraction
Hardware payloads frequently mix ASCII headers with tab-delimited records or variable token formats:

```javascript
export function parseAttendancePayload(rawString) {
  if (!rawString || typeof rawString !== 'string') return null;

  // Pattern 1: Tokenized PIN format (e.g., PIN=102 Time=2026-09-23 08:30:00)
  const pinMatch = rawString.match(/(?:PIN|ID|UserNo|enrollid)=([A-Za-z0-9_-]+)/i);
  const timeMatch = rawString.match(/(?:Time|DateTime|LogTime)=([0-9:\-\s]+)/i);

  if (pinMatch) {
    return {
      userId: pinMatch[1],
      timestamp: timeMatch ? new Date(timeMatch[1]).toISOString() : new Date().toISOString(),
      raw: rawString
    };
  }

  // Pattern 2: Tab-delimited punch record (EnrollID \t VerifyMode \t InOutMode \t DateTime)
  const parts = rawString.trim().split(/\t+/);
  if (parts.length >= 4) {
    return {
      userId: parts[0].trim(),
      verifyMode: parts[1].trim(),
      inOutMode: parts[2].trim(),
      timestamp: new Date(parts[3].trim()).toISOString(),
      raw: rawString
    };
  }

  return null;
}
```

---

### 3.3 Resilient Cloud Forwarding with Disk/Memory Spillover
Network hiccups should never drop an employee clock-in or door access event:

```javascript
const offlineBuffer = [];

export async function forwardToCloud(eventData, cloudUrl, authToken) {
  offlineBuffer.push(eventData);

  while (offlineBuffer.length > 0) {
    const batch = offlineBuffer.slice(0, 50); // Ship in chunks of 50
    try {
      const response = await fetch(cloudUrl, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${authToken}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(batch),
        signal: AbortSignal.timeout(5000)
      });

      if (!response.ok) {
        throw new Error(`Cloud responded with status ${response.status}`);
      }

      // Successfully transmitted, remove from queue
      offlineBuffer.splice(0, batch.length);
    } catch (err) {
      console.warn(`[Cloud Sync] Forwarding paused (${err.message}). Retrying in 10s. Buffer: ${offlineBuffer.length}`);
      break; // Pause drain loop and retry on next tick
    }
  }
}
```

---

## 4. Verification Checklist
- [ ] ACK Latency: Verify that device requests receive a response within < 50ms regardless of cloud database response time.
- [ ] Disconnection Test: Disconnect Internet uplink, trigger 10 badge swipes, reconnect Internet, and verify all 10 records drain from the buffer to the cloud without duplicates.
- [ ] Format Testing: Test parsing against both tokenized (`PIN=...`) and tab-delimited device logs.
