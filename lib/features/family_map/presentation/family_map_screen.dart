import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:family_finance/app/theme/app_colors.dart';
import 'package:family_finance/features/family_map/providers/location_provider.dart';
import 'package:family_finance/shared/models/live_location.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// ── Màu marker theo thứ tự thành viên ───────────────────────────────
const _markerColors = [
  Color(0xFF534AB7),
  Color(0xFF1D9E75),
  Color(0xFFE24B4A),
  Color(0xFF378ADD),
  Color(0xFFFF8C00),
  Color(0xFF9C27B0),
];

// ── Dark Map Style JSON ──────────────────────────────────────────────
const _darkMapStyle = '''[
  {"elementType":"geometry","stylers":[{"color":"#212121"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#212121"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#757575"}]},
  {"featureType":"administrative.country","elementType":"labels.text.fill","stylers":[{"color":"#9e9e9e"}]},
  {"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#bdbdbd"}]},
  {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#181818"}]},
  {"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#616161"}]},
  {"featureType":"poi.park","elementType":"labels.text.stroke","stylers":[{"color":"#1b1b1b"}]},
  {"featureType":"road","elementType":"geometry.fill","stylers":[{"color":"#2c2c2c"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#8a8a8a"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#373737"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#3c3c3c"}]},
  {"featureType":"road.highway.controlled_access","elementType":"geometry","stylers":[{"color":"#4e4e4e"}]},
  {"featureType":"road.local","elementType":"labels.text.fill","stylers":[{"color":"#616161"}]},
  {"featureType":"transit","elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#000000"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#3d3d3d"}]}
]''';

class FamilyMapScreen extends ConsumerStatefulWidget {
  const FamilyMapScreen({super.key});

  @override
  ConsumerState<FamilyMapScreen> createState() => _FamilyMapScreenState();
}

