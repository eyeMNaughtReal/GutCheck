# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| Latest (main branch) | ✅ |
| Older releases | ❌ |

Only the current `main` branch receives security fixes. If you are running an older build, please update to the latest release before reporting.

## Reporting a Vulnerability

**Please do not open a public GitHub issue for security vulnerabilities.**

To report a security issue, use GitHub's private vulnerability reporting:

1. Go to the [GutCheck Security Advisories](https://github.com/eyeMNaughtReal/GutCheck/security/advisories) page
2. Click **"Report a vulnerability"**
3. Fill in the details of the issue

This keeps the report private until a fix is ready and coordinated disclosure can happen.

### What to Include

A good report includes:
- A clear description of the vulnerability and its potential impact
- Steps to reproduce, or a proof-of-concept if applicable
- The affected file(s), function(s), or component(s)
- Any suggested remediation if you have one

## Response Timeline

| Stage | Target |
|-------|--------|
| Acknowledgement | Within 48 hours |
| Initial assessment | Within 7 days |
| Fix or mitigation | Within 30 days (severity-dependent) |
| Public disclosure | After fix is released |

## Scope

This policy applies to the GutCheck iOS application source code, CI/CD workflows, and Firebase security rules contained in this repository.

**Out of scope:** Third-party dependencies (Firebase, Swift packages). Please report those directly to their respective maintainers.

## Preferred Languages

English preferred; Spanish accepted.
