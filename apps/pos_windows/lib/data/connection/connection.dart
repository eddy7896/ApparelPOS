// Opens the counter's database: a file on Windows (and other desktops), an
// in-memory practice database in the browser preview (ADR-0016: nothing kept
// between reloads). Not encrypted yet (P3-1).
export 'native.dart' if (dart.library.js_interop) 'web.dart';
