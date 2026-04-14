6. rename it to Sweet from Axiom      DONE
1. add epoll as fallback
2. dont use complex FP patterns, use function composition
3. add future support for pattern matching when it comes to mojo
4. middlewares and plugins should be separate(research first)
5. see the implementation of SeaStar/Glommio in the plan and check if it works with proposed plan of Task_Queue implementation of single and multicore
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
20. check what developer ergonomics from Echo, FastAPI, spring Boot, laravel, rails, ruby, effectTS
21. also think about this working in cross platform like windows, macOS
22. check for feasibility of this with implementation from popular frameworks
Enforce max header size (8KB)
Enforce max body size (10MB, configurable)
Enforce max path length (2KB)
Enforce max query string length (4KB)
Enforce max header count (100)
23. verify of all the metaprogramming features used
24. should i have a ctx object like in koa and go framwworks]
25. from the orginal plan check whether all the hacks where inlcuded in the design or not
26. make a standard library inspired from go, python, rust, Effect.ts
27. 