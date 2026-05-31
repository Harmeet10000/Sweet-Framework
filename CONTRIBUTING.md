# Contributing to Sweet

Thank you for your interest in contributing to Sweet! We welcome contributions from everyone. This document provides guidelines and instructions for contributing.

## Getting Started

1. Fork the repository on GitHub
2. Clone your fork locally:
   ```bash
   git clone https://github.com/your-username/sweet.git
   cd sweet
3. Create a new branch for your feature or bugfix:
   ```bash
   git checkout -b feature/your-feature-name
   ```

## Development Setup
### Prerequisites

- Mojo 0.26.3 or later
- Linux 5.1+ (for io_uring support) or macOS (epoll fallback)
- x86_64 CPU with AVX2 support
- Magic package manager

### Installation

```bash
# Install Magic (Mojo's package manager)
curl -ssL https://magic.modular.com | bash

# Install dependencies
magic install

# Build the project
magic run mojo build src/sweet
```

### Running Tests

```bash
# Run all tests
magic run mojo test tests/

# Run specific test suite
magic run mojo test tests/unit/test_parser.mojo

# Run property-based tests
magic run mojo test tests/property/
```

### Running Benchmarks

```bash
# Run all benchmarks
magic run mojo benchmarks/full_stack_bench.mojo

# Run specific benchmark
magic run mojo benchmarks/http_parser_bench.mojo
```

### Code Formatting

```bash
# Format code
mojo format src/ tests/ examples/
```
## Making Changes

### Code Style

- Follow Mojo conventions and idioms
- Use `mojo format` to format your code
- Use meaningful variable and function names
- Keep functions focused and modular (single responsibility)
- Add docstrings for public APIs
- Add comments for complex logic
- Maintain consistency with existing code
- Follow the Railway Oriented Programming pattern for error handling

### Testing Requirements

- Add unit tests for new functionality
- Add property-based tests for core algorithms
- Add integration tests for end-to-end features
- Ensure all tests pass before submitting PR
- Aim for >90% line coverage, >85% branch coverage
- Test error paths and edge cases

### Documentation

- Update relevant documentation in `docs/`
- Add docstrings to public functions and structs
- Include code examples for new features
- Update CHANGELOG.md with your changes

### Commit Messages

Use clear, descriptive commit messages following conventional commits:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `perf`: Performance improvement
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `docs`: Documentation changes
- `chore`: Maintenance tasks

**Example:**

```
feat(parser): add SIMD optimization for delimiter detection

- Implement AVX-512 based CRLF detection
- Reduce parsing latency by 40%
- Add benchmarks for parser performance

Closes #123
```
## Submitting Changes

1. **Push your branch to your fork:**
   ```bash
   git push origin feature/your-feature-name
   ```

2. **Create a Pull Request** on GitHub with:
   - Clear description of changes
   - Reference to related issues (e.g., "Fixes #123")
   - Benchmark results if performance-related
   - Test coverage for new features
   - Screenshots/examples if UI-related

3. **Ensure all CI checks pass:**
   - All tests passing
   - Code formatted with `mojo format`
   - No linting errors
   - Documentation builds successfully

4. **Address review feedback promptly**

### Pull Request Guidelines

- **One feature or fix per PR** - Keep PRs focused
- **Include tests** for new functionality
- **Update documentation** as needed
- **Keep PRs reasonably sized** - Large PRs are harder to review
- **Provide context** - Explain why the change is needed
- **Be responsive** - Address feedback in a timely manner
- **Rebase if needed** - Keep your branch up to date with main

### PR Checklist

Before submitting, ensure:

- [ ] Code follows project style guidelines
- [ ] All tests pass locally
- [ ] New tests added for new functionality
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] Commit messages follow conventional commits
- [ ] No merge conflicts with main branch

## Reporting Issues

### Bug Reports

When reporting bugs, please include:

- **Clear description** of the issue
- **Steps to reproduce** the problem
- **Expected behavior** vs **actual behavior**
- **Environment information:**
  - Mojo version (`mojo --version`)
  - OS and version
  - CPU architecture
  - Kernel version (for Linux)
- **Relevant code snippets** or minimal reproduction
- **Error messages** and stack traces
- **Logs** if applicable

### Feature Requests

When requesting features:

- **Describe the problem** you're trying to solve
- **Explain the proposed solution**
- **Provide use cases** and examples
- **Consider alternatives** you've thought about
- **Discuss impact** on existing functionality

### Performance Issues

For performance-related issues:

- **Include benchmark results** showing the problem
- **Specify hardware** (CPU, cores, memory)
- **Provide profiling data** if available
- **Compare with expected performance** from documentation

## Performance Considerations

Sweet is a high-performance framework targeting sub-millisecond latency and 1M+ RPS. When contributing performance-critical code:

### Benchmarking

- **Include benchmark results** comparing before/after
- **Test on multiple core counts** (1, 2, 4, 8, 16 cores)
- **Measure latency percentiles** (p50, p95, p99, p999)
- **Profile memory usage** and allocations
- **Use appropriate tools** (perf, flamegraphs, etc.)

### Performance Guidelines

- **Use SIMD** where applicable (parsing, serialization)
- **Minimize allocations** - use memory arenas
- **Avoid locks** - leverage thread-per-core architecture
- **Zero-copy** where possible (StringRef, buffer reuse)
- **Document complexity** - Big-O notation for algorithms
- **Consider cache locality** - data structure layout matters

### Benchmarking Example

```bash
# Run benchmarks before changes
magic run mojo benchmarks/http_parser_bench.mojo > before.txt

# Make your changes
# ...

# Run benchmarks after changes
magic run mojo benchmarks/http_parser_bench.mojo > after.txt

# Compare results
diff before.txt after.txt
```

## Development Workflow

### Working on Issues

1. **Check existing issues** before starting work
2. **Comment on the issue** to let others know you're working on it
3. **Ask questions** if anything is unclear
4. **Link your PR** to the issue when ready

### Code Review Process

1. **Maintainers review** PRs within 2-3 business days
2. **Address feedback** - make requested changes
3. **Discussion** - engage in constructive dialogue
4. **Approval** - at least one maintainer approval required
5. **Merge** - maintainers will merge approved PRs

### Release Process

- Releases follow [Semantic Versioning](https://semver.org/)
- CHANGELOG.md is updated for each release
- Security fixes may trigger patch releases
- Breaking changes only in major versions

## Community

### Getting Help

- **GitHub Discussions** - Ask questions and share ideas
- **GitHub Issues** - Report bugs and request features
- **Documentation** - Check docs/ for guides and examples

### Ways to Contribute

Not just code! You can contribute by:

- **Reporting bugs** and issues
- **Suggesting features** and improvements
- **Writing documentation** and guides
- **Creating examples** and tutorials
- **Reviewing pull requests**
- **Answering questions** in discussions
- **Improving performance** with benchmarks
- **Testing** on different platforms

## License

By contributing to Sweet, you agree that your contributions will be licensed under the Apache License 2.0, the same license as the project.

## Questions?

Feel free to:
- Open an issue for questions
- Start a discussion on GitHub Discussions
- Reach out to maintainers

Thank you for contributing to Sweet! 🚀
