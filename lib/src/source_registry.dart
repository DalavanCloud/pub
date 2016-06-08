// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package.dart';
import 'source.dart';
import 'source/git.dart';
import 'source/hosted.dart';
import 'source/path.dart';
import 'source/unknown.dart';

final sources = new SourceRegistry._();

/// A class that keeps track of [Source]s used for getting packages.
class SourceRegistry {
  /// The registered sources.
  ///
  /// This is initialized with the three built-in sources.
  final _sources = {
    "git": new GitSource(),
    "hosted": new HostedSource(),
    "path": new PathSource()
  };

  /// The default source, which is used when no source is specified.
  ///
  /// This defaults to [hosted].
  Source get defaultSource => _default;
  Source _default;

  /// The registered sources, in name order.
  List<Source> get sources {
    var sources = _sources.values.toList();
    sources.sort((a, b) => a.name.compareTo(b.name));
    return sources;
  }

  /// The built-in [GitSource].
  GitSource get git => _sources["git"] as GitSource;

  /// The built-in [HostedSource].
  HostedSource get hosted => _sources["hosted"] as HostedSource;

  /// The built-in [PathSource].
  PathSource get path => _sources["path"] as PathSource;

  SourceRegistry._() {
    _default = hosted;
  }

  /// Returns whether [id1] and [id2] refer to the same package, including
  /// validating that their descriptions are equivalent.
  bool idsEqual(PackageId id1, PackageId id2) {
    if (id1 != id2) return false;
    if (id1 == null && id2 == null) return true;
    return idDescriptionsEqual(id1, id2);
  }

  /// Returns whether [id1] and [id2] have the same source and description.
  ///
  /// This doesn't check whether the name or versions are equal.
  bool idDescriptionsEqual(PackageId id1, PackageId id2) {
    if (id1.source != id2.source) return false;
    return this[id1.source].descriptionsEqual(id1.description, id2.description);
  }

  /// Sets the default source.
  ///
  /// This takes a string, which must be the name of a registered source.
  void setDefault(String name) {
    if (!_sources.containsKey(name)) {
      throw new StateError('Default source $name is not in the registry');
    }

    _default = _sources[name];
  }

  /// Registers a new source.
  ///
  /// This source may not have the same name as a source that's already been
  /// registered.
  void register(Source source) {
    if (_sources.containsKey(source.name)) {
      throw new StateError('Source registry already has a source named '
          '${source.name}');
    }

    _sources[source.name] = source;
  }

  /// Returns the source named [name].
  ///
  /// Returns an [UnknownSource] if no source with that name has been
  /// registered. If [name] is null, returns the default source.
  Source operator[](String name) {
    if (name == null) return _default;
    if (_sources.containsKey(name)) return _sources[name];
    return new UnknownSource(name);
  }
}
