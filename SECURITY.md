# Security Policy

## Supported Versions

We provide security updates for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

Instead, please report security vulnerabilities by:

1. **Email**: Send details to the project maintainers
2. **Private Issue**: Use GitHub's private vulnerability reporting feature
3. **Direct Contact**: Reach out to maintainers directly

### What to Include

When reporting a vulnerability, please include:
- Description of the vulnerability
- Steps to reproduce the issue
- Potential impact assessment
- Any suggested fixes (if known)

### Response Timeline

- **Initial Response**: Within 48 hours
- **Status Update**: Within 1 week
- **Resolution Timeline**: Varies by severity

## Security Best Practices

When using this SDK:

### Key Management
- Never commit private keys to source control
- Use secure key storage mechanisms
- Rotate keys regularly
- Use environment variables or secure vaults for sensitive data

### Network Security
- Always use HTTPS endpoints in production
- Validate SSL/TLS certificates
- Implement proper timeout and retry policies
- Monitor for unusual network activity

### Code Security
- Keep dependencies updated
- Run security audits regularly
- Follow principle of least privilege
- Validate all external inputs

### Cryptographic Security
- This SDK implements Ed25519 signatures with verified compatibility
- LID/LTA derivation uses SHA256 with proper checksum validation
- All cryptographic operations use well-tested libraries
- Binary encoding follows canonical rules to prevent tampering

## Scope

This security policy covers:
- The opendlt-accumulate Dart SDK code
- Generated clients and type definitions
- CLI tools and examples
- Documentation and tooling scripts

Out of scope:
- Accumulate blockchain network security
- Third-party dependencies (report to their maintainers)
- Infrastructure or deployment security

## Disclosure Policy

We follow responsible disclosure:
1. Vulnerabilities are fixed privately
2. Security advisories are published after fixes are available
3. Credit is given to reporters (unless they prefer anonymity)
4. Public disclosure timeline is coordinated with reporters