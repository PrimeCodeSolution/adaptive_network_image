export 'image_cache_manager_stub.dart'
    if (dart.library.io) 'image_cache_manager_mobile.dart'
    if (dart.library.js_interop) 'image_cache_manager_web.dart';
