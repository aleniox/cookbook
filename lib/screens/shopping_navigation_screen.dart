import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as Math;
import 'dart:io' show Platform;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import '../models/recipe.dart';
import '../models/ingredient_item.dart';

class Shop {
  final String name;
  final double distance;
  final String type;
  final double lat;
  final double lon;

  Shop({
    required this.name,
    required this.distance,
    required this.type,
    required this.lat,
    required this.lon,
  });

  static double calcDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371;
    final dLat = (lat2 - lat1) * Math.pi / 180;
    final dLon = (lon2 - lon1) * Math.pi / 180;
    final a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(lat1 * Math.pi / 180) *
            Math.cos(lat2 * Math.pi / 180) *
            Math.sin(dLon / 2) *
            Math.sin(dLon / 2);
    return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  }
}

class ShoppingNavigationScreen extends StatefulWidget {
  final List<Recipe> recipes;

  const ShoppingNavigationScreen({super.key, required this.recipes});

  @override
  State<ShoppingNavigationScreen> createState() =>
      _ShoppingNavigationScreenState();
}

class _ShoppingNavigationScreenState extends State<ShoppingNavigationScreen> {
  late List<IngredientItem> items;
  late List<Shop> shops;
  bool loading = true;
  String? error;
  String city = 'Hà Nội';
  double? currentLat;
  double? currentLon;
  late GoogleMapController mapController;
  Map<MarkerId, Marker> markers = {};
  late bool isDesktop;
  final location = Location();

  final cities = {
    'Hà Nội': (21.0285, 105.8542),
    'TP.HCM': (10.7769, 106.7009),
    'Đà Nẵng': (16.0473, 108.2068),
    'Hải Phòng': (20.8449, 106.6881),
    'Cần Thơ': (10.0282, 105.7808),
  };

