// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../package.dart';

abstract class Cause {
  static const rootDependency = const _RootCause("root dependency");
  static const explicitDependency = const _RootCause("explicit dependency");
  static const packageNotFound = const _RootCause("package not found");
  static const noVersion = const _RootCause("package version not found");
  static const badSdkVersion = const _RootCause("bad SDK version");
  static const unknownSource = const _RootCause("unknown dependency source");
}

class _RootCause implements Cause {
  final String _name;

  const _RootCause(this._name);

  String toString() => _name;
}

/// A context-independent truth about the package graph.
abstract class Fact implements Cause {
  List<Cause> get causes;
}

/// A package version covered by [allowed] is required.
class Required implements Fact {
  final List<Cause> causes;

  final PackageDep dep;

  Required(this.dep, [Iterable<Cause> causes])
      : causes = causes?.toList() ?? [Cause.rootDependency];

  String toString() => "$dep is required";
}

/// No package versions covered by [dep] can ever be selected.
class Disallowed implements Fact {
  final List<Cause> causes;

  final PackageDep dep;

  Disallowed(this.dep, Iterable<Cause> causes)
      : causes = causes.toList();

  String toString() => "$dep is forbidden";
}

/// All versions covered by [depender] require a version covered by [allowed].
class Dependency implements Fact {
  final List<Cause> causes;

  final PackageDep depender;

  final PackageDep allowed;

  Dependency(this.depender, this.allowed, [Iterable<Cause> causes])
      : causes = causes?.toList() ?? [Cause.explicitDependency] {
    assert(depender.name != allowed.name);
  }

  String toString() => "$depender depends on $allowed";
}

/// No versions covered by [package1] may be selected along with any versions
/// covered by [package2].
class Incompatibility implements Fact {
  final List<Cause> causes;

  final PackageDep dep1;
  final PackageDep dep2;

  Incompatibility(this.dep1, this.dep2, Iterable<Cause> causes)
      : causes = causes.toList() {
    assert(dep1.name != dep2.name);
  }

  String toString() => "$dep1 is incompatible with $dep2";
}
