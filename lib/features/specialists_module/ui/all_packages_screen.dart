import 'package:flutter/material.dart';
import 'package:car_app/Common/Color.dart';
import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/Common/ShimmerLoader.dart';

class AllPackagesScreen extends StatefulWidget {
  final String vendorId;
  final String vendorName;

  const AllPackagesScreen({
    Key? key,
    required this.vendorId,
    required this.vendorName,
  }) : super(key: key);

  @override
  _AllPackagesScreenState createState() => _AllPackagesScreenState();
}

class _AllPackagesScreenState extends State<AllPackagesScreen> {
  List<Map<String, dynamic>> packages = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    try {
      setState(() {
        isLoading = true;
      });

      // Simulate loading packages
      await Future.delayed(const Duration(seconds: 1));

      // Mock packages data - replace with actual API call
      setState(() {
        packages = [
          {
            'id': '1',
            'name': 'Basic Car Wash Package',
            'description': 'Exterior wash, tire cleaning, and basic interior cleaning',
            'price': 299,
            'duration': '45 minutes',
            'services': ['Exterior Wash', 'Tire Cleaning', 'Interior Vacuum'],
            'image': 'https://via.placeholder.com/300x200',
          },
          {
            'id': '2',
            'name': 'Premium Detailing Package',
            'description': 'Complete exterior and interior detailing with waxing',
            'price': 799,
            'duration': '2 hours',
            'services': ['Exterior Wash', 'Waxing', 'Interior Deep Clean', 'Leather Treatment'],
            'image': 'https://via.placeholder.com/300x200',
          },
          {
            'id': '3',
            'name': 'Luxury Spa Package',
            'description': 'Ultimate car care with ceramic coating and paint protection',
            'price': 1499,
            'duration': '4 hours',
            'services': ['Ceramic Coating', 'Paint Protection', 'Interior Deep Clean', 'Engine Bay Cleaning'],
            'image': 'https://via.placeholder.com/300x200',
          },
        ];
        isLoading = false;
      });
    } catch (e) {
      print('Error loading packages: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: ColorClass.base_color,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          "Packages - ${widget.vendorName}",
          style: const TextStyle(
            color: Colors.white,
            fontFamily: "Pop600",
            fontSize: 18,
          ),
        ),
      ),
      body: isLoading
          ? _buildLoadingState()
          : packages.isEmpty
              ? _buildEmptyState()
              : _buildPackagesList(),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(
          3,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ShimmerLoader.buildSleekShimmer(
              width: double.infinity,
              height: 200,
              borderRadius: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            "No Packages Available",
            style: TextStyle(
              fontSize: 24,
              fontFamily: "Pop600",
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Packages will appear here when available",
            style: TextStyle(
              fontSize: 16,
              fontFamily: "Pop400",
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackagesList() {
    return RefreshIndicator(
      onRefresh: _loadPackages,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: packages.length,
        itemBuilder: (context, index) {
          final package = packages[index];
          return _buildPackageCard(package);
        },
      ),
    );
  }

  Widget _buildPackageCard(Map<String, dynamic> package) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: Container(
              height: 200,
              width: double.infinity,
              color: Colors.grey[200],
              child: Image.network(
                package['image'],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.inventory_2,
                    size: 64,
                    color: ColorClass.base_color,
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  package['name'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontFamily: "Pop600",
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  package['description'],
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: "Pop400",
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      package['duration'],
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: "Pop400",
                        color: Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      "₹${package['price']}",
                      style: TextStyle(
                        fontSize: 20,
                        fontFamily: "Pop600",
                        color: ColorClass.base_color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: (package['services'] as List<String>).map((service) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: ColorClass.base_light_color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        service,
                        style: TextStyle(
                          fontSize: 10,
                          fontFamily: "Pop400",
                          color: ColorClass.base_color,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _bookPackage(package);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorClass.base_color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "Book Package",
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: "Pop500",
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _bookPackage(Map<String, dynamic> package) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Book ${package['name']}"),
        content: Text("This package costs ₹${package['price']} and takes ${package['duration']} to complete."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              CommonWidget.successShowSnackBarFor(context, "Package booking initiated!");
            },
            child: const Text("Book Now"),
          ),
        ],
      ),
    );
  }
}
