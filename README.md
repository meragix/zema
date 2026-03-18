# Zema

[![pub package](https://img.shields.io/pub/v/zema.svg)](https://pub.dev/packages/zema)
[![Build Status](https://github.com/meragix/zema/workflows/CI/badge.svg)](https://github.com/meragix/zema/actions)
[![Coverage](https://img.shields.io/codecov/c/github/meragix/zema)](https://codecov.io/gh/meragix/zema)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Zod-like schema validation for Dart. Type-safe runtime validation with a fluent, declarative API.

## 📦 Packages

This monorepo contains:

- [`zema`](./packages/zema) - Core validation library

## 🚀 Quick Start

```yaml
dependencies:
  zema: ^0.1.0
```

```dart
import 'package:zema/zema.dart';

final userSchema = z.object({
  'name': z.string().min(2),
  'email': z.string().email(),
  'age': z.int().positive().optional(),
});

final user = userSchema.parse({
  'name': 'John',
  'email': 'john@example.com',
  'age': 30,
});
```

## 🛠️ Development

This project uses [Melos](https://melos.invertase.dev/) to manage the monorepo.

### Setup

```bash
# Install Melos
dart pub global activate melos

# Bootstrap the workspace
melos bootstrap
```

### Common Commands

```bash
# Run tests
melos test

# Run analysis
melos analyze

# Format code
melos format

# Check publish readiness
melos publish:check

# Version packages
melos version
```

## 📚 Documentation

- [Zema Documentation](https://zema.meragix.dev)
- [API Reference](https://pub.dev/documentation/zema/latest/)

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md)

## 📄 License

MIT License - see [LICENSE](LICENSE)

## 🔗 Links

- [Website](https://meragix.dev)
- [Documentation](https://zema.meragix.dev)
- [GitHub](https://github.com/meragix/zema)
- [pub.dev](https://pub.dev/packages/zema)

<!-- Rôle : Agis en tant qu'Architecte Logiciel Senior spécialisé en systèmes de types et compilateurs.

Mission : Rédiger la documentation technique de la bibliothèque Zema. Ton objectif est d'expliquer les mécanismes internes et l'usage de l'API avec une précision chirurgicale.

Directives de Style :

Ton : Froid, autoritaire, factuel. Utilise uniquement des phrases déclaratives.

Structure : Utilise des titres hiérarchisés (H1, H2, H3). Une idée par phrase. Pas de paragraphes denses.

Lexique : Utilise les termes techniques exacts (Inférence, Coercition, Extension Types, Covariance, Monades, Arborescence de types).

Interdictions Strictes :

AUCUN tiret cadratin (—). Utilise des deux-points (:) ou des points simples.

AUCUN adjectif marketing (puissant, incroyable, révolutionnaire).

AUCUN ton conversationnel ("nous allons voir", "n'hésitez pas").

AUCUNE question rhétorique.

Format de Sortie :

Description : Définition technique de l'objet ou de la méthode.

Signature : Signature Dart exacte.

Mécanisme : Explication du flux de données ou de la contrainte de type.

Exemple : Code minimaliste et idiomatique.

Données à traiter : [INSÈRE TES NOTES OU TON CODE ICI] -->