import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:location/location.dart';
import /* 'web_location.dart' if(dart.library.html)  */ 'dart:js' as js;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'User Location'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  double? latitude;
  double? longitude;
  bool watching = false;

  final locationService = Location();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Latitude:'),
                Text(
                  latitude != null ? latitude.toString() : '',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Longitude:'),
                Text(
                  longitude != null ? longitude.toString() : '',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    /* final location = await _determinePosition(locationService);
                    print('position is $location');
                    setState(() {
                      latitude = location.latitude;
                      longitude = location.longitude;
                    }); */

                    fetchLocation();
                  },
                  child: const Text('Get Location'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: watching
                      ? null
                      : () async {
                          setState(() {
                            watching = true;
                          });

                          final canAskLocation = await _canAskLocation(
                            locationService,
                          );

                          if (!canAskLocation) {
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Location permissions are denied'),
                              ),
                            );
                            return Future.error(
                              'Location permissions are denied',
                            );
                          }

                          locationService.onLocationChanged
                              .listen((LocationData position) {
                            print('position is $position');
                            setState(() {
                              latitude = position.latitude;
                              longitude = position.longitude;
                            });
                          });
                        },
                  child: const Text('Watch Location'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Function to call JavaScript from Dart
  void fetchLocation() {
    // Define a callback function to handle the location from JavaScript
    js.context['receiveLocationFromJS'] = (position) {
      // Handle the location received from JavaScript
      print('Location from JavaScript: $position');
    };

    // Call the JavaScript function and pass the callback
    js.context.callMethod('getLocation', [js.allowInterop(receiveLocation)]);
  }

  // Callback function to handle the location from JavaScript
  void receiveLocation(js.JsObject position) {
    // Handle the location received from JavaScript
    double latitude = position['coords']['latitude'].toDouble();
    double longitude = position['coords']['longitude'].toDouble();

    print('Latitude: $latitude, Longitude: $longitude');
    setState(() {
      this.latitude = latitude;
      this.longitude = longitude;
    });
  }

  Future<bool> _canAskLocation(Location location) async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return false;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return false;
      }
    }

    return permissionGranted == PermissionStatus.granted ||
        permissionGranted == PermissionStatus.grantedLimited;
  }

  /// Determine the current position of the device.
  ///
  /// When the location services are not enabled or permissions
  /// are denied the `Future` will return an error.
  Future<LocationData> _determinePosition(Location location) async {
    final canAskLocation = await _canAskLocation(location);

    if (!canAskLocation) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location permissions are denied'),
        ),
      );
      return Future.error('Location permissions are denied');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await location.getLocation();
  }
}
