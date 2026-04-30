# TODO List

1. rename it to Sweet from Axiom      DONE
2.  add epoll as fallback(make it modular to use both tokio and seastar)- dont use complex FP patterns, use function composition.
3.  use mojo default async runtime for the very forst version, adding tokio/seastar can come later.
4. add future support for pattern matching when it comes to mojo
5. middlewares and plugins should be separate(research first), also search how deugging should be done for async task(make a clean hexgonal like interface if possible)
6. see the implementation of SeaStar/Glommio/tokio-uring in the plan and check if it works with proposed plan of Task_Queue implementation of single and multicore, RLIMIT_MEMLOCK ≥ 512 KiB (for io_uring), tokio vs Node.js event loop/uvloop
7. check if photon(logger) and http client is in plan or not
8. add plan for WebSockets & SSE, also check for UDP(research with gemini first)
9. add complete support for Auth and OAuth inpired from on in Agent_saul and use paseto tokens
10. what things so i need to keep i mind for proper use of SeaStar and efficiently squeesing the performance without crashes, any kind of thrashing(GC), memory burst, how threads model work if make more threads internally in the server
11. evaluate seastar and Glommio and others
12. analyse where are the edges cases of all these things lie and where they fail
13. check how big companies like Modal, Modular etc and small/mid comapnies need to scale AI offerings with mojo and how can this framework align with there goals
14. make a complete list if security concerns that that should be included in Design before implementation
15. carefully analyse platformatic's watt and new features in Linux Kernel for other optimisations
16. check if Returns package is properly adopted
17. SIMDJSON, apscheduler, seaStar, celery, faststream, tenacity, all major plugins of fastify, FastAPI and others needs to be ported or reused check
18. OpenAPI Docs should have a modern look along with the old one
19. FastAPI depends needs to be same here too
20. check what developer ergonomics from Echo, FastAPI, spring Boot, laravel, rails, ruby, effectTS, Nest, .NET
21. also think about this working in cross platform like windows, macOS
22. check for feasibility of this with implementation from popular frameworks
  - Enforce max header size (8KB)
  - Enforce max body size (10MB, configurable)
  - Enforce max path length (2KB)
  - Enforce max query string length (4KB)
  - Enforce max header count (100)
23. verify of all the metaprogramming features used
24. should i have a ctx object like in koa and go framwworks and have all the things available in it
25. from the orginal plan check whether all the hacks where inlcuded in the design or not
26. make a standard library inspired from go, python, rust, Effect.ts
27. One plugin could take down the entire app, while plugins can work, they require way more engineering effort to get the second sarchitecture right. They will cause endless support woes and costs and in the end not even cover all of the features that your customers want. so understand what makes a good plugin arch from fastify, salesforce, retools
28. also implement RPC with Proto-Bufs and JSON-RPC
29. plan and add receive side scaling (RSS), NUMA Topologies, SO_INCOMING_CPU
30. add grouping of routes, add opinionated folder structure
31. do i need a Global Error handler? will it need diff error as values, if yes which ones? add APIFeatures for standard pagination, cursor, limit, sort. 
32. what makes a framework and library
33. use appropriate design patterns like Context Object pattern and others as necessary
34. use MLIR to emit Coroutines so to bypass OS context switches entirely.
34, see what is index and arith dialects which are hardware agnostic for writing code.
35.  use MLIR to solve the "Abstraction Penalty." In the BEAM, if you want to use AVX-512 instructions, you have to write a NIF, which breaks your portability. In MLIR, you use the vector dialect. The vector dialect is the ultimate "hack": it represents virtual vectors of arbitrary size. During the lowering phase, the MLIR vector-to-llvm pass detects if the CPU supports AVX-512, NEON, or SVE and generates the specific machine instructions. You get the portability of a VM with the bare-metal performance of hand-tuned assembly.
36.  The BEAM is stable because it handles preemption and fault isolation (Let It Crash) at the VM level. In Mojo, you are working on bare metal, so you have to build these guards yourself.
Preemption via MLIR: Standard Mojo async is cooperative (like Python or Rust), meaning a "greedy" function can block the thread. To get BEAM-like preemption, you can use an MLIR transformation pass to inject check-points into your code loops.
Reliability (Isolation): BEAM processes share nothing. In Mojo, you can achieve this by using the Memory and Pointer APIs to ensure that "Tasks" (Mojo's version of processes) operate in strictly partitioned memory segments, essentially building a "Software-Defined Sandbox."
37.  Yes, and it is a powerful combination. Seastar is a C++ framework designed for "shared-nothing" high-performance asynchronous tasks (used in ScyllaDB). Since Mojo has top-tier C++ Interop, you can use Seastar as your underlying "Engine."
The Strategy: Use Seastar to manage the Core-per-Thread architecture and high-performance I/O (using io_uring), while using Mojo/MLIR to write your actual business logic (like legal document parsing).
The Integration: You would import the Seastar headers into Mojo. Since Seastar relies heavily on C++ Futures, you would write a small Mojo wrapper that translates seastar::future into Mojo’s async tasks.
38.  No. Rewriting the BEAM in Mojo would be a massive, redundant undertaking. Instead, you should port the abstractions.  BEAM Concept     Mojo/MLIR Equivalent
Process          asyncrt.Task (Isolated via MLIR Dialects)
Scheduler        Seastar's Core-per-core Reactor
Preemption       Loop Instrumentation (The "Hack")
Distribution     Mojo's built-in support for cross-node GPU/CPU clusters 
39.  The Hidden Layer: To truly mimic the BEAM’s stability look into MLIR's Control Flow (cf) dialect.
The BEAM's "Reduction Counter" works by counting function calls. You can replicate this by writing a custom MLIR Pass that targets cf.br (branch) and cf.cond_br (conditional branch) operations. For every branch, you decrement a register-based counter. If it hits zero, the pass forces a yield to the Seastar reactor.
This is how the "chosen ones" achieve hard preemption without an OS kernel. By doing this at the MLIR level, you get the performance of C++ but the "unkillable" nature of Erlang. If a massive OCR task on a complex legal brief starts hogging the CPU, your MLIR-injected counter will pause it every 4000 "reductions," keeping the rest of your IDE perfectly responsive. This is something the JVM simply cannot do because its bytecode is sealed away from this level of manipulation.
40.   will it run on diff CPU archs maybe due to LLVM?
41. should be flexible enough like FastAPI/express while also supporting framework like rules and battery included approach
42. add SO_REUSEPORT and others for better performace, Utilizing SO_REUSEPORT and Mojo's concurrency primitives to create a lock-free, thread-per-core listener architecture.
43. does mojo offers 0 cost FFIs? and how good is the support for C, C++, Rust
44. how will SO_REUSEPORT incorporate with Seastar 