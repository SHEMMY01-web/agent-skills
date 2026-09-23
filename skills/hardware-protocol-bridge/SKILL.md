---
name: hardware-protocol-bridge
description: >-
  Hardware IoT protocol bridging, binary UDP/TCP packet parsing, datagram socket lifecycle,
  CRC checksum validation, and device-to-cloud relay pipelines in Node.js. Use when
  interfacing with physical biometric terminals, attendance hardware, serial/socket
  devices, or embedded network controllers.
---

# Hardware Protocol Bridge & IoT Datagram Engineering

A specialized guide for engineering resilient UDP/TCP socket bridges, binary packet deserializers, CRC checksum validators, and real-time cloud relays in Node.js for physical hardware devices (biometric terminals, access controllers, IoT sensors).

---

## 1. When to Use
- Interfacing Node.js backends with physical hardware terminals via UDP or TCP sockets.
- Implementing binary communication protocols, command-response handshakes, and packet framing.
- Handling little-endian and big-endian binary buffers, byte alignment, and fixed-width headers.
- Calculating or verifying CRC16, CRC32, or checksum byte boundaries.
- Relaying binary event streams (e.g. attendance punches, card swipes) into modern cloud databases or HTTP REST APIs.
- Managing robust socket lifecycles (graceful binding, port reuse, reconnect loops on network disruption).

---

## 2. Core Guidelines & Best Practices

### 1. Robust Datagram Socket Lifecycle & Port Binding
- **Address In Use (`EADDRINUSE`):** Hardware bridges often crash or fail to restart if previous socket handles linger in `TIME_WAIT`. Always clean up listeners on process termination and handle binding errors:
  ```javascript
  const dgram = require('dgram');

  function createHardwareSocket(port, onMessage) {
    const socket = dgram.createSocket({ type: 'udp4', reuseAddr: true });

    socket.on('error', (err) => {
      console.error('[Socket] UDP Socket error:', err.message);
      if (err.code === 'EADDRINUSE') {
        setTimeout(() => {
          socket.close();
          createHardwareSocket(port, onMessage);
        }, 5000);
      }
    });

    socket.on('message', onMessage);
    socket.bind(port, () => {
      console.log(`[Socket] Hardware bridge listening on UDP port ${port}`);
    });

    return socket;
  }
  ```

### 2. Binary Buffer Deserialization & Endianness
- Never parse binary device streams as UTF-8 strings.
- Read binary fields using explicit endianness methods (`readUInt16LE`, `readUInt32LE` vs `BE`):
  ```javascript
  function parseDevicePacket(buffer) {
    if (buffer.length < 8) {
      throw new Error(`Packet fragment too short: ${buffer.length} bytes`);
    }

    // Example fixed-width packet layout:
    // [0..1]: Magic Header (0xAA55)
    // [2..3]: Command Code (UInt16LE)
    // [4..7]: Device ID (UInt32LE)
    const magic = buffer.readUInt16BE(0);
    if (magic !== 0xAA55) {
      throw new Error(`Invalid packet magic: 0x${magic.toString(16)}`);
    }

    const command = buffer.readUInt16LE(2);
    const deviceId = buffer.readUInt32LE(4);
    const payload = buffer.subarray(8, buffer.length - 2);
    const receivedChecksum = buffer.readUInt16LE(buffer.length - 2);

    return { command, deviceId, payload, receivedChecksum };
  }
  ```

### 3. Checksum & Integrity Validation
- Devices frequently transmit corrupted packets over noisy local area networks.
- Always verify payload integrity before processing business logic:
  ```javascript
  function calculateChecksum(buffer, start = 0, end = buffer.length - 2) {
    let sum = 0;
    for (let i = start; i < end; i++) {
      sum = (sum + buffer[i]) & 0xFFFF;
    }
    return sum;
  }

  function isValidPacket(buffer) {
    const expected = calculateChecksum(buffer);
    const actual = buffer.readUInt16LE(buffer.length - 2);
    return expected === actual;
  }
  ```

### 4. Device-to-Cloud Relay & Offline Queuing
- Hardware devices cannot wait for slow cloud REST endpoints (e.g. Supabase, AWS, Render) without timing out their UDP transmission windows.
- Ingest datagrams immediately, acknowledge the hardware terminal, and push records into an in-memory or Redis queue for asynchronous ingestion:
  ```javascript
  const queue = [];

  socket.on('message', (msg, rinfo) => {
    try {
      const packet = parseDevicePacket(msg);
      // Immediate ACK back to terminal to prevent retransmission storms
      sendAck(socket, rinfo, packet.command);
      // Enqueue for cloud worker
      queue.push({ packet, receivedAt: new Date().toISOString() });
    } catch (err) {
      console.warn(`[Socket] Dropped malformed packet from ${rinfo.address}:${rinfo.port}`);
    }
  });
  ```

---

## 3. Recommended Workflow & Procedures

1. **Protocol Specification Inspection:** Identify header bytes, magic numbers, opcode enumeration, body payload structure, and checksum algorithms.
2. **Buffer Stream Isolation:** Create mock packet buffers (`Buffer.from([...])`) to unit-test packet parsers and packet encoders in isolation.
3. **Socket Orchestration:** Initialize UDP/TCP listener with `reuseAddr: true` and bind graceful termination hooks (`SIGINT`, `SIGTERM`).
4. **Cloud Forwarder:** Connect the queue processor to your cloud database with exponential retry backoff and duplicate punch deduplication.

---

## 4. Verification & Validation
- **Packet Round-Trip Test:** Construct a valid binary packet, pass to `parseDevicePacket()`, and assert all extracted fields match expected device metadata.
- **Corrupted Frame Rejection:** Mutate a single payload byte and assert `isValidPacket()` returns `false` and discards the packet cleanly.
- **Load / Retransmission Stress Test:** Send 100 concurrent UDP packets to the bridge; assert zero unhandled exceptions and 100% queue delivery.
