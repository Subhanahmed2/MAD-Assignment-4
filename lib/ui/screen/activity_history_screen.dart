import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/activity_provider.dart';
import '../../models/activity_model.dart';

class ActivityHistoryScreen extends StatefulWidget {
  const ActivityHistoryScreen({Key? key}) : super(key: key);

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final activityProvider = Provider.of<ActivityProvider>(context);

    // Filter activities based on search query
    final filteredActivities = activityProvider.activities.where((activity) {
      final timestampStr =
          '${activity.timestamp.hour}:${activity.timestamp.minute}';
      final latStr = activity.latitude.toString();
      final lngStr = activity.longitude.toString();

      return timestampStr.contains(searchQuery) ||
          latStr.contains(searchQuery) ||
          lngStr.contains(searchQuery);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity History'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth > 600;
          final listWidget = filteredActivities.isEmpty
              ? const Center(child: Text('No activity found'))
              : ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: filteredActivities.length,
            itemBuilder: (context, index) {
              final activity = filteredActivities[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: Text(
                      'Activity at ${activity.timestamp.hour}:${activity.timestamp.minute}'),
                  subtitle: Text(
                      'Lat: ${activity.latitude}, Lng: ${activity.longitude}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await activityProvider.removeActivity(activity.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Activity deleted')),
                      );
                    },
                  ),
                  onTap: () {
                    if ((kIsWeb && activity.imageBytes != null) ||
                        (!kIsWeb && activity.imagePath.isNotEmpty)) {
                      showModalBottomSheet(
                        context: context,
                        builder: (_) => SizedBox(
                          height: 300,
                          child: kIsWeb && activity.imageBytes != null
                              ? Image.memory(activity.imageBytes!,
                              fit: BoxFit.cover)
                              : Image.file(File(activity.imagePath),
                              fit: BoxFit.cover),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );

          // Tablet view: show side-by-side if needed (future use)
          if (isTablet) {
            return Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'Search by time or location',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setState(() {
                              searchQuery = value.trim();
                            });
                          },
                        ),
                      ),
                      Expanded(child: listWidget),
                    ],
                  ),
                ),
                // Placeholder for map or extra content
                Expanded(
                  flex: 3,
                  child: Center(
                    child: Text(
                      'Map or extra info can be shown here for tablet view',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            );
          } else {
            // Phone view: normal column
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Search by time or location',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.trim();
                      });
                    },
                  ),
                ),
                Expanded(child: listWidget),
              ],
            );
          }
        },
      ),
    );
  }
}
