import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../app/config/env/env_config.dart';

class FixenMapMarker {
  final String id;
  final String label;
  final double latitude;
  final double longitude;
  final BitmapDescriptor? icon;

  const FixenMapMarker({
    required this.id,
    required this.label,
    required this.latitude,
    required this.longitude,
    this.icon,
  });
}

class FixenMapView extends StatelessWidget {
  final double latitude;
  final double longitude;
  final double zoom;
  final Set<Polyline> polylines;
  final List<FixenMapMarker> markers;
  final bool showMyLocation;
  final bool liteMode;
  final VoidCallback? onMapUnavailable;

  const FixenMapView({
    super.key,
    required this.latitude,
    required this.longitude,
    this.zoom = 15,
    this.polylines = const {},
    this.markers = const [],
    this.showMyLocation = true,
    this.liteMode = false,
    this.onMapUnavailable,
  });

  static bool get supportsGoogleMaps {
    final key = EnvConfig.googleMapsApiKey;
    if (key.isEmpty || key.contains('MOCK') || key.startsWith('AIzaSyA1B2C3D4E5F6G7H8I9J0K')) {
      return false;
    }
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  Widget build(BuildContext context) {
    if (!supportsGoogleMaps) {
      return _MapFallback(
        latitude: latitude,
        longitude: longitude,
        markers: markers,
        onTap: onMapUnavailable,
      );
    }

    final center = LatLng(latitude, longitude);
    final mapMarkers = <Marker>{
      Marker(
        markerId: const MarkerId('customer_location'),
        position: center,
        infoWindow: const InfoWindow(title: 'Service location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
      ...markers.map(
        (marker) => Marker(
          markerId: MarkerId(marker.id),
          position: LatLng(marker.latitude, marker.longitude),
          infoWindow: InfoWindow(title: marker.label),
          icon: marker.icon ?? BitmapDescriptor.defaultMarker,
        ),
      ),
    };

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: center, zoom: zoom),
      markers: mapMarkers,
      polylines: polylines,
      myLocationEnabled: showMyLocation,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: true,
      compassEnabled: true,
      mapToolbarEnabled: true,
      liteModeEnabled: liteMode && !kIsWeb,
      onMapCreated: (controller) {
        controller.animateCamera(CameraUpdate.newLatLngZoom(center, zoom));
      },
    );
  }
}

class _MapFallback extends StatelessWidget {
  final double latitude;
  final double longitude;
  final List<FixenMapMarker> markers;
  final VoidCallback? onTap;

  const _MapFallback({
    required this.latitude,
    required this.longitude,
    required this.markers,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      child: CustomPaint(
        painter: _FallbackMapPainter(isDark: isDark),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.person_pin_circle_rounded,
                    color: Theme.of(context).primaryColor,
                    size: 42,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            ...markers.take(4).map((marker) {
              final offset = marker.id.hashCode.abs() % 4;
              final alignments = [
                Alignment.topLeft,
                Alignment.topRight,
                Alignment.bottomLeft,
                Alignment.bottomRight,
              ];
              return Align(
                alignment: alignments[offset],
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: _FallbackMarker(label: marker.label),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _FallbackMarker extends StatelessWidget {
  final String label;

  const _FallbackMarker({required this.label});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.72),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.engineering_rounded, color: Colors.white, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _FallbackMapPainter extends CustomPainter {
  final bool isDark;

  const _FallbackMapPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final basePaint = Paint()
      ..color = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    canvas.drawRect(Offset.zero & size, basePaint);

    final gridPaint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final roadPaint = Paint()
      ..color = isDark ? const Color(0xFF334155) : Colors.white
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(20, size.height * 0.55), Offset(size.width - 20, size.height * 0.45), roadPaint);
    canvas.drawLine(Offset(size.width * 0.45, 10), Offset(size.width * 0.56, size.height - 10), roadPaint);
  }

  @override
  bool shouldRepaint(covariant _FallbackMapPainter oldDelegate) => oldDelegate.isDark != isDark;
}
