import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/activity_model.dart';
import '../../provider/activity_provider.dart';
import 'activity_history_screen.dart'; // same folder

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;

  @override
  void initState() {
    super.initState();
    _determinePosition();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ActivityProvider>(context, listen: false);
      provider.fetchActivitiesFromApi();
    });
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    _currentPosition = LatLng(position.latitude, position.longitude);
    setState(() {});

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((pos) {
      setState(() {
        _currentPosition = LatLng(pos.latitude, pos.longitude);
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(_currentPosition!),
        );
      });
    });
  }

  Future<void> _logActivity() async {
    if (_currentPosition == null) return;

    final picker = ImagePicker();
    final XFile? pickedFile =
    await picker.pickImage(source: ImageSource.camera, imageQuality: 70);

    String imagePath = '';
    Uint8List? imageBytes;

    if (pickedFile != null) {
      if (kIsWeb) {
        imageBytes = await pickedFile.readAsBytes();
      } else {
        imagePath = pickedFile.path;
      }
    }

    final activity = Activity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      latitude: _currentPosition!.latitude,
      longitude: _currentPosition!.longitude,
      imagePath: imagePath,
      imageBytes: imageBytes,
      timestamp: DateTime.now(),
    );

    Provider.of<ActivityProvider>(context, listen: false)
        .addActivity(activity, syncApi: true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Activity logged with image!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ActivityProvider>(context);

    final markers = provider.activities.map((activity) {
      return Marker(
        markerId: MarkerId(activity.id),
        position: LatLng(activity.latitude, activity.longitude),
        infoWindow: InfoWindow(
          title:
          'Activity at ${activity.timestamp.hour}:${activity.timestamp.minute}',
          snippet: activity.imagePath.isNotEmpty || activity.imageBytes != null
              ? '📷 Photo attached'
              : null,
          onTap: () {
            if ((kIsWeb && activity.imageBytes != null) ||
                (!kIsWeb && activity.imagePath.isNotEmpty)) {
              showModalBottomSheet(
                context: context,
                builder: (_) => SizedBox(
                  height: 300,
                  child: kIsWeb
                      ? Image.memory(activity.imageBytes!, fit: BoxFit.cover)
                      : Image.file(File(activity.imagePath), fit: BoxFit.cover),
                ),
              );
            }
          },
        ),
      );
    }).toSet();

    if (_currentPosition != null) {
      markers.add(Marker(
          markerId: const MarkerId('currentLocation'),
          position: _currentPosition!,
          infoWindow: const InfoWindow(title: 'You are here')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartTracker Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ActivityHistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Tablet view: side by side
          if (constraints.maxWidth > 600) {
            return Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _currentPosition == null
                      ? const Center(child: CircularProgressIndicator())
                      : GoogleMap(
                    initialCameraPosition: CameraPosition(
                        target: _currentPosition!, zoom: 16),
                    markers: markers,
                    onMapCreated: (controller) =>
                    _mapController = controller,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: ActivityHistoryWidget(),
                ),
              ],
            );
          } else {
            // Phone view: column
            final mapHeight = constraints.maxHeight * 0.7;
            return Column(
              children: [
                SizedBox(
                  height: mapHeight,
                  child: _currentPosition == null
                      ? const Center(child: CircularProgressIndicator())
                      : GoogleMap(
                    initialCameraPosition: CameraPosition(
                        target: _currentPosition!, zoom: 16),
                    markers: markers,
                    onMapCreated: (controller) =>
                    _mapController = controller,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                  ),
                ),
                Expanded(child: ActivityHistoryWidget()),
              ],
            );
          }
        },
      ),
      floatingActionButton: PopupMenuButton<String>(
        icon: const Icon(Icons.add),
        onSelected: (value) {
          if (value == 'log') {
            _logActivity();
          } else if (value == 'history') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ActivityHistoryScreen(),
              ),
            );
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'log',
            child: Text('Log Activity'),
          ),
          const PopupMenuItem(
            value: 'history',
            child: Text('Activity History'),
          ),
        ],
      ),
    );
  }
}

// Separate widget for Activity History
class ActivityHistoryWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ActivityProvider>(context);
    final activities = provider.activities;

    if (activities.isEmpty) {
      return const Center(child: Text('No activity found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            title: Text(
                'Activity at ${activity.timestamp.hour}:${activity.timestamp.minute}'),
            subtitle:
            Text('Lat: ${activity.latitude}, Lng: ${activity.longitude}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                await provider.removeActivity(activity.id);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Activity deleted')));
              },
            ),
            onTap: () {
              if ((kIsWeb && activity.imageBytes != null) ||
                  (!kIsWeb && activity.imagePath.isNotEmpty)) {
                showModalBottomSheet(
                  context: context,
                  builder: (_) => SizedBox(
                    height: 300,
                    child: kIsWeb
                        ? Image.memory(activity.imageBytes!, fit: BoxFit.cover)
                        : Image.file(File(activity.imagePath), fit: BoxFit.cover),
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }
}