class _FamilyMapScreenState extends ConsumerState<FamilyMapScreen>
    with WidgetsBindingObserver {
  // ── Map state ─────────────────────────────────────────────────────
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Map<String, BitmapDescriptor> _markerCache = {};
  final Map<String, Color> _memberColorMap = {};
  int _colorIndex = 0;

  // ── Permission state ──────────────────────────────────────────────
  bool _hasPermission = false;
  bool _isCheckingPermission = true;

  // ── Camera state ─────────────────────────────────────────────────
  bool _cameraFitted = false;
  bool _userDragging = false;

  // ── Selected member for bottom sheet ─────────────────────────────
  LiveLocation? _selectedMember;
  String? _selectedMemberAddress;
  bool _loadingAddress = false;
  final Map<String, String> _addressCache = {};

  // ── Self location ─────────────────────────────────────────────────
  Position? _myPosition;
  StreamSubscription<Position>? _myPositionSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initPermissionAndTracking();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mapController?.dispose();
    _myPositionSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Không dừng tracking khi vào background — ForegroundService đảm nhiệm
  }

  // ── Permission + Tracking Init ────────────────────────────────────

  Future<void> _initPermissionAndTracking() async {
    final perm = await _requestPermission();
    if (!mounted) return;
    setState(() {
      _hasPermission = perm;
      _isCheckingPermission = false;
    });

    if (perm) {
      await _startMyLocationStream();
      // Khởi động location service (upload vị trí bản thân)
      final service = ref.read(locationServiceProvider);
      service?.start();
    }
  }

  Future<bool> _requestPermission() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return perm == LocationPermission.always || perm == LocationPermission.whileInUse;
  }

  Future<void> _startMyLocationStream() async {
    _myPositionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((pos) {
      if (mounted) setState(() => _myPosition = pos);
    });
  }

  // ── Marker Building ───────────────────────────────────────────────

  Color _colorForMember(String userId) {
    if (!_memberColorMap.containsKey(userId)) {
      _memberColorMap[userId] = _markerColors[_colorIndex % _markerColors.length];
      _colorIndex++;
    }
    return _memberColorMap[userId]!;
  }

  Future<BitmapDescriptor> _buildMarkerBitmap(LiveLocation loc) async {
    final cacheKey = '${loc.userId}_${loc.isOnline}_${loc.isMoving}';
    if (_markerCache.containsKey(cacheKey)) return _markerCache[cacheKey]!;

    const size = 80.0;
    const pinHeight = 16.0;
    const totalH = size + pinHeight;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, totalH));

    final color = _colorForMember(loc.userId);

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha(50)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset(size / 2 + 2, size / 2 + 2), size / 2 - 4, shadowPaint);

    // Circle background
    final bgPaint = Paint()..color = color;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 4, bgPaint);

    // Online / offline ring
    final ringPaint = Paint()
      ..color = loc.isOnline ? const Color(0xFF4CAF50) : Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 4, ringPaint);

    // Initials text
    final initials = _getInitials(loc.displayName);
    final tp = TextPainter(
      text: TextSpan(
        text: initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: initials.length == 1 ? 28 : 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(size / 2 - tp.width / 2, size / 2 - tp.height / 2));

    // Moving indicator (dot at top-right)
    if (loc.isMoving && loc.isOnline) {
      final dotPaint = Paint()..color = const Color(0xFF4CAF50);
      canvas.drawCircle(Offset(size - 8, 8), 7, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(size - 8, 8), 5, dotPaint);
    }

    // Pin pointer
    final pinPaint = Paint()..color = color;
    final pinPath = Path()
      ..moveTo(size / 2 - 10, size - 4)
      ..lineTo(size / 2, totalH)
      ..lineTo(size / 2 + 10, size - 4)
      ..close();
    canvas.drawPath(pinPath, pinPaint);

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), totalH.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    final descriptor = BitmapDescriptor.bytes(data!.buffer.asUint8List());

    _markerCache[cacheKey] = descriptor;
    return descriptor;
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts.last[0]).toUpperCase();
  }

  // ── Marker Updates ────────────────────────────────────────────────

  Future<void> _updateMarkers(List<LiveLocation> locations) async {
    final newMarkers = <Marker>{};
    for (final loc in locations) {
      final bitmap = await _buildMarkerBitmap(loc);
      final marker = Marker(
        markerId: MarkerId(loc.userId),
        position: LatLng(loc.latitude, loc.longitude),
        icon: bitmap,
        onTap: () => _onMarkerTap(loc),
        anchor: const Offset(0.5, 1.0),
        infoWindow: InfoWindow.noText,
      );
      newMarkers.add(marker);
    }

    if (!mounted) return;
    setState(() => _markers
      ..clear()
      ..addAll(newMarkers));

    // Lần đầu: fit camera bao gồm tất cả markers
    if (!_cameraFitted && newMarkers.isNotEmpty && _mapController != null) {
      await _fitAllMarkers(locations);
      _cameraFitted = true;
    }
  }

  // ── Camera Control ────────────────────────────────────────────────

  Future<void> _fitAllMarkers(List<LiveLocation> locations) async {
    if (locations.isEmpty || _mapController == null) return;

    if (locations.length == 1) {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(locations.first.latitude, locations.first.longitude),
            zoom: 15,
          ),
        ),
      );
      return;
    }

    // Tính bounds bao gồm tất cả markers
    double minLat = locations.first.latitude;
    double maxLat = locations.first.latitude;
    double minLng = locations.first.longitude;
    double maxLng = locations.first.longitude;

    for (final loc in locations) {
      minLat = min(minLat, loc.latitude);
      maxLat = max(maxLat, loc.latitude);
      minLng = min(minLng, loc.longitude);
      maxLng = max(maxLng, loc.longitude);
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  Future<void> _animateToMember(LiveLocation loc) async {
    await _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(loc.latitude, loc.longitude),
          zoom: 16,
        ),
      ),
    );
  }

  Future<void> _animateToMyLocation() async {
    if (_myPosition == null) return;
    await _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(_myPosition!.latitude, _myPosition!.longitude),
          zoom: 16,
        ),
      ),
    );
  }

  // ── Marker Tap → Bottom Sheet ─────────────────────────────────────

  Future<void> _onMarkerTap(LiveLocation loc) async {
    if (!_userDragging) {
      await _animateToMember(loc);
    }

    final cacheKey = _addressCacheKey(loc.latitude, loc.longitude);
    final cachedAddress = _addressCache[cacheKey];

    setState(() {
      _selectedMember = loc;
      _selectedMemberAddress = cachedAddress;
      _loadingAddress = cachedAddress == null;
    });

    // Reverse geocoding chỉ khi chưa có cache để giảm gọi dịch vụ ngoài
    if (cachedAddress == null) {
      _loadAddress(loc.latitude, loc.longitude);
    }
  }

  String _addressCacheKey(double lat, double lng) {
    // Làm tròn 3 chữ số thập phân (~100m) để tái sử dụng địa chỉ gần nhau
    final roundedLat = (lat * 1000).round() / 1000;
    final roundedLng = (lng * 1000).round() / 1000;
    return '$roundedLat,$roundedLng';
  }

  Future<void> _loadAddress(double lat, double lng) async {
    final cacheKey = _addressCacheKey(lat, lng);
    final cached = _addressCache[cacheKey];
    if (cached != null) {
      if (mounted) {
        setState(() {
          _selectedMemberAddress = cached;
          _loadingAddress = false;
        });
      }
      return;
    }

    try {
      final placemarks = await placemarkFromCoordinates(lat, lng)
          .timeout(const Duration(seconds: 8));
      if (!mounted) return;
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = <String>[
          if (p.name != null && p.name!.isNotEmpty && p.name != p.thoroughfare) p.name!,
          if (p.thoroughfare != null && p.thoroughfare!.isNotEmpty) p.thoroughfare!,
          if (p.subAdministrativeArea != null && p.subAdministrativeArea!.isNotEmpty)
            p.subAdministrativeArea!,
        ].take(2).toList();
        final resolvedAddress = parts.isNotEmpty ? parts.join(', ') : 'Không xác định';
        _addressCache[cacheKey] = resolvedAddress;
        setState(() {
          _selectedMemberAddress = resolvedAddress;
          _loadingAddress = false;
        });
      } else {
        _addressCache[cacheKey] = 'Không xác định';
        setState(() {
          _selectedMemberAddress = 'Không xác định';
          _loadingAddress = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _selectedMemberAddress = 'Không lấy được địa chỉ';
          _loadingAddress = false;
        });
      }
    }
  }

  // ── Navigation ────────────────────────────────────────────────────

  Future<void> _openNavigation(LiveLocation destination) async {
    if (destination.isStale) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Vị trí có thể không chính xác'),
          content: Text(
            'Vị trí của ${destination.displayName} chưa được cập nhật trong hơn 10 phút.\n\nBạn vẫn muốn dẫn đường?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Vẫn dẫn đường'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    final lat = destination.latitude;
    final lng = destination.longitude;

    // Thử mở Google Maps trước
    final googleUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=$lat,$lng'
      '&travelmode=driving',
    );

    if (await canLaunchUrl(googleUri)) {
      await launchUrl(googleUri, mode: LaunchMode.externalApplication);
      return;
    }

    // Fallback: Apple Maps (iOS) hoặc generic geo: (Android)
    final fallbackUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng');
    if (await canLaunchUrl(fallbackUri)) {
      await launchUrl(fallbackUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy ứng dụng bản đồ')),
        );
      }
    }
  }

  Future<void> _callMember(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có số điện thoại')),
      );
      return;
    }
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _messageMember(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có số điện thoại')),
      );
      return;
    }
    final uri = Uri.parse('sms:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // ── Distance helper ───────────────────────────────────────────────

  String _distanceText(LiveLocation loc) {
    if (_myPosition == null) return '';
    final distM = Geolocator.distanceBetween(
      _myPosition!.latitude,
      _myPosition!.longitude,
      loc.latitude,
      loc.longitude,
    );
    if (distM < 1000) return '${distM.toStringAsFixed(0)} m';
    return '${(distM / 1000).toStringAsFixed(1)} km';
  }

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isCheckingPermission) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_hasPermission) {
      return _buildPermissionDeniedScreen();
    }

    return _buildMapScreen();
  }

  // ── Permission Denied ─────────────────────────────────────────────

  Widget _buildPermissionDeniedScreen() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off, size: 80, color: Colors.grey),
              const SizedBox(height: 24),
              const Text(
                'Cần quyền truy cập vị trí',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Ứng dụng cần quyền vị trí để hiển thị bản đồ gia đình và chia sẻ vị trí của bạn.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _initPermissionAndTracking,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Geolocator.openAppSettings(),
                icon: const Icon(Icons.settings),
                label: const Text('Mở Cài đặt'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Map Screen ────────────────────────────────────────────────────

  Widget _buildMapScreen() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locationsAsync = ref.watch(familyLocationsProvider);

    // Lắng nghe cập nhật vị trí để rebuild markers
    ref.listen(familyLocationsProvider, (_, next) {
      next.whenData(_updateMarkers);
    });

    return Scaffold(
      body: Stack(
        children: [
          // ── Google Map ─────────────────────────────────────────────
          GoogleMap(
            style: isDark ? _darkMapStyle : null,
            onMapCreated: (ctrl) async {
              _mapController = ctrl;
              // Fit markers nếu đã có data
              final locs = ref.read(familyLocationsProvider).valueOrNull;
              if (locs != null && locs.isNotEmpty) {
                await _fitAllMarkers(locs);
                _cameraFitted = true;
              }
            },
            initialCameraPosition: const CameraPosition(
              target: LatLng(10.762622, 106.660172), // Hồ Chí Minh default
              zoom: 12,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
            mapType: MapType.normal,
            onCameraMoveStarted: () => setState(() => _userDragging = true),
            onCameraIdle: () => setState(() => _userDragging = false),
            onTap: (_) {
              if (_selectedMember != null) {
                setState(() => _selectedMember = null);
              }
            },
          ),

          // ── Overlay: trạng thái loading / lỗi ────────────────────
          locationsAsync.when(
            data: (_) => const SizedBox.shrink(),
            loading: () => Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                      SizedBox(width: 8),
                      Text('Đang tải vị trí...', style: TextStyle(color: Colors.white, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
            error: (e, _) => Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              child: _ErrorBanner(message: 'Lỗi kết nối: ${e.toString().split(':').first}'),
            ),
          ),

          // ── Floating action buttons (top-right) ────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: Column(
              children: [
                // Về vị trí bản thân
                _MapFab(
                  icon: Icons.my_location,
                  tooltip: 'Vị trí của tôi',
                  onPressed: _animateToMyLocation,
                ),
                const SizedBox(height: 10),
                // Fit tất cả thành viên
                _MapFab(
                  icon: Icons.group,
                  tooltip: 'Xem tất cả',
                  onPressed: () {
                    final locs = ref.read(familyLocationsProvider).valueOrNull;
                    if (locs != null) _fitAllMarkers(locs);
                  },
                ),
              ],
            ),
          ),

          // ── Members list overlay (bottom) ─────────────────────────
          if (_selectedMember == null)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: _MemberListStrip(
                locationsAsync: locationsAsync,
                onMemberTap: _onMarkerTap,
              ),
            ),

          // ── Bottom sheet khi chọn thành viên ─────────────────────
          if (_selectedMember != null)
            _MemberDetailSheet(
              location: _selectedMember!,
              distanceText: _distanceText(_selectedMember!),
              address: _selectedMemberAddress,
              loadingAddress: _loadingAddress,
              onClose: () => setState(() => _selectedMember = null),
              onNavigate: () => _openNavigation(_selectedMember!),
              onCall: () => _callMember(null),
              onMessage: () => _messageMember(null),
              memberColor: _colorForMember(_selectedMember!.userId),
            ),
        ],
      ),
    );
  }
}

