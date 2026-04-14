# Implementation Plan: Sweet API Framework

## Overview

This implementation plan breaks down the Sweet API Framework into discrete, actionable coding tasks. The framework is a high-performance API server written in Mojo targeting sub-millisecond latency and 1M+ RPS throughput. Implementation follows a bottom-up approach, building foundational components first, then composing them into higher-level features.

The framework leverages:
- MLIR AOT compilation for zero-cost abstractions
- Thread-per-core architecture for lock-free scalability
- io_uring/epoll for async I/O
- SIMD acceleration for parsing and serialization
- Railway Oriented Programming for type-safe error handling
- Memory arenas for O(1) request-scoped allocation

## Tasks

- [ ] 1. Set up project structure and core types
  - Create directory structure: src/, tests/, examples/
  - Define core Result[T, E] type with Ok/Err constructors
  - Define Error type with ErrorKind enum (NotFound, BadRequest, Unauthorized, InternalError)
  - Implement Result monad operations: map, and_then, unwrap, unwrap_or
  - Define HttpMethod enum (GET, POST, PUT, DELETE, PATCH)
  - Define HttpRequest and HttpResponse structs
  - Set up basic project configuration (pixi.toml or equivalent)
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 1.5_

- [ ]* 1.1 Write property tests for Result monad
  - **Property 21: Result Type Exclusivity** - Result is either Ok or Err, never both
  - **Property 22: Result Monad Laws** - map identity, and_then left/right identity
  - **Validates: Requirements 6.1, 6.2, 6.3, 6.4, 6.5**

- [ ] 2. Implement memory arena allocator
  - [ ] 2.1 Create Arena struct with buffer, capacity, offset fields
    - Implement __init__ to allocate buffer with specified capacity
    - Implement allocate(size) method with bounds checking
    - Implement reset() method for O(1) deallocation
    - Implement __del__ to free buffer
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

  - [ ]* 2.2 Write property tests for memory arena
    - **Property 1: Memory Arena Bounds Safety** - offset never exceeds capacity
    - **Property 2: Memory Arena Reset** - reset() sets offset to zero in O(1)
    - **Validates: Requirements 7.1, 7.3, 7.4, 7.5, 19.7, 20.9**

- [ ] 3. Implement SIMD HTTP parser
  - [ ] 3.1 Create SimdHttpParser struct with buffer reference
    - Implement find_crlf_simd() using SIMD to detect \r\n sequences
    - Implement find_char_simd() for finding specific characters (colon, space)
    - Use SIMD width of 16 bytes (128-bit) or 64 bytes (AVX-512) based on CPU
    - _Requirements: 1.3, 18.5_

  - [ ] 3.2 Implement parse_request_line() method
    - Parse HTTP method using SIMD comparison
    - Extract path as zero-copy StringRef
    - Parse HTTP version (1.1)
    - Return Result[(HttpMethod, StringRef, (Int, Int)), ParseError]
    - _Requirements: 1.1, 1.5_

  - [ ] 3.3 Implement parse_headers() method
    - Use find_crlf_simd() to locate header boundaries
    - Use find_char_simd() to locate colon separators
    - Create zero-copy StringRef for header names and values
    - Validate all headers are valid UTF-8
    - Return Result[Dict[StringRef, StringRef], ParseError]
    - _Requirements: 1.1, 1.2, 1.6_

  - [ ] 3.4 Implement parse() main method
    - Parse request line, headers, and body
    - Extract query parameters from path
    - Return Result[HttpRequest, ParseError]
    - Handle malformed requests with descriptive errors
    - _Requirements: 1.1, 1.4, 1.7_

  - [ ]* 3.5 Write property tests for HTTP parser
    - **Property 3: HTTP Parsing Validity** - valid HTTP/1.1 requests parse successfully
    - **Property 4: HTTP Parsing Zero-Copy** - all StringRef point to valid buffer regions
    - **Property 5: HTTP Parsing SIMD Acceleration** - SIMD used for delimiter detection
    - **Property 6: HTTP Parsing Error Handling** - malformed requests return ParseError
    - **Validates: Requirements 1.1, 1.2, 1.3, 1.4, 1.6, 18.5, 20.1**

