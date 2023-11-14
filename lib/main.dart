import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:location/location.dart' as l;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

enum LocationOption { js, location, geoLocator }

enum LocationAccuracy { high, low }

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
  bool checkPermission = true;
  bool fetchingLocation = false;
  LocationOption locationOption = LocationOption.js;
  LocationAccuracy locationAccuracy = LocationAccuracy.high;

  final locationService = l.Location();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Stack(
        children: [
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Flexible(child: SizedBox(width: 128)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Check permission: '),
                        const SizedBox(width: 20),
                        Switch(
                          value: checkPermission,
                          onChanged: (value) {
                            setState(() {
                              checkPermission = value;
                            });
                          },
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Location option: '),
                        const SizedBox(width: 20),
                        DropdownButton<LocationOption>(
                          value: locationOption,
                          onChanged: (LocationOption? newValue) {
                            setState(() {
                              if (newValue != null) {
                                locationOption = newValue;
                              }
                            });
                          },
                          items: LocationOption.values
                              .map<DropdownMenuItem<LocationOption>>((value) {
                            return DropdownMenuItem<LocationOption>(
                              value: value,
                              child: Text(value.name.toUpperCase()),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Location accuracy: '),
                        const SizedBox(width: 20),
                        DropdownButton<LocationAccuracy>(
                          value: locationAccuracy,
                          onChanged: (LocationAccuracy? newValue) {
                            setState(() {
                              if (newValue != null) {
                                locationAccuracy = newValue;
                              }
                            });
                          },
                          items: LocationAccuracy.values
                              .map<DropdownMenuItem<LocationAccuracy>>((value) {
                            return DropdownMenuItem<LocationAccuracy>(
                              value: value,
                              child: Text(value.name.toUpperCase()),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                          onPressed: () {
                            print(locationOption);
                            switch (locationOption) {
                              case LocationOption.js:
                                fetchLocationJS();
                                break;
                              case LocationOption.location:
                                fetchLocationLocation(
                                  accuracy: locationAccuracy,
                                  checkPermission: checkPermission,
                                );
                                break;
                              case LocationOption.geoLocator:
                                fetchLocationGeoLocator(
                                  accuracy: locationAccuracy,
                                  checkPermission: checkPermission,
                                );
                                break;
                            }
                          },
                          child: const Text('Get Location'),
                        ),
                        const SizedBox(width: 20),
                        ElevatedButton(
                          onPressed: watching
                              ? null
                              : () {
                                  switch (locationOption) {
                                    case LocationOption.js:
                                      break;
                                    case LocationOption.location:
                                      watchLocationLocation(locationAccuracy);
                                      break;
                                    case LocationOption.geoLocator:
                                      watchLocationGeoLocator(locationAccuracy);
                                      break;
                                  }
                                },
                          child: const Text('Watch Location'),
                        ),
                      ],
                    ),
                  ],
                ),
                const Flexible(child: SizedBox(width: 128)),
              ],
            ),
          ),
          if (fetchingLocation)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          if (fetchingLocation)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Future<void> fetchLocationLocation({
    required LocationAccuracy accuracy,
    required bool checkPermission,
  }) async {
    gl.LocationPermission permission;

    if (checkPermission) {
      permission = await gl.Geolocator.checkPermission();
      if (permission == gl.LocationPermission.denied) {
        permission = await gl.Geolocator.requestPermission();
        if (permission == gl.LocationPermission.denied) {
          // Permissions are denied, next time you could try
          // requesting permissions again (this is also where
          // Android's shouldShowRequestPermissionRationale
          // returned true. According to Android guidelines
          // your App should show an explanatory UI now.
          return Future.error('Location permissions are denied');
        }
      }

      if (permission == gl.LocationPermission.deniedForever) {
        // Permissions are denied forever, handle appropriately.
        return Future.error(
            'Location permissions are permanently denied, we cannot request permissions.');
      }
    }

    setState(() {
      fetchingLocation = true;
    });

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    final location = await locationService.getLocation();
    print('LOC - Location is ${location.latitude} ${location.longitude}');
    setState(() {
      latitude = location.latitude;
      longitude = location.longitude;
      fetchingLocation = false;
    });
  }

  Future<void> fetchLocationGeoLocator({
    required LocationAccuracy accuracy,
    required bool checkPermission,
  }) async {
    try {
      if (checkPermission) {
        l.PermissionStatus permissionGranted;

        permissionGranted = await locationService.hasPermission();
        if (permissionGranted == l.PermissionStatus.denied) {
          permissionGranted = await locationService.requestPermission();
          if (permissionGranted != l.PermissionStatus.granted) {
            return;
          }
        }
      }

      setState(() {
        fetchingLocation = true;
      });

      final location = await gl.Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy == LocationAccuracy.high
            ? gl.LocationAccuracy.best
            : gl.LocationAccuracy.low,
        timeLimit: const Duration(seconds: 1200),
      );
      print('GEO - Location is ${location.latitude} ${location.longitude}');
      setState(() {
        latitude = location.latitude;
        longitude = location.longitude;
        fetchingLocation = false;
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> watchLocationLocation(LocationAccuracy accuracy) async {
    setState(() {
      watching = true;
    });

    await locationService.changeSettings(
      accuracy: accuracy == LocationAccuracy.high
          ? l.LocationAccuracy.high
          : l.LocationAccuracy.low,
    );

    locationService.onLocationChanged.listen((l.LocationData position) {
      print('position is $position');
      setState(() {
        latitude = position.latitude;
        longitude = position.longitude;
      });
    });
  }

  void watchLocationGeoLocator(LocationAccuracy accuracy) async {
    setState(() {
      watching = true;
    });

    gl.Geolocator.getPositionStream(
            locationSettings: gl.LocationSettings(
                accuracy: accuracy == LocationAccuracy.high
                    ? gl.LocationAccuracy.high
                    : gl.LocationAccuracy.low,
                timeLimit: const Duration(seconds: 1200)))
        .listen((gl.Position position) {
      print('position is $position');
      setState(() {
        latitude = position.latitude;
        longitude = position.longitude;
      });
    });
  }

  // Function to call JavaScript from Dart
  void fetchLocationJS() {
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

    print('JS - Latitude: $latitude, Longitude: $longitude');
    setState(() {
      this.latitude = latitude;
      this.longitude = longitude;
    });
  }
}
