# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| Latest  | Yes       |
| < Latest | No       |

We recommend always using the latest version of fast_image_editor.

## Reporting a Vulnerability

If you discover a security vulnerability, please report it responsibly.

**Do NOT open a public GitHub issue for security vulnerabilities.**

Instead, please email: **eryk@codigee.com**

### What to Include

- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

### Response Timeline

- **Acknowledgment**: within 48 hours
- **Initial assessment**: within 1 week
- **Fix release**: coordinated with reporter, as soon as possible depending on severity

## Scope

This policy covers the `fast_image_editor` Flutter package, including:

- Native C code in `src/` (memory safety, buffer overflows, integer overflows)
- Dart FFI bindings in `lib/src/`
- Image data processing (untrusted user-provided bytes)
- Build configurations (CMakeLists.txt, podspec)

The library processes untrusted image data. All input validation and bounds checking
happens in native C code. Memory is manually managed — all `malloc` calls have
corresponding `free` calls. No network access is performed by the library.

## Thank You

Thank you for helping keep fast_image_editor and its users safe!
