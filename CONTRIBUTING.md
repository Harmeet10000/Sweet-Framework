# Contributing to Sweet

Thank you for your interest in contributing to Sweet! We welcome contributions from everyone. This document provides guidelines and instructions for contributing.

## Getting Started

1. Fork the repository on GitHub
2. Clone your fork locally:
   ```bash
   git clone https://github.com/your-username/sweet.git
   cd sweet
Create a new branch for your feature or bugfix:

git checkout -b feature/your-feature-name

Copy
bash
Development Setup
Prerequisites
Mojo 0.26.3 or later

Linux 5.1+ (for io_uring support)

x86_64 CPU with AVX2 support

Building
mojo build

Copy
bash
Running Tests
mojo test

Copy
bash
Running Benchmarks
mojo run benchmarks/full_stack_bench.mojo

Copy
bash
Making Changes
Code Style
Follow Mojo conventions and idioms

Use meaningful variable and function names

Keep functions focused and modular

Add comments for complex logic

Maintain consistency with existing code

Commit Messages
Use clear, descriptive commit messages

Start with a verb (Add, Fix, Update, Remove, etc.)

Keep the first line under 50 characters

Reference issues when applicable: "Fixes #123"

Example:

Add SIMD optimization to HTTP parser

- Implement AVX2-based delimiter detection
- Reduce parsing latency by 40%
- Add benchmarks for parser performance

Copy
Submitting Changes
Push your branch to your fork:

git push origin feature/your-feature-name

Copy
bash
Create a Pull Request on GitHub with:

Clear description of changes

Reference to related issues

Benchmark results if performance-related

Test coverage for new features

Ensure all CI checks pass

Address review feedback promptly

Pull Request Guidelines
One feature or fix per PR

Include tests for new functionality

Update documentation as needed

Keep PRs focused and reasonably sized

Provide context and rationale for changes

Reporting Issues
When reporting bugs, please include:

Clear description of the issue

Steps to reproduce

Expected vs actual behavior

Mojo version and OS information

Relevant code snippets or logs

Performance Considerations
When contributing performance-critical code:

Include benchmark results

Document algorithmic complexity

Consider memory usage

Test on multiple core counts

Profile with appropriate tools

License
By contributing to Sweet, you agree that your contributions will be licensed under the same license as the project.

Questions?
Feel free to open an issue or reach out to the maintainers for guidance.

Thank you for contributing to Sweet!