// ── _MapFab ───────────────────────────────────────────────────────────
class _MapFab extends StatelessWidget {
  const _MapFab({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      color: Theme.of(context).colorScheme.surface,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, size: 22, color: AppColors.primary),
        ),
      ),
    );
  }
}

// ── _MemberListStrip ───────────────────────────────────────────────────
class _MemberListStrip extends StatelessWidget {
  const _MemberListStrip({
    required this.locationsAsync,
    required this.onMemberTap,
  });

  final AsyncValue<List<LiveLocation>> locationsAsync;
  final void Function(LiveLocation) onMemberTap;

  @override
  Widget build(BuildContext context) {
    final locations = locationsAsync.valueOrNull;
    if (locations == null || locations.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: locations.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final loc = locations[i];
          return _MemberChip(location: loc, onTap: () => onMemberTap(loc));
        },
      ),
    );
  }
}

class _MemberChip extends StatelessWidget {
  const _MemberChip({required this.location, required this.onTap});

  final LiveLocation location;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withAlpha(30),
                  child: Text(
                    location.displayName.isNotEmpty ? location.displayName[0].toUpperCase() : '?',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: location.isOnline ? const Color(0xFF4CAF50) : Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location.displayName.split(' ').last, // Tên ngắn
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(
                  location.onlineStatusText,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── _MemberDetailSheet ────────────────────────────────────────────────
class _MemberDetailSheet extends StatelessWidget {
  const _MemberDetailSheet({
    required this.location,
    required this.distanceText,
    required this.address,
    required this.loadingAddress,
    required this.onClose,
    required this.onNavigate,
    required this.onCall,
    required this.onMessage,
    required this.memberColor,
  });

  final LiveLocation location;
  final String distanceText;
  final String? address;
  final bool loadingAddress;
  final VoidCallback onClose;
  final VoidCallback onNavigate;
  final VoidCallback onCall;
  final VoidCallback onMessage;
  final Color memberColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1E1C2E) : Colors.white;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(38), blurRadius: 20, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),

                // Avatar + info
                Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: memberColor.withAlpha(30),
                          child: Text(
                            location.displayName.isNotEmpty
                                ? location.displayName.substring(0, min(2, location.displayName.length)).toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: memberColor,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: location.isOnline ? const Color(0xFF4CAF50) : Colors.grey,
                              shape: BoxShape.circle,
                              border: Border.all(color: surface, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            location.displayName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                location.isOnline ? Icons.circle : Icons.circle_outlined,
                                size: 10,
                                color: location.isOnline ? const Color(0xFF4CAF50) : Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                location.onlineStatusText,
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Close button
                    IconButton(
                      onPressed: onClose,
                      icon: const Icon(Icons.close),
                      color: Colors.grey,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Info chips
                Row(
                  children: [
                    if (distanceText.isNotEmpty) ...[
                      _InfoChip(
                        icon: Icons.near_me,
                        label: 'Cách $distanceText',
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                    ],
                    _InfoChip(
                      icon: location.batteryLow ? Icons.battery_alert : Icons.battery_full,
                      label: location.batteryText,
                      color: location.batteryLow ? AppColors.expense : AppColors.income,
                    ),
                    if (location.isMoving) ...[
                      const SizedBox(width: 8),
                      _InfoChip(
                        icon: Icons.directions_run,
                        label: 'Đang di chuyển',
                        color: AppColors.transfer,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                // Địa chỉ
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A2840) : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.place, size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: loadingAddress
                            ? const SizedBox(
                                height: 14,
                                width: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                address ?? 'Đang lấy địa chỉ...',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),

                // Stale warning
                if (location.isStale) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber, size: 16, color: Colors.amber.shade700),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Vị trí hiện tại có thể không chính xác (${location.onlineStatusText})',
                            style: TextStyle(fontSize: 12, color: Colors.amber.shade800),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.call,
                        label: 'Gọi',
                        onPressed: onCall,
                        color: AppColors.income,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.message,
                        label: 'Nhắn tin',
                        onPressed: onMessage,
                        color: AppColors.transfer,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: onNavigate,
                        icon: const Icon(Icons.navigation),
                        label: const Text('Dẫn đường'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── _InfoChip ─────────────────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── _ActionButton ─────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: BorderSide(color: color.withAlpha(100)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }
}

// ── _ErrorBanner ──────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.expense,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
