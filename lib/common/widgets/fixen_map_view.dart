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
    if (kIsWeb) return false;
    final key = EnvConfig.googleMapsApiKey;
    if (key.isEmpty || key.contains('MOCK') || key.startsWith('AIzaSyA1B2C3D4E5F6G7H8I9J0K')) {
      return false;
    }
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
    Color pinColor = Colors.grey;
    IconData markerIcon = Icons.engineering_rounded;

    final cat = label.toLowerCase();
    if (cat.contains('electric')) {
      pinColor = const Color(0xFFFBBF24); // Electrician Yellow
      markerIcon = Icons.electric_bolt_rounded;
    } else if (cat.contains('carpenter')) {
      pinColor = const Color(0xFF8B5A2B); // Wooden Brown
      markerIcon = Icons.construction_rounded;
    } else if (cat.contains('plumber')) {
      pinColor = const Color(0xFF2563EB); // Plumber Blue
      markerIcon = Icons.plumbing_rounded;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TeardropPin(
          pinColor: pinColor,
          icon: markerIcon,
          iconColor: pinColor,
          size: 36,
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.78),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
          ),
        ),
      ],
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

class TeardropPin extends StatelessWidget {
  final Color pinColor;
  final IconData icon;
  final Color iconColor;
  final double size;

  const TeardropPin({
    super.key,
    required this.pinColor,
    required this.icon,
    required this.iconColor,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.3,
      child: CustomPaint(
        painter: _TeardropPinPainter(pinColor: pinColor),
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            width: size * 0.72,
            height: size * 0.72,
            margin: EdgeInsets.only(top: size * 0.08),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: size * 0.44,
            ),
          ),
        ),
      ),
    );
  }
}

class _TeardropPinPainter extends CustomPainter {
  final Color pinColor;

  _TeardropPinPainter({required this.pinColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = pinColor
      ..style = PaintingStyle.fill;

    final path = Path();
    final double w = size.width;
    final double h = size.height;
    final double r = w / 2;

    // Draw teardrop pin shape pointing down to (r, h)
    path.moveTo(r, h);
    path.cubicTo(0, h * 0.6, 0, r, r, 0);
    path.cubicTo(w, r, w, h * 0.6, r, h);
    path.close();

    // Draw shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawPath(path.shift(const Offset(0, 2)), shadowPaint);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TeardropPinPainter oldDelegate) =>
      oldDelegate.pinColor != pinColor;
}