- [ ] 4. Implement radix trie router
  - [ ] 4.1 Create RadixNode struct
    - Define fields: prefix, children, handler, param_name, is_wildcard
    - Implement node creation and insertion logic
    - _Requirements: 2.1, 2.4, 2.5, 2.6_

  - [ ] 4.2 Create RadixRouter struct
    - Implement add_route() to insert routes into trie
    - Implement compile_routes() for AOT compilation
    - Support static routes (/users, /posts)
    - Support parameterized routes (/users/:id)
    - Support wildcard routes (/static/*)
    - _Requirements: 2.1, 2.4, 2.5, 2.6_

  - [ ] 4.3 Implement match_route() method
    - Recursive radix trie traversal
    - Extract path parameters into RouteParams
    - Return Result[RouteMatch, RouteError]
    - Achieve O(path_length) time complexity
    - _Requirements: 2.2, 2.3, 2.7, 2.8_

  - [ ]* 4.4 Write property tests for router
    - **Property 7: Route Compilation** - valid routes compile without errors
    - **Property 8: Route Matching Correctness** - matched routes return correct handler and params
    - **Property 9: Route Not Found Handling** - unmatched paths return RouteError
    - **Property 10: Route Matching Performance** - O(path_length) complexity
    - **Validates: Requirements 2.1, 2.2, 2.3, 2.7, 2.8, 18.6, 20.2**

- [ ] 5. Implement validation system
  - [ ] 5.1 Create Validator trait and Schema struct
    - Define Validator[T] trait with validate() method
    - Create Schema[T] struct with list of validators
    - Implement StringValidator with min_length, max_length, pattern
    - Implement IntValidator with min_value, max_value
    - _Requirements: 3.1, 3.5, 3.6_

  - [ ] 5.2 Implement compile-time schema generation
    - Create macro for generating validation code at compile time
    - Support nested object validation
    - Support array validation
    - Generate descriptive ValidationError with field-level details
    - _Requirements: 3.1, 3.2, 3.3, 3.7, 3.8, 3.9_

  - [ ]* 5.3 Write property tests for validation
    - **Property 11: Validation Schema Compilation** - schemas compile at build time
    - **Property 12: Validation Success** - conforming data validates successfully
    - **Property 13: Validation Failure** - non-conforming data returns ValidationError
    - **Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.9, 20.3**

- [ ] 6. Implement SIMD JSON serializer
  - [ ] 6.1 Create JsonSerializer struct
    - Implement serialize() method for Dict[String, Any]
    - Implement deserialize() method for parsing JSON
    - Use SIMD for delimiter detection ({ } [ ] " : ,)
    - Use SIMD for string escaping during serialization
    - _Requirements: 4.1, 4.2, 4.4, 4.5_

  - [ ] 6.2 Implement SIMD string escaping
    - Create write_escaped_string_simd() function
    - Use SIMD to detect characters needing escaping (" \ / \b \f \n \r \t)
    - Fast path for chunks without special characters
    - Scalar fallback for chunks with special characters
    - _Requirements: 4.3, 4.5, 19.8_

  - [ ]* 6.3 Write property tests for JSON serializer
    - **Property 14: JSON Serialization Round-Trip** - deserialize(serialize(obj)) equals obj
    - **Property 15: JSON Serialization Validity** - output is valid JSON with escaped characters
    - **Property 16: JSON SIMD Acceleration** - SIMD used for delimiters and escaping
    - **Validates: Requirements 4.1, 4.3, 4.4, 4.5, 4.6, 18.7, 19.8**

- [ ] 7. Implement middleware system
  - [ ] 7.1 Create Middleware trait
    - Define on_request, pre_handler, on_response, on_error hooks
    - Each hook returns Result type for Railway Oriented Programming
    - _Requirements: 5.2, 5.3, 5.4, 5.5_

  - [ ] 7.2 Create MiddlewareChain struct
    - Implement execute() method with ROP error propagation
    - Execute on_request hooks in registration order
    - Execute pre_handler hooks in registration order
    - Execute on_response hooks in reverse order
    - Short-circuit on error and invoke on_error hooks
    - Support request context state sharing
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.8_

  - [ ]* 7.3 Write property tests for middleware
    - **Property 17: Middleware Execution Order** - registration order for request, reverse for response
    - **Property 18: Middleware Lifecycle Hooks** - correct hook sequence
    - **Property 19: Middleware Error Handling** - on_error hooks invoked on errors
    - **Property 20: Middleware Short-Circuit** - error stops chain execution
    - **Validates: Requirements 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 20.4**

- [ ] 8. Checkpoint - Core components complete
  - Ensure all tests pass for Result, Arena, Parser, Router, Validator, JSON, Middleware
  - Verify zero-copy semantics and SIMD optimizations
  - Ask the user if questions arise

- [ ] 9. Implement io_uring reactor (Linux)
  - [ ] 9.1 Create IoUring wrapper struct
    - Wrap io_uring system calls (io_uring_setup, io_uring_enter)
    - Implement submit() to submit operations
    - Implement wait_cqe_timeout() to wait for completions
    - Implement peek_cqe() and cqe_seen() for completion handling
    - _Requirements: 8.1_

  - [ ] 9.2 Create IoUringReactor struct
    - Implement run() event loop
    - Implement register_socket() and unregister_socket()
    - Implement submit_read() and submit_write() for async I/O
    - Configure sockets with TCP_NODELAY, TCP_QUICKACK, SO_REUSEPORT
    - Batch I/O operations to reduce syscalls
    - _Requirements: 8.1, 8.3, 8.4, 8.5, 8.6, 8.7, 8.8, 8.9_

  - [ ]* 9.3 Write unit tests for io_uring reactor
    - Test socket registration and event dispatching
    - Test read/write operations
    - Test connection closure handling
    - Test batching behavior
    - _Requirements: 8.1, 8.3, 8.4, 8.5, 8.6_

- [ ] 10. Implement epoll reactor (fallback)
  - [ ] 10.1 Create EpollReactor struct
    - Wrap epoll system calls (epoll_create, epoll_ctl, epoll_wait)
    - Implement same Reactor trait interface as IoUringReactor
    - Support read/write event handling
    - Configure sockets with TCP_NODELAY, TCP_QUICKACK, SO_REUSEPORT
    - _Requirements: 8.2, 8.7, 8.8, 8.9_

  - [ ]* 10.2 Write unit tests for epoll reactor
    - Test socket registration and event dispatching
    - Test read/write operations
    - Test connection closure handling
    - _Requirements: 8.2, 8.3, 8.4, 8.5_

  - [ ] 10.3 Implement reactor selection logic
    - Detect io_uring availability at runtime (kernel 5.1+)
    - Fall back to epoll if io_uring unavailable
    - Create factory function to return appropriate reactor
    - _Requirements: 8.1, 8.2, 25.4, 25.5_

  - [ ]* 10.4 Write property tests for async I/O
    - **Property 25: Async I/O Reactor Selection** - io_uring used when available, epoll fallback
    - **Property 26: Async I/O Event Handling** - handlers invoked for socket events
    - **Property 27: Async I/O Batching** - operations submitted in batches
    - **Property 28: TCP Latency Optimization** - TCP_NODELAY and TCP_QUICKACK enabled
    - **Validates: Requirements 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 8.7, 8.8, 25.5**

- [ ] 11. Implement request processing pipeline
  - [ ] 11.1 Create RequestContext struct
    - Define fields: request, params, state, arena, start_time
    - Implement helper methods: get_header, set_state, get_state
    - _Requirements: 5.8_

  - [ ] 11.2 Implement process_request() function
    - Parse HTTP request using SimdHttpParser
    - Match route using RadixRouter
    - Create RequestContext with arena
    - Execute middleware chain with handler
    - Reset arena after processing (success or error)
    - Convert errors to HTTP responses
    - _Requirements: 1.1, 2.2, 5.1, 6.6, 6.7, 7.3, 7.5, 20.1, 20.2, 20.4, 20.9_

  - [ ]* 11.3 Write integration tests for request pipeline
    - Test full request-response cycle
    - Test error handling and recovery
    - Test arena reset on success and error
    - _Requirements: 1.1, 2.2, 5.1, 6.6, 7.3, 20.9_

- [ ] 12. Implement thread-per-core architecture
  - [ ] 12.1 Create Worker struct
    - Define per-core resources: reactor, arena, router, middleware
    - Implement worker_main() function to run event loop
    - Ensure complete isolation (no shared state between workers)
    - _Requirements: 9.1, 9.3, 9.6, 9.7_

  - [ ] 12.2 Implement server startup with SO_REUSEPORT
    - Create listening socket with SO_REUSEPORT enabled
    - Spawn worker threads (one per configured core)
    - Each worker accepts connections independently
    - Kernel distributes connections across workers
    - _Requirements: 8.9, 9.2_

  - [ ]* 12.3 Write property tests for thread-per-core
    - **Property 29: Thread-Per-Core Isolation** - no shared state between cores
    - **Property 30: Thread-Per-Core Load Distribution** - SO_REUSEPORT distributes load
    - **Property 31: Thread-Per-Core Linear Scaling** - throughput scales with cores
    - **Validates: Requirements 8.9, 9.2, 9.3, 9.4, 9.5, 9.6, 9.7, 18.3**

- [ ] 13. Implement structured logger
  - [ ] 13.1 Create Logger struct
    - Define LogLevel enum (TRACE, DEBUG, INFO, WARN, ERROR, FATAL)
    - Define LogRecord struct with timestamp, level, message, fields, source_location
    - Implement log() method with level filtering
    - Use memory arena for zero-allocation logging
    - _Requirements: 13.1, 13.2, 13.3, 13.4, 13.5, 13.6, 13.7_

  - [ ] 13.2 Create LogSink trait and implementations
    - Define LogSink trait with write() and flush() methods
    - Implement StdoutSink with buffered writes
    - Implement FileSink for file logging
    - Support multiple sinks per logger
    - _Requirements: 13.8, 13.9_

  - [ ]* 13.3 Write property tests for logger
    - **Property 46: Structured Logging Fields** - all required fields included
    - **Property 47: Structured Logging Level Filtering** - messages below threshold skipped
    - **Property 48: Structured Logging Zero-Allocation** - arena used for logging
    - **Validates: Requirements 13.1, 13.2, 13.3, 13.4, 13.6, 13.7, 13.8**

- [ ] 14. Checkpoint - Server infrastructure complete
  - Ensure reactor, thread-per-core, and logging work correctly
  - Test multi-core request handling
  - Verify linear scaling with core count
  - Ask the user if questions arise

- [ ] 15. Implement background task system
  - [ ] 15.1 Create Task struct and TaskQueue trait
    - Define Task with id, payload, retry_count, max_retries, created_at
    - Define TaskQueue trait with enqueue, dequeue, ack, nack methods
    - _Requirements: 10.1_

  - [ ] 15.2 Implement LocalTaskQueue (single-core)
    - Use local deque for task storage
    - Implement enqueue and dequeue operations
    - _Requirements: 10.2_

  - [ ] 15.3 Implement RedisTaskQueue (multi-core)
    - Create SPSCQueue for local buffer
    - Implement Redis client wrapper
    - Enqueue: try local buffer first, fallback to Redis
    - Dequeue: try local buffer first, fallback to Redis
    - _Requirements: 10.2, 10.3_

  - [ ] 15.4 Implement TaskExecutor
    - Register task handlers by task type
    - Implement run() loop to dequeue and execute tasks
    - Implement retry logic with exponential backoff
    - Move failed tasks to dead letter queue after max_retries
    - _Requirements: 10.4, 10.5, 10.6, 10.7, 10.8_

  - [ ]* 15.5 Write property tests for background tasks
    - **Property 32: Background Task Enqueue Non-Blocking** - enqueue doesn't block
    - **Property 33: Background Task Storage Strategy** - local deque for single-core, SPSC+Redis for multi-core
    - **Property 34: Background Task Execution** - handlers invoked for dequeued tasks
    - **Property 35: Background Task Retry Logic** - exponential backoff and dead letter queue
    - **Property 36: Background Task At-Least-Once Delivery** - tasks executed at least once
    - **Validates: Requirements 10.1, 10.2, 10.3, 10.4, 10.5, 10.6, 10.7, 10.8, 20.7**

- [ ] 16. Implement cron scheduler
  - [ ] 16.1 Create CronExpression struct
    - Parse cron expression fields (minute, hour, day, month, weekday)
    - Implement next_execution() to calculate next run time
    - Support standard cron syntax (* for any, specific values, ranges)
    - _Requirements: 11.1, 11.2, 11.8_

  - [ ] 16.2 Create CronJob and CronScheduler structs
    - Define CronJob with id, expression, handler, next_run
    - Implement MinHeap for efficient job scheduling
    - Implement add_job() to register jobs
    - _Requirements: 11.1, 11.2, 11.5_

  - [ ] 16.3 Implement scheduler run() loop
    - Pop jobs from heap when next_run <= now
    - Execute job handler
    - Calculate next execution time and re-insert into heap
    - Handle job failures gracefully (log and continue)
    - Sleep until next job or timeout
    - _Requirements: 11.3, 11.4, 11.5, 11.6_

  - [ ] 16.4 Implement JobStore trait and MemoryJobStore
    - Define JobStore trait with save_job, load_jobs, update_next_run
    - Implement MemoryJobStore with in-memory storage
    - Persist job state on updates
    - _Requirements: 11.7_

  - [ ]* 16.5 Write property tests for cron scheduler
    - **Property 37: Cron Expression Parsing** - expressions parsed and validated
    - **Property 38: Cron Job Execution Timing** - jobs execute at scheduled times
    - **Property 39: Cron Job Rescheduling** - jobs rescheduled after completion
    - **Property 40: Cron Scheduler Min-Heap** - O(log n) next job lookup
    - **Property 41: Cron Job Error Handling** - failures logged, schedule continues
    - **Validates: Requirements 11.1, 11.2, 11.3, 11.4, 11.5, 11.6, 20.8**

- [ ] 17. Implement HTTP client
  - [ ] 17.1 Create ConnectionPool struct
    - Maintain connections per host
    - Implement acquire() to get connection from pool
    - Implement release() to return connection to pool
    - Close idle connections after timeout
    - Enforce max_connections_per_host limit
    - _Requirements: 12.1, 12.2, 12.3, 12.4_

  - [ ] 17.2 Create HttpClient struct
    - Implement request() method for HTTP requests
    - Implement convenience methods: get, post, put, delete
    - Integrate with reactor for async I/O
    - Handle timeouts
    - _Requirements: 12.1, 12.5, 12.6_

  - [ ] 17.3 Implement DnsResolver
    - Use thread pool for async DNS resolution (spawn_blocking)
    - Cache DNS results to avoid repeated lookups
    - _Requirements: 12.7, 12.8_

  - [ ]* 17.4 Write property tests for HTTP client
    - **Property 42: HTTP Client Connection Reuse** - connections reused from pool
    - **Property 43: HTTP Client Connection Limits** - max_connections_per_host enforced
    - **Property 44: HTTP Client Timeout Handling** - timeouts return error
    - **Property 45: HTTP Client DNS Caching** - DNS results cached
    - **Validates: Requirements 12.1, 12.2, 12.4, 12.6, 12.7, 12.8**

- [ ] 18. Implement WebSocket support
  - [ ] 18.1 Create WebSocket frame parser
    - Define WebSocketOpcode enum (CONTINUATION, TEXT, BINARY, CLOSE, PING, PONG)
    - Define WebSocketFrame struct with FIN, RSV, opcode, masked, payload_length, masking_key, payload
    - Implement parse_frame() to extract frame fields from buffer
    - Validate frame structure per RFC 6455
    - _Requirements: 26.1, 26.2_

  - [ ] 18.2 Implement SIMD payload unmasking
    - Create unmask_payload_simd() using AVX-512 instructions
    - Broadcast masking key to SIMD register
    - Process 64 bytes at a time with SIMD XOR
    - Scalar fallback for remaining bytes
    - Zero-copy in-place unmasking
    - _Requirements: 26.3, 18.5_

  - [ ] 18.3 Implement WebSocket handshake
    - Create perform_websocket_handshake() function
    - Validate required headers (Upgrade, Connection, Sec-WebSocket-Key, Sec-WebSocket-Version)
    - Calculate Sec-WebSocket-Accept using SHA-1
    - Return 101 Switching Protocols response
    - Validate Origin header for CSWSH protection
    - _Requirements: 26.1, 27.10_

  - [ ] 18.4 Create WebSocketConnection and WebSocketManager
    - Define WebSocketConnection with fd, state, arena, subscriptions, ping/pong timestamps
    - Define WebSocketState enum (CONNECTING, OPEN, CLOSING, CLOSED)
    - Implement WebSocketManager with connections map, topic_registry, broadcast_buffer
    - Implement upgrade_connection() to perform handshake
    - _Requirements: 26.4_

  - [ ] 18.5 Implement WebSocket frame processing
    - Create process_frame() to handle incoming frames
    - Handle TEXT and BINARY data frames (invoke handler)
    - Handle CLOSE frames (close connection gracefully)
    - Handle PING frames (respond with PONG)
    - Handle PONG frames (update last_pong timestamp)
    - Enforce frame size limits (max_frame_size)
    - Implement rate limiting (messages/sec and bytes/sec)
    - _Requirements: 26.5, 26.8, 26.9_

  - [ ] 18.6 Implement WebSocket sending
    - Create send_frame() to serialize and send frames
    - Implement send_text() and send_binary() convenience methods
    - Implement ping() to send PING frames
    - Implement close_connection() to send CLOSE frame
    - Server frames are not masked per RFC 6455
    - _Requirements: 26.5_

  - [ ] 18.7 Implement topic-based pub/sub
    - Create TopicRegistry with topics map (topic -> [fd1, fd2, ...])
    - Implement subscribe() to add connection to topic
    - Implement unsubscribe() to remove connection from topic
    - Implement get_subscribers() to retrieve subscriber list
    - Implement remove_connection() to clean up on disconnect
    - _Requirements: 26.7_

  - [ ] 18.8 Implement lock-free broadcasting
    - Create SPSCRingBuffer for broadcast messages
    - Implement broadcast() to send message to all topic subscribers
    - Use lock-free ring buffer for per-core isolation
    - Handle failed sends gracefully (log and continue)
    - _Requirements: 26.6, 9.3_

  - [ ] 18.9 Implement ping/pong keepalive
    - Send PING frames at ping_interval
    - Track last_ping and last_pong timestamps
    - Close connections that don't respond within pong_timeout
    - Optional paranoia mode for aggressive takedowns
    - _Requirements: 26.11_

  - [ ] 18.10 Implement Redis Pub/Sub adapter
    - Create RedisPubSubAdapter for cross-instance broadcasting
    - Implement publish() to send message to Redis channel
    - Implement subscribe() to listen to Redis channel
    - Forward Redis messages to local WebSocket connections
    - _Requirements: 26.12_

  - [ ]* 18.11 Write property tests for WebSocket
    - **Property 61: WebSocket Handshake Validation** - all required headers validated
    - **Property 62: WebSocket Frame Parsing** - frame fields extracted correctly
    - **Property 63: WebSocket SIMD Unmasking** - AVX-512 used for unmasking
    - **Property 64: WebSocket Connection Lifecycle** - state transitions correct
    - **Property 65: WebSocket Control Frame Handling** - PING/PONG/CLOSE handled per RFC
    - **Property 66: WebSocket Broadcasting Lock-Free** - lock-free SPSC buffers used
    - **Property 67: WebSocket Topic Subscription** - subscriptions tracked correctly
    - **Property 68: WebSocket Frame Size Limits** - oversized frames rejected
    - **Property 69: WebSocket Rate Limiting** - rate limits enforced
    - **Property 70: WebSocket CSWSH Protection** - Origin header validated
    - **Property 71: WebSocket Ping/Pong Keepalive** - keepalive enforced
    - **Property 72: WebSocket Redis Pub/Sub** - cross-instance broadcasting works
    - **Validates: Requirements 26.1-26.12, 27.10, 18.5, 9.3, 19.1**

- [ ] 19. Checkpoint - WebSocket implementation complete
  - Test WebSocket handshake, frame parsing, broadcasting
  - Verify SIMD unmasking performance
  - Test topic subscriptions and Redis adapter
  - Ask the user if questions arise

- [ ] 20. Implement Server-Sent Events (SSE)
  - [ ] 20.1 Create SSE data structures
    - Define SSEConnection with fd, state, last_event_id, retry_interval, subscriptions, last_keepalive
    - Define SSEState enum (OPEN, CLOSED)
    - Define SSEEvent with id, event, data, retry fields
    - Define SSEConfig with keepalive_interval, max_subscriptions_per_connection, retry_interval
    - _Requirements: 28.1_

  - [ ] 20.2 Implement SSE connection upgrade
    - Create upgrade_connection() to send SSE response headers
    - Set Content-Type: text/event-stream
    - Set Cache-Control: no-cache
    - Set Connection: keep-alive
    - Set Transfer-Encoding: chunked
    - Set X-Accel-Buffering: no (disable nginx buffering)
    - _Requirements: 28.1_

  - [ ] 20.3 Implement SSE event formatting
    - Create format_sse_event() for zero-copy event formatting
    - Write id, event, data, retry fields directly to buffer
    - Support multi-line data (prefix each line with "data: ")
    - Terminate with double newline (\n\n)
    - _Requirements: 28.2, 28.3_

  - [ ] 20.4 Create SSEManager struct
    - Implement send_event() to send formatted event
    - Implement send_comment() for keep-alive comments
    - Implement broadcast() to send event to topic subscribers
    - Implement subscribe() and unsubscribe() for topic management
    - Implement close_connection() to gracefully close SSE connection
    - Share TopicRegistry with WebSocketManager
    - _Requirements: 28.5_

  - [ ] 20.5 Implement timing wheel for keep-alive
    - Create TimingWheel struct with circular buffer of FD lists
    - Implement schedule() to add FD to future slot
    - Implement tick() to advance wheel and return FDs to process
    - Use hashed timing wheel for O(1) scheduling
    - _Requirements: 28.4_

  - [ ] 20.6 Implement SSE keep-alive processing
    - Create process_keepalive() to send keep-alive comments
    - Tick timing wheel to get FDs needing keep-alive
    - Send keep-alive comment to each FD
    - Reschedule FD for next keep-alive
    - Close connections that fail keep-alive
    - _Requirements: 28.4_

  - [ ] 20.7 Implement SSE streaming with generator pattern
    - Define SSEStream trait with next() and close() methods
    - Create stream_sse_events() to consume stream and send events
    - Integrate with io_uring reactor for async writes
    - Handle Last-Event-ID for reconnection
    - _Requirements: 28.6, 28.7_

  - [ ]* 20.8 Write property tests for SSE
    - **Property 73: SSE Connection Upgrade** - correct headers sent
    - **Property 74: SSE Event Formatting** - zero-copy formatting with correct fields
    - **Property 75: SSE Multi-Line Data** - multi-line data formatted correctly
    - **Property 76: SSE Keep-Alive Comments** - keep-alive sent at intervals
    - **Property 77: SSE Topic Broadcasting** - events broadcast to subscribers
    - **Property 78: SSE Last-Event-ID** - reconnection resumes from event ID
    - **Property 79: SSE Generator Pattern** - generator/stream pattern works
    - **Property 80: SSE Chunked Encoding** - chunked encoding used
    - **Validates: Requirements 28.1-28.8**

- [ ] 21. Implement plugin system
  - [ ] 21.1 Create Plugin trait and PluginRegistry
    - Define Plugin trait with name, register, on_startup, on_shutdown methods
    - Create PluginRegistry to manage plugins
    - Implement register() to add plugin
    - Implement startup_all() and shutdown_all() for lifecycle management
    - _Requirements: 14.1, 14.2, 14.3_

  - [ ] 21.2 Implement built-in plugins
    - Create CorsPlugin with allowed_origins, allowed_methods configuration
    - Create JwtAuthPlugin with secret_key and token validation
    - Create RateLimitPlugin with Redis-backed rate limiting
    - Each plugin registers middleware during registration
    - _Requirements: 14.4, 14.5, 14.7_

  - [ ]* 21.3 Write property tests for plugins
    - **Property 49: Plugin Lifecycle Management** - register, on_startup, on_shutdown invoked
    - **Property 50: Plugin Registration Capabilities** - plugins can register routes, middleware, hooks
    - **Validates: Requirements 14.1, 14.2, 14.3, 14.4, 14.5, 14.6**

- [ ] 22. Implement dependency injection
  - [ ] 22.1 Create DIContainer struct
    - Implement register_singleton() for singleton dependencies
    - Implement register_factory() for transient dependencies
    - Implement resolve() to retrieve dependencies
    - Support compile-time resolution where possible
    - _Requirements: 15.1, 15.2, 15.3_

  - [ ] 22.2 Implement functional DI with Dependencies struct
    - Create Dependencies struct to hold common dependencies (db, cache, logger)
    - Implement get() method for type-safe dependency retrieval
    - Pass Dependencies to handlers as parameter
    - _Requirements: 15.4_

  - [ ] 22.3 Implement decorator-based DI with @inject
    - Create @inject decorator for handler functions
    - Automatically resolve dependencies at compile time
    - Inject dependencies as handler parameters
    - _Requirements: 15.5_

  - [ ]* 22.4 Write property tests for dependency injection
    - **Property 51: Dependency Injection Singleton** - singletons created once
    - **Property 52: Dependency Injection Factory** - factories create new instances
    - **Property 53: Dependency Injection Compile-Time Resolution** - compile-time resolution where possible
    - **Validates: Requirements 15.1, 15.2, 15.3**

- [ ] 23. Implement OpenAPI documentation
  - [ ] 23.1 Create OpenAPI data structures
    - Define OpenApiSpec, OpenApiInfo, PathItem, Operation, Parameter, RequestBody, Response structs
    - Define Components struct for reusable schemas
    - _Requirements: 16.1_

  - [ ] 23.2 Create OpenApiGenerator struct
    - Implement generate() to create OpenAPI spec from routes
    - Extract route metadata (path, method, parameters)
    - Generate request body schemas from validation schemas
    - Generate response schemas from handler return types
    - _Requirements: 16.2, 16.3, 16.4, 16.5_

  - [ ] 23.3 Implement OpenAPI JSON serialization
    - Implement to_json() to serialize OpenApiSpec to JSON
    - Ensure output is valid OpenAPI 3.0
    - Serve spec at /openapi.json endpoint
    - _Requirements: 16.6, 16.7_

  - [ ]* 23.4 Write property tests for OpenAPI
    - **Property 54: OpenAPI Metadata Extraction** - route metadata extracted correctly
    - **Property 55: OpenAPI Specification Validity** - valid OpenAPI 3.0 JSON generated
    - **Validates: Requirements 16.1, 16.2, 16.3, 16.4, 16.5, 16.6, 16.7**

- [ ] 24. Implement configuration management
  - [ ] 24.1 Create ServerConfig struct
    - Define fields: host, port, num_workers, reactor_config, enable_tls, tls_cert_path, tls_key_path
    - Implement validate() method to check configuration
    - Validate port range (1-65535)
    - Validate num_workers >= 1
    - Validate TLS configuration if enabled
    - _Requirements: 17.1, 17.2, 17.3, 17.4, 17.5, 17.6, 17.7_

  - [ ] 24.2 Implement configuration from environment variables
    - Support SWEET_HOST, SWEET_PORT, SWEET_NUM_WORKERS env vars
    - Support SWEET_TLS_CERT, SWEET_TLS_KEY for TLS configuration
    - Provide sensible defaults
    - _Requirements: 23.7_

  - [ ]* 24.3 Write property tests for configuration
    - **Property 56: Configuration Validation** - invalid configs return errors
    - **Validates: Requirements 17.1, 17.2, 17.3, 17.4**

- [ ] 25. Implement security features
  - [ ] 25.1 Implement input size validation
    - Enforce max header size (8KB)
    - Enforce max body size (10MB, configurable)
    - Enforce max path length (2KB)
    - Enforce max query string length (4KB)
    - Enforce max header count (100)
    - Return HTTP 413 Payload Too Large for violations
    - _Requirements: 19.1, 19.2, 19.3, 19.4, 19.5_

  - [ ] 25.2 Implement UTF-8 validation
    - Validate all string inputs are valid UTF-8
    - Validate header names and values
    - Return HTTP 400 Bad Request for invalid UTF-8
    - _Requirements: 19.6_

  - [ ] 25.3 Implement bounds checking
    - Bounds-check all buffer accesses in parser
    - Bounds-check all arena allocations
    - Prevent buffer overflows
    - _Requirements: 19.7_

  - [ ]* 25.4 Write property tests for security
    - **Property 57: Input Size Limits** - size limits enforced
    - **Property 58: UTF-8 Validation** - invalid UTF-8 rejected
    - **Validates: Requirements 19.1, 19.2, 19.3, 19.4, 19.5, 19.6**

- [ ] 26. Implement error handling and recovery
  - [ ] 26.1 Implement error-to-HTTP mapping
    - Map ErrorKind.NotFound to HTTP 404
    - Map ErrorKind.BadRequest to HTTP 400
    - Map ErrorKind.Unauthorized to HTTP 401
    - Map ErrorKind.InternalError to HTTP 500
    - Include error message in response body (JSON format)
    - _Requirements: 6.7, 6.8, 6.9, 6.10, 6.11_

  - [ ] 26.2 Implement error recovery scenarios
    - HTTP parse error: return 400, continue processing
    - Route not found: return 404, continue processing
    - Validation failure: return 422 with field errors
    - Handler error: return 500, log error, reset arena
    - I/O error: close connection, clean up resources
    - Arena exhaustion: return 500, reset arena
    - Background task failure: retry with backoff or dead-letter
    - Cron job failure: log error, continue schedule
    - _Requirements: 20.1, 20.2, 20.3, 20.4, 20.5, 20.6, 20.7, 20.8, 20.9_

  - [ ]* 26.3 Write property tests for error handling
    - **Property 23: Error Propagation** - errors propagate through ROP chain
    - **Property 24: Error to HTTP Response Mapping** - ErrorKind mapped to HTTP status
    - **Validates: Requirements 6.6, 6.7, 6.8, 6.9, 6.10, 6.11**

- [ ] 27. Implement monitoring and observability
  - [ ] 27.1 Create metrics collection
    - Implement request latency histograms (p50, p95, p99, p999)
    - Track requests per second per core
    - Track memory arena utilization
    - Track connection pool statistics
    - Track background task queue depth
    - Track error rates by error type
    - _Requirements: 24.1, 24.2, 24.3, 24.4, 24.5, 24.6_

  - [ ] 27.2 Implement Prometheus exporter
    - Create /metrics endpoint
    - Export metrics in Prometheus format
    - Include all collected metrics
    - _Requirements: 24.7_

  - [ ] 27.3 Implement distributed tracing
    - Generate trace IDs for requests
    - Propagate trace IDs through middleware
    - Include trace IDs in logs
    - Support trace context propagation
    - _Requirements: 24.8_

- [ ] 28. Implement deployment support
  - [ ] 28.1 Implement graceful shutdown
    - Handle SIGTERM and SIGINT signals
    - Stop accepting new connections
    - Drain in-flight requests
    - Close all connections gracefully
    - Shutdown background tasks and cron jobs
    - _Requirements: 23.6_

  - [ ] 28.2 Implement health check endpoints
    - Create /health endpoint for liveness checks
    - Create /ready endpoint for readiness checks
    - Return 200 OK when healthy/ready
    - Return 503 Service Unavailable when not ready
    - _Requirements: 23.5_

  - [ ] 28.3 Create Dockerfile for containerization
    - Use multi-stage build for minimal image size
    - Copy compiled binary (no runtime dependencies)
    - Set appropriate user and permissions
    - Expose port 8000
    - _Requirements: 23.1, 23.3_

  - [ ] 28.4 Create Kubernetes manifests
    - Create Deployment manifest with resource limits
    - Create Service manifest with load balancing
    - Create ConfigMap for configuration
    - Include health check probes
    - _Requirements: 23.4, 23.5_

- [ ] 29. Checkpoint - Production features complete
  - Test configuration, security, error handling, monitoring
  - Test graceful shutdown and health checks
  - Verify Docker and Kubernetes deployment
  - Ask the user if questions arise

- [ ] 30. Implement Application struct and server startup
  - [ ] 30.1 Create Application struct
    - Define fields: config, router, middleware, plugins, di_container, logger
    - Implement route() to register routes
    - Implement use_middleware() to register middleware
    - Implement register_plugin() to register plugins
    - _Requirements: 2.1, 5.1, 14.1_

  - [ ] 30.2 Implement server run() method
    - Validate configuration
    - Initialize plugins (on_startup)
    - Create listening socket with SO_REUSEPORT
    - Spawn worker threads (one per core)
    - Each worker runs reactor event loop
    - Handle graceful shutdown
    - Cleanup plugins (on_shutdown)
    - _Requirements: 9.1, 9.2, 14.2, 14.3, 17.1, 23.6_

  - [ ]* 30.3 Write integration tests for full server
    - Test full request-response cycle
    - Test multi-core load distribution
    - Test middleware execution
    - Test error handling
    - Test graceful shutdown
    - _Requirements: 9.2, 9.5, 18.3_

- [ ] 31. Create example applications
  - [ ] 31.1 Create hello world example
    - Simple GET endpoint returning "Hello, Sweet!"
    - Demonstrate basic server setup
    - _Requirements: 22.4_

  - [ ] 31.2 Create REST API example
    - CRUD operations for users resource
    - Demonstrate routing, validation, JSON serialization
    - Use middleware for logging and CORS
    - _Requirements: 22.4_

  - [ ] 31.3 Create WebSocket chat example
    - WebSocket endpoint for chat messages
    - Topic-based rooms
    - Demonstrate WebSocket broadcasting
    - _Requirements: 22.4_

  - [ ] 31.4 Create SSE streaming example
    - SSE endpoint for real-time updates
    - Demonstrate generator pattern
    - Show keep-alive handling
    - _Requirements: 22.4_

  - [ ] 31.5 Create background tasks example
    - Enqueue tasks from API endpoints
    - Process tasks asynchronously
    - Demonstrate retry logic
    - _Requirements: 22.4_

  - [ ] 31.6 Create cron jobs example
    - Schedule periodic tasks with cron expressions
    - Demonstrate job persistence
    - _Requirements: 22.4_

- [ ] 32. Performance optimization and benchmarking
  - [ ] 32.1 Implement performance benchmarks
    - Benchmark HTTP parsing (target: 10-20 microseconds)
    - Benchmark route matching (target: 5-10 microseconds)
    - Benchmark JSON serialization (target: 20-50 microseconds)
    - Benchmark full request-response cycle (target: <1ms p99)
    - Benchmark throughput (target: 60K-100K RPS per core)
    - _Requirements: 18.1, 18.2, 18.5, 18.6, 18.7_

  - [ ] 32.2 Profile and optimize hot paths
    - Profile with perf or similar tools
    - Optimize SIMD usage in parser and serializer
    - Optimize memory allocation patterns
    - Reduce syscall overhead
    - _Requirements: 18.1, 18.2_

  - [ ] 32.3 Verify linear scaling
    - Benchmark with 1, 2, 4, 8, 16 cores
    - Verify throughput scales linearly
    - Measure per-core resource usage
    - _Requirements: 18.3_

  - [ ]* 32.4 Write property tests for performance
    - **Property 59: Performance Latency Target** - p99 latency <1ms
    - **Property 60: Performance Throughput Target** - 60K-100K RPS per core
    - **Validates: Requirements 18.1, 18.2**

- [ ] 33. Documentation and developer experience
  - [ ] 33.1 Write API documentation
    - Document all public APIs with docstrings
    - Include parameter descriptions and return types
    - Document error conditions
    - _Requirements: 22.5_

  - [ ] 33.2 Write user guide
    - Getting started tutorial
    - Core concepts explanation
    - Common patterns and best practices
    - Deployment guide
    - _Requirements: 22.4, 22.5_

  - [ ] 33.3 Write migration guide
    - Comparison with FastAPI, Fastify, ElysiaJS
    - Migration examples from other frameworks
    - Performance comparison
    - _Requirements: 22.5_

  - [ ] 33.4 Improve error messages
    - Ensure compile-time errors are descriptive
    - Ensure runtime errors include context
    - Provide helpful suggestions for common mistakes
    - _Requirements: 22.1, 22.2, 22.3, 22.7_

- [ ] 34. Testing and quality assurance
  - [ ] 34.1 Achieve test coverage goals
    - Run coverage analysis
    - Add tests for uncovered code paths
    - Target: >90% line coverage, >85% branch coverage
    - _Requirements: 21.5, 21.6_

  - [ ] 34.2 Test all error paths
    - Test each error scenario from design document
    - Verify error recovery works correctly
    - Test edge cases and boundary conditions
    - _Requirements: 21.7_

  - [ ] 34.3 Run property-based tests
    - Execute all property tests with 1000+ cases each
    - Fix any failing properties
    - Document any limitations or assumptions
    - _Requirements: 21.2_

  - [ ] 34.4 Run integration tests
    - Test full request-response cycles
    - Test multi-core scenarios
    - Test background tasks and cron jobs
    - Test WebSocket and SSE functionality
    - _Requirements: 21.3_

- [ ] 35. Cross-platform support
  - [ ] 35.1 Test on Linux
    - Test with io_uring on kernel 5.1+
    - Test with epoll fallback on older kernels
    - Verify full feature support
    - _Requirements: 25.1, 25.4_

  - [ ] 35.2 Test on macOS
    - Test with epoll fallback (no io_uring)
    - Verify development workflow
    - Document any platform-specific limitations
    - _Requirements: 25.2_

  - [ ] 35.3 Verify CPU requirements
    - Test on x86_64 with AVX2 support
    - Document minimum CPU requirements
    - Provide fallback for systems without AVX2 (if feasible)
    - _Requirements: 25.3_

- [ ] 36. Final integration and polish
  - [ ] 36.1 End-to-end testing
    - Deploy example applications
    - Test with real-world traffic patterns
    - Verify performance targets met
    - Test under load (stress testing)
    - _Requirements: 18.1, 18.2, 18.3_

  - [ ] 36.2 Security audit
    - Review all input validation
    - Review error handling for information leaks
    - Test for common vulnerabilities (injection, overflow, etc.)
    - _Requirements: 19.1-19.10_

  - [ ] 36.3 Code review and cleanup
    - Review all code for clarity and maintainability
    - Remove dead code and TODOs
    - Ensure consistent style
    - Add missing comments
    - _Requirements: 22.5_

  - [ ] 36.4 Prepare for release
    - Write CHANGELOG documenting features
    - Write README with quick start guide
    - Set up CI/CD pipeline
    - Tag release version
    - _Requirements: 22.4, 22.5_

- [ ] 37. Final checkpoint - Framework complete
  - All components implemented and tested
  - Performance targets achieved
  - Documentation complete
  - Ready for production use
  - Ask the user if questions arise

## Notes

- Tasks marked with `*` are optional testing tasks and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation at key milestones
- Property tests validate universal correctness properties from the design document
- Unit tests validate specific examples and edge cases
- Integration tests validate component interactions and end-to-end workflows
- The implementation follows a bottom-up approach: core types → components → integration → features
- SIMD optimizations are critical for performance targets and should be verified with benchmarks
- Thread-per-core architecture requires careful attention to avoid shared state
- Railway Oriented Programming ensures type-safe error handling throughout
- Memory arenas provide O(1) request-scoped allocation and deallocation
