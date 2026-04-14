1. add epoll as fallback
2. dont use complex FP patterns, use function composition
3. add future support for pattern matching when it comes to mojo
4. middlewares and plugins should be separate(research first)
5. see the implementation of SeaStar/Glommio and check if it works with proposed plan of Task_Queue implementation of single and multicore
6. rename it to Sweet from Axiom
7. check if photon(logger) and http client is in plan or not
8. add plan for WebSockets & SSE, also check for UDP(research with gemini first)
9. add complete support for Auth and OAuth inpired from on in Agent_saul and use paseto tokens