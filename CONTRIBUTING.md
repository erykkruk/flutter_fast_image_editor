# Contributing to fast_image_editor

Thank you for your interest in contributing! This guide will help you get started.

## How to Contribute

### Reporting Bugs

1. Check [existing issues](https://github.com/erykkruk/fast_image_editor/issues) first
2. Open a new issue using the **Bug Report** template
3. Include: Flutter version, platform, minimal reproduction code, expected vs actual behavior

### Suggesting Features

1. Open an issue using the **Feature Request** template
2. Describe the use case and why it would be useful
3. Include API examples if possible

### Submitting Code

1. Fork the repository
2. Create a branch from `main`: `git checkout -b feature/your-feature`
3. Make your changes
4. Run checks:
   ```bash
   flutter analyze
   dart format .
   flutter test
   ```
5. Commit using [Conventional Commits](https://www.conventionalcommits.org/):
   ```
   feat: add gaussian blur effect
   fix: fix memory leak in region crop
   docs: update API documentation
   test: add tests for brightness filter
   ```
6. Open a Pull Request against `main`

## Development Setup

```bash
git clone https://github.com/erykkruk/fast_image_editor.git
cd fast_image_editor
flutter pub get
```

### Running the example app

```bash
cd example
flutter pub get
flutter run
```

### Project Structure

- `src/` — Native C code (image processing effects)
- `lib/` — Dart FFI bindings and public API
- `ios/` — iOS build configuration
- `android/` — Android build configuration
- `test/` — Flutter tests
- `example/` — Demo app

### Working with Native Code

The core image processing is in C (`src/`). If you modify native code:

- Test on **both** iOS and Android
- Ensure no memory leaks (all `malloc` has matching `free`)
- Keep the API surface minimal (single FFI entry point per operation)
- Validate all buffer sizes before native operations

## Code Style

- Follow `analysis_options.yaml` rules (strict linting, zero warnings)
- Use `dart format` for consistent formatting
- No `print()` statements in library code
- No `dynamic` types — always use explicit types
- Add `///` doc comments for all public APIs
- Keep functions focused and small (single responsibility)

## Pull Request Guidelines

- Keep PRs focused on a single change
- Update `CHANGELOG.md` with your changes under `## Unreleased`
- Update `README.md` if you change the public API
- Add tests for new functionality
- Ensure all CI checks pass before requesting review
- Native changes must be tested on both iOS and Android

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).