  @override
  void initState() {
    super.initState();
    items = widget.recipes
        .expand((r) => r.ingredients)
        .toList()
        .where((item) => item.name.isNotEmpty)
        .toList();
    isDesktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;
    if (isDesktop) {
      load();
    } else {
      _getCurrentLocation();
    }
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    if (isDesktop) {
      load();
      return;
    }
    try {
      final hasPermission = await location.hasPermission();
      if (hasPermission == PermissionStatus.denied) {
        final permission = await location.requestPermission();
        if (permission != PermissionStatus.granted) {
          if (mounted) {
            setState(() {
              error = 'Cấp quyền truy cập vị trí để tìm cửa hàng gần đây';
              loading = false;
            });
          }
          return;
        }
      }
      final userLocation = await location.getLocation();
      setState(() {
        currentLat = userLocation.latitude;
        currentLon = userLocation.longitude;
      });
      if (currentLat != null && currentLon != null) {
        await load();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = 'Lỗi lấy vị trí: $e';
          loading = false;
        });
      }
    }
  }

  Future<void> load() async {
    try {
      final lat = currentLat ?? cities[city]?.$1 ?? 21.0285;
      final lon = currentLon ?? cities[city]?.$2 ?? 105.8542;
      final result = <Shop>[];
      final newMarkers = <MarkerId, Marker>{};

      // Marker vị trí hiện tại (xanh)
      newMarkers[MarkerId('current')] = Marker(
        markerId: MarkerId('current'),
        position: LatLng(lat, lon),
        infoWindow: const InfoWindow(title: 'Vị trí của bạn'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      );

      for (String q in ['supermarket', 'market', 'shop']) {
        final res = await http
            .get(Uri.parse(
                'https://nominatim.openstreetmap.org/search?q=$q&lat=$lat&lon=$lon&format=json&limit=5'))
            .timeout(const Duration(seconds: 15));

        if (res.statusCode == 200) {
          final data = json.decode(res.body) as List;
          for (var item in data) {
            final d = Shop.calcDistance(lat, lon, double.parse(item['lat'].toString()),
                double.parse(item['lon'].toString()));
            if (d <= 10) {
              result.add(Shop(
                name: item['name'] ?? 'Cửa hàng',
                distance: d,
                type: item['type'].toString().contains('super') ? 'Siêu thị' : 'Cửa hàng',
                lat: double.parse(item['lat'].toString()),
                lon: double.parse(item['lon'].toString()),
              ));
            }
          }
        }
      }

      result.sort((a, b) => a.distance.compareTo(b.distance));

      // Thêm markers cho cửa hàng (đỏ)
      for (var shop in result) {
        newMarkers[MarkerId(shop.name)] = Marker(
          markerId: MarkerId(shop.name),
          position: LatLng(shop.lat, shop.lon),
          infoWindow: InfoWindow(
            title: shop.name,
            snippet: '${shop.distance.toStringAsFixed(1)} km',
          ),
        );
      }

      if (mounted) {
        setState(() {
          shops = result.take(10).toList();
          markers = newMarkers;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = 'Lỗi: $e';
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tìm đường mua sắm')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(isDesktop ? 'Đang tìm cửa hàng...' : 'Đang lấy vị trí hiện tại...'),
              const SizedBox(height: 8),
              Text(
                isDesktop ? 'Vui lòng chọn thành phố' : 'Vui lòng cho phép truy cập vị trí',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  setState(() {
                    loading = true;
                    error = null;
                  });
                  _getCurrentLocation();
                },
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tìm đường mua sắm')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(error!),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  setState(() {
                    loading = true;
                    error = null;
                  });
                  _getCurrentLocation();
                },
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final lat = currentLat ?? cities[city]?.$1 ?? 21.0285;
    final lon = currentLon ?? cities[city]?.$2 ?? 105.8542;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tìm đường mua sắm'),
        actions: [
          if (isDesktop)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: DropdownButton<String>(
                value: city,
                dropdownColor: Colors.blue[700],
                icon: const Icon(Icons.location_city, color: Colors.white),
                items: cities.keys
                    .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c, style: const TextStyle(color: Colors.white))))
                    .toList(),
                onChanged: (c) {
                  if (c != null && c != city) {
                    setState(() {
                      city = c;
                      loading = true;
                      error = null;
                    });
                    load();
                  }
                },
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                loading = true;
                error = null;
              });
              _getCurrentLocation();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            onMapCreated: (controller) {
              mapController = controller;
            },
            initialCameraPosition: CameraPosition(
              target: LatLng(lat, lon),
              zoom: 14,
            ),
            markers: markers.values.toSet(),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),

          // Bottom sheet với nguyên liệu và cửa hàng
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Nguyên liệu (${items.length})',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Wrap(
                      spacing: 6,
                      children: items.take(4).map((item) {
                        return Chip(
                          label: Text(item.name, style: const TextStyle(fontSize: 11)),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                  ),
                  if (items.length > 4)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: Text(
                        '...và ${items.length - 4} nguyên liệu khác',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // Danh sách cửa hàng (horizontal scroll)
          Positioned(
            bottom: 200,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 120,
              child: shops.isEmpty
                  ? const Center(child: Text('Không tìm thấy cửa hàng'))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.all(8),
                      itemCount: shops.length,
                      itemBuilder: (context, index) {
                        final shop = shops[index];
                        return Card(
                          margin: const EdgeInsets.only(right: 8),
                          child: Container(
                            width: 180,
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  shop.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${shop.distance.toStringAsFixed(1)} km',
                                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                                Text(
                                  shop.type,
                                  style: const TextStyle(fontSize: 10, color: Colors.blue),
                                ),
                                const Spacer(),
                                SizedBox(
                                  width: double.infinity,
                                  height: 32,
                                  child: FilledButton.icon(
                                    onPressed: () async {
                                      final uri = Uri.parse(
                                          'https://www.google.com/maps/search/?api=1&query=${shop.lat},${shop.lon}');
                                      if (await canLaunchUrl(uri)) await launchUrl(uri);
                                    },
                                    icon: const Icon(Icons.map, size: 14),
                                    label: const Text('Chỉ đường', style: TextStyle(fontSize: 11)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
