export 'image_loader_stub.dart'
    if (dart.library.io) 'image_loader_mobile.dart'
    if (dart.library.js_interop) 'image_loader_web.dart';
