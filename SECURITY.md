# Security Policy

## Supported Versions

We provide security updates for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 0.x.x   | :white_check_mark: |

Once Sweet reaches 1.0.0:

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting Security Vulnerabilities

**Please do not report security vulnerabilities through public GitHub issues.**

If you discover a security vulnerability in Sweet, please report it privately:

### How to Report

1. **Email:** security@sweet-framework.dev (preferred)
2. **GitHub Security Advisory:** Use the "Report a vulnerability" button in the Security tab

### What to Include

- **Description** of the vulnerability
- **Steps to reproduce** (if applicable)
- **Potential impact** and severity assessment
- **Affected versions**
- **Suggested fix** (if available)
- **Your contact information** for follow-up

### Response Timeline

- **Acknowledgment:** Within 48 hours
- **Initial assessment:** Within 5 business days
- **Status updates:** Every 7 days until resolved
- **Fix timeline:** Depends on severity (critical: <7 days, high: <30 days)

### Disclosure Policy

- We will work with you to understand and resolve the issue
- We request that you do not publicly disclose the vulnerability until we've released a fix
- We will credit you in the security advisory (unless you prefer to remain anonymous)
- We may request a CVE for significant vulnerabilities

## Security Considerations

Sweet is designed with security in mind. Here are key security features and considerations:

### Built-in Security Features

#### Input Validation
- **Maximum header size:** 8KB (configurable)
- **Maximum body size:** 10MB (configurable)
- **Maximum path length:** 2KB
- **Maximum query string:** 4KB
- **Maximum header count:** 100
- **UTF-8 validation:** All string inputs validated
- **Bounds checking:** All buffer accesses checked

#### Memory Safety
- **Arena allocator:** Prevents buffer overflows
- **Zero-copy parsing:** Reduces attack surface
- **Automatic cleanup:** Memory freed after each request
- **No use-after-free:** Mojo's ownership system

#### Network Security
- **Rate limiting:** Built-in middleware support
- **CORS:** Configurable cross-origin policies
- **WebSocket security:** Origin validation, frame size limits
- **SSE security:** Connection limits, keep-alive monitoring

## Security Best Practices for Users

1. **Keep Sweet Updated**: Regularly update to the latest version
2. **Use HTTPS**: Always use HTTPS in production
3. **Validate Input**: Implement comprehensive input validation
4. **Rate Limiting**: Enable rate limiting on public endpoints
5. **Authentication**: Implement strong authentication mechanisms
6. **Secrets Management**: Never commit secrets to version control
7. **Monitoring**: Set up proper logging and monitoring
8. **Testing**: Include security testing in your CI/CD pipeline

## Supported Versions

Security updates are provided for:

- Current major version (all minor versions)
- Previous major version (critical fixes only)

## Security Advisories

Security advisories will be published on:

- GitHub Security Advisories
- Project website
- Mailing list (when established)

## Compliance

Sweet aims to follow security best practices and standards:

- OWASP Top 10
- CWE/SANS Top 25
- NIST Cybersecurity Framework

## Contact

For security-related inquiries, contact: security@sweet-framework.dev

Thank you for helping keep Sweet secure!
