import 'package:family_finance/app/theme/app_colors.dart';
import 'package:family_finance/shared/services/location_sharing_service.dart';
import 'package:family_finance/shared/widgets/app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class FamilyMapViewScreen extends StatefulWidget {
  const FamilyMapViewScreen({
    super.key,
    required this.memberUid,
    required this.memberName,
  });

  final String memberUid;
  final String memberName;

  @override
  State<FamilyMapViewScreen> createState() => _FamilyMapViewScreenState();
}

class _FamilyMapViewScreenState extends State<FamilyMapViewScreen> {
  GoogleMapController? _mapController;
  LatLng? _memberLocation;

  bool _loading = true;

  Future<void> _openNavigation() async {
    if (_memberLocation == null) return;
    final lat = _memberLocation!.latitude;
    final lng = _memberLocation!.longitude;
    final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text('Vị trí: ${widget.memberName}'),
        actions: [
          if (_memberLocation != null)
            IconButton(
              onPressed: _openNavigation,
              icon: const Icon(Icons.navigation_outlined),
              tooltip: 'Dẫn đường',
            ),
        ],
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: LocationSharingService.instance.watchMemberLocation(widget.memberUid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && _loading) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data;

          if (data == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_off_outlined, size: 52, color: AppColors.border),
                  const SizedBox(height: 12),
                  Text(
                    '${widget.memberName} chưa chia sẻ vị trí',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Nhờ thành viên nhấn "Chia sẻ vị trí" trong Bản đồ gia đình.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          final lat = (data['lat'] as num).toDouble();
          final lng = (data['lng'] as num).toDouble();
          final position = LatLng(lat, lng);
          final ts = data['updatedAt'];
          DateTime? updatedAt;
          if (ts != null) {
            try {
              // Firestore Timestamp or null
              updatedAt = (ts as dynamic).toDate() as DateTime?;
            } catch (_) {}
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _memberLocation = position;
            _loading = false;
            _mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(position, 15),
            );
          });

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(target: position, zoom: 15),
                markers: {
                  Marker(
                    markerId: const MarkerId('member'),
                    position: position,
                    infoWindow: InfoWindow(title: widget.memberName),
                  ),
                },
                onMapCreated: (ctrl) {
                  _mapController = ctrl;
                  _mapController?.animateCamera(
                    CameraUpdate.newLatLngZoom(position, 15),
                  );
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
              ),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: AppColors.expense, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(widget.memberName, style: const TextStyle(fontWeight: FontWeight.w600)),
                              if (updatedAt != null)
                                Text(
                                  'Cập nhật: ${DateFormat('HH:mm dd/MM').format(updatedAt)}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                            ],
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: _openNavigation,
                          icon: const Icon(Icons.navigation, size: 16),
                          label: const Text('Dẫn đường'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
