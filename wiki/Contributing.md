# Contributing

Thank you for your interest in contributing to Oracle Drive! This guide will help you get started.

## Ways to Contribute

### Code Contributions
- Bug fixes
- New features
- Performance improvements
- Platform support

### Documentation
- Wiki improvements
- Code comments
- Tutorial content
- Translation

### Community
- Bug reports
- Feature requests
- User support
- Testing

## Getting Started

### 1. Fork the Repository

1. Visit the [Oracle Drive repository](https://github.com/your-repo/oracle-drive)
2. Click "Fork" to create your copy
3. Clone your fork locally:

```bash
git clone https://github.com/YOUR_USERNAME/oracle-drive.git
cd oracle-drive
```

### 2. Set Up Development Environment

See [[Building from Source]] for detailed setup instructions.

### 3. Create a Branch

```bash
# Update main
git checkout main
git pull upstream main

# Create feature branch
git checkout -b feature/your-feature-name
```

### Branch Naming
- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation
- `refactor/` - Code refactoring
- `test/` - Test additions

## Making Changes

### Code Guidelines

1. **Follow existing patterns** - Match the style of surrounding code
2. **Keep changes focused** - One feature/fix per PR
3. **Write tests** - For new functionality
4. **Update docs** - If behavior changes
5. **Run analysis** - Before committing

```bash
# Check for issues
flutter analyze
cargo clippy

# Format code
dart format lib/
cargo fmt
```

### Commit Messages

Use clear, descriptive commit messages:

```
type(scope): brief description

Detailed explanation if needed.

Fixes #123
```

**Types:**
- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation
- `style` - Formatting
- `refactor` - Code restructuring
- `test` - Tests
- `chore` - Maintenance

**Examples:**
```
feat(wdb): add bulk update dialog
fix(crystalium): prevent camera swing on node arrival
docs(wiki): add workflow system guide
refactor(providers): extract common state logic
```

## Pull Requests

### Before Submitting

1. **Test your changes** - Run the app, verify functionality
2. **Run all tests** - `flutter test` and `cargo test`
3. **Check analysis** - No errors or warnings
4. **Update CHANGELOG** - If applicable

### Submitting

1. Push your branch:
```bash
git push origin feature/your-feature-name
```

2. Open a Pull Request on GitHub

3. Fill out the PR template:

```markdown
## Description
Brief description of changes.

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation

## Testing
How was this tested?

## Screenshots
If applicable.

## Checklist
- [ ] Code follows style guidelines
- [ ] Tests pass
- [ ] Documentation updated
```

### Review Process

1. Maintainers review your PR
2. Address any feedback
3. Once approved, PR is merged
4. Your contribution is live!

## Code Architecture

### Dart/Flutter

```
lib/
├── main.dart           # Entry point
├── models/             # Data classes (immutable)
├── providers/          # Riverpod state management
├── screens/            # Full-page views
├── components/         # Reusable widgets
├── theme/              # Theming
└── src/
    ├── services/       # Core services
    ├── isar/           # Database layer
    ├── utils/          # Utilities
    └── workflow/       # Workflow engine
```

### Rust

```
rust/fabula_nova_sdk/src/
├── api.rs              # Public API (modify this for new features)
├── core/               # Shared utilities
├── modules/            # File format handlers
└── ffi/                # Low-level exports
```

### Adding New Features

**New Rust API:**
1. Add function to `api.rs`
2. Implement in appropriate module
3. Run `flutter_rust_bridge_codegen generate`
4. Add Dart wrapper in `NativeService`

**New Screen:**
1. Create screen in `lib/screens/`
2. Add provider in `lib/providers/`
3. Add to navigation in `main_screen.dart`

**New Workflow Node:**
1. Add type to `NodeType` enum
2. Create executor in `lib/src/workflow/execution/executors/`
3. Register in `WorkflowEngine`
4. Add UI in node palette

## Testing

### Dart Tests

```dart
// test/wdb_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WDB Parser', () {
    test('parses enemy database', () async {
      final data = await loadTestFile('enemy.wdb');
      final wdb = WdbParser.parse(data);
      expect(wdb.records.length, greaterThan(0));
    });
  });
}
```

### Rust Tests

```rust
// src/modules/wdb/tests.rs
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_roundtrip() {
        let original = parse("test_data/enemy.wdb").unwrap();
        let bytes = write_to_memory(&original).unwrap();
        let parsed = parse_from_memory(&bytes).unwrap();
        assert_eq!(original, parsed);
    }
}
```

### Running Tests

```bash
# All Dart tests
flutter test

# Specific Dart test
flutter test test/wdb_test.dart

# All Rust tests
cargo test

# Specific Rust test
cargo test wdb::tests
```

## Issues

### Reporting Bugs

Include:
1. **Description** - What happened?
2. **Expected** - What should happen?
3. **Steps** - How to reproduce
4. **Environment** - OS, version, etc.
5. **Logs** - Console output if applicable

### Feature Requests

Include:
1. **Use case** - Why is this needed?
2. **Proposal** - How should it work?
3. **Alternatives** - Other approaches considered

## Community Guidelines

### Be Respectful
- Treat everyone with respect
- Be patient with newcomers
- Accept constructive criticism

### Be Collaborative
- Share knowledge
- Help others learn
- Celebrate contributions

### Be Constructive
- Focus on the code, not the person
- Offer solutions, not just criticism
- Assume good intent

## Recognition

Contributors are recognized in:
- CONTRIBUTORS.md file
- Release notes
- README acknowledgements

## Questions?

- **Discord**: [Fabula Nova Crystallis Modding](https://discord.gg/fabula-nova)
- **GitHub Discussions**: For general questions
- **Issues**: For bugs and features

## See Also

- [[Building from Source]] - Development setup
- [[Code Style]] - Coding conventions
- [[Architecture]] - System design
