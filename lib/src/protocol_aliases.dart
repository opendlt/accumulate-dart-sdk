/// Non-colliding aliases for generated protocol types whose names shadow
/// `dart:core`.
///
/// The Accumulate protocol defines a type literally named `Object` (the account
/// object envelope: type + chains + pending). The code generator emits it
/// verbatim, and exporting it from the umbrella library shadowed
/// `dart:core`'s `Object` for **every consumer** — so ordinary Dart such as
///
/// ```dart
/// Object o = 'hello';
/// ```
///
/// failed to compile with `A value of type 'String' can't be assigned to a
/// variable of type 'Object'` merely because the SDK had been imported.
///
/// The umbrella now hides the generated `Object` and re-exports it here as
/// [ProtocolObject]. Nothing is lost — the type is still reachable — and
/// `dart:core` behaves normally again.
///
/// The alias lives in a hand-maintained file on purpose: `lib/src/generated/`
/// is overwritten by the generator (see REGENERATION.md), so a rename applied
/// there would be silently reverted on the next regeneration.
library;

import 'generated/types/general_types.dart' as general;

/// The Accumulate protocol's `Object` type (account type, chains, pending).
///
/// Named `ProtocolObject` here to avoid shadowing `dart:core`'s `Object`.
typedef ProtocolObject = general.Object;
