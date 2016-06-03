// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:pub_semver/pub_semver.dart';

/// Merges constraints such that they fully cover actual available versions.
///
/// See https://gist.github.com/nex3/f4d0e2a9267d1b8cfdb5132b760d0111.
class ConstraintMaximizer {
  final List<Version> _versions;

  // Indices
  final _leastUpperBounds = <Version, int>{};

  final _normalized = new Expando<bool>();

  ConstraintMaximizer(Iterable<Version> versions)
      : _versions = versions.toList();

  VersionConstraint maximize(Iterable<VersionConstraint> constraints) {
    // TODO(nweiz): if there end up being a lot of constraints per union, we can
    // avoid re-sorting them using [this algorithm][].
    //
    // [this algorithm]: https://gist.github.com/nex3/f4d0e2a9267d1b8cfdb5132b760d0111#gistcomment-1782883
    var flattened = <VersionRange>[];
    for (var constraint in constraints) {
      if (constraint is VersionUnion) {
        flattened.addAll(constraint.ranges.map(_normalize));
      } else {
        flattened.add(_normalize(constraint as VersionRange));
      }
    }

    return new VersionConstraint.unionOf(flattened);
  }

  /// Normalize [range] so that it encodes the next upper bound.
  VersionRange _normalize(VersionRange range) {
    if (_normalized[range] ?? false) return range;
    if (range.max == null) {
      _normalized[range] = true;
      return range;
    }

    // TODO(nweiz): It may be more user-friendly to avoid normalizing individual
    // versions here, so the user sees messages about "foo 1.2.3" rather than
    // "foo >=1.2.3 <1.2.4". That would require more logic in [maximize] to
    // merge those versions, though.

    // Convert the upper bound to `<V`, where V is in [_versions]. This makes
    // the range look more like a caret-style version range and implicitly
    // tracks the upper bound.
    var result = new VersionRange(
        min: range.min, max: _strictLeastUpperBound(range),
        includeMin: range.includeMin, includeMax: false);
    _normalized[result] = true;
    return result;
  }

  // Strictly greater than
  Version _strictLeastUpperBound(VersionRange range) {
    var index = _leastUpperBoundIndex(range.max);
    if (index == _versions.length) return null;

    var bound = _versions[index];
    if (!range.includeMax || bound != range.max) return bound;
    if (index + 1 == _versions.length) return null;
    return _versions[index + 1];
  }

  // Greater than or equal to, `versions.length` if none
  int _leastUpperBoundIndex(Version version) {
    // TODO(nweiz): tweak the binary search to favor the latter end of
    // [_versions]?
    return _leastUpperBounds.putIfAbsent(version,
        () => lowerBound(_versions, version));
  }
}
