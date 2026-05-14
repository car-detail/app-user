import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:car_app/Common/Color.dart';
import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/features/specialists_module/ui/specialists_activity.dart';
import 'package:car_app/features/home_module/data_manager/home_data_manager.dart';
import 'package:car_app/features/home_module/model/mixed_vendor_data.dart';
import 'package:car_app/Common/ShimmerLoader.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:car_app/Common/Constant.dart';
import 'package:geolocator/geolocator.dart';

class AllVendorsScreen extends StatefulWidget {
  const AllVendorsScreen({super.key});

  @override
  _AllVendorsScreenState createState() => _AllVendorsScreenState();
}

class _AllVendorsScreenState extends State<AllVendorsScreen> {
  HomeDataManager? dataManager;
  List<MixedVendorData> vendors = [];
  bool isLoading = true;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Pagination & Distance states
  int _pageNumber = 1;
  bool _isLoadingMore = false;
  bool _isLastPage = false;
  final int _pageSize = 20;
  int _currentDistance = 30000;
  final int _maxDistanceLimit = 150000;

  // Debounce search so shimmer is visible and we don't fire an API per keystroke
  Timer? _searchDebounce;


  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initializeDataManager();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.95 &&
        !isLoading &&
        !_isLoadingMore &&
        searchQuery.isEmpty) {
      if (!_isLastPage) {
        _loadVendors(isLoadMore: true);
      } else if (_currentDistance < _maxDistanceLimit) {
        debugPrint("🔄 Auto-expanding distance on All Vendors...");
        _loadVendors(isLoadMore: true, isExpandingDistance: true);
      }
    }
  }


  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }


  Future<void> _initializeDataManager() async {
    final prefs = await SharedPreferences.getInstance();
    dataManager = HomeDataManager(prefs);
    await _ensureLocationAvailable(prefs);
    await _loadVendors();
  }

  Future<void> _ensureLocationAvailable(SharedPreferences prefs) async {
    final lat = prefs.getString(Constant.lat);
    if (lat != null && lat != "null" && lat != "0.0" && lat.isNotEmpty) return;
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return;
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      await prefs.setString(Constant.lat, position.latitude.toString());
      await prefs.setString(Constant.long, position.longitude.toString());
    } catch (_) {}
  }

  Future<void> _loadVendors({bool isLoadMore = false, bool isExpandingDistance = false}) async {
    if (!isLoadMore && isLoading && vendors.isNotEmpty) return; // Prevent double load on init/refresh

    try {
      setState(() {
        if (isLoadMore) {
          _isLoadingMore = true;
          if (isExpandingDistance) {
            _currentDistance += 20000;
            _isLastPage = false;
            _pageNumber = 1;
          }
        } else {
          isLoading = true;
          _pageNumber = 1;
          _isLastPage = false;
          _currentDistance = 30000;
          vendors.clear();
        }
      });

      debugPrint("🔵 Fetching all vendors page $_pageNumber at ${_currentDistance/1000}km");
      final vendorsList = await dataManager!.getMixedVendors(
        context, 
        pageNumber: _pageNumber, 
        count: _pageSize,
        maxDistance: _currentDistance,
      );
      
      debugPrint("🟢 Received ${vendorsList.length} vendors for page $_pageNumber");

      setState(() {
        if (vendorsList.isNotEmpty) {
          for (final v in vendorsList) {
            if (!vendors.any((existing) => existing.id == v.id)) {
              vendors.add(v);
            }
          }
          _pageNumber++;
          if (vendorsList.length < _pageSize) {
            _isLastPage = true;
            debugPrint("🛑 AllVendors: Last page reached at ${_currentDistance/1000}km");
            
            // Proactively expand if few results found
            if (vendors.length < 5 && _currentDistance < _maxDistanceLimit) {
              _isLoadingMore = false;
              _loadVendors(isLoadMore: true, isExpandingDistance: true);
              return;
            }
          }
        } else {
          _isLastPage = true;
          debugPrint("🛑 AllVendors: No more items at ${_currentDistance/1000}km");
          
          // Trigger immediate expansion if empty page reached
          if (_currentDistance < _maxDistanceLimit) {
            _isLoadingMore = false;
            _loadVendors(isLoadMore: true, isExpandingDistance: true);
            return;
          }
        }
        isLoading = false;
        _isLoadingMore = false;
      });

      // Auto-expand if empty on first load
      if (vendors.isEmpty && !isLoadMore && _currentDistance < _maxDistanceLimit) {
        _loadVendors(isLoadMore: true, isExpandingDistance: true);
      }
    } catch (e) {
      debugPrint("🔴 Error loading vendors: $e");
      setState(() {
        isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _searchVendors(String query) async {
    if (query.isEmpty) {
      await _loadVendors();
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      final searchResults = await dataManager!.searchVendors(context, query);
      setState(() {
        vendors = searchResults;
        isLoading = false;
      });
    } catch (e) {
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF166534), Color(0xFF1CB273), Color(0xFF00E676)],
            ),
          ),
        ),
        leading: CommonWidget.buildGreenHeaderBackButton(context),
        title: const Text(
          "All Vendors",
          style: TextStyle(
            color: Colors.white,
            fontFamily: "Pop600",
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                _searchDebounce?.cancel();
                setState(() {
                  searchQuery = value;
                  // Show shimmer immediately so the user sees feedback
                  isLoading = true;
                });
                _searchDebounce = Timer(const Duration(milliseconds: 500), () {
                  _searchVendors(value);
                });
              },
              decoration: InputDecoration(
                hintText: "Search vendors...",
                hintStyle: TextStyle(
                  fontFamily: "Pop400",
                  color: Colors.grey[600],
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: ColorClass.base_color,
                ),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            searchQuery = '';
                          });
                          _loadVendors();
                        },
                        icon: const Icon(Icons.clear, color: Colors.grey),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ),
      ),
      body: isLoading
          ? _buildLoadingState()
          : vendors.isEmpty
              ? _buildEmptyState()
              : _buildVendorsList(),
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
              height: 120,
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
            Icons.location_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            searchQuery.isNotEmpty ? "No vendors found" : "No vendors available",
            style: TextStyle(
              fontSize: 24,
              fontFamily: "Pop600",
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            searchQuery.isNotEmpty
                ? "Try a different search term"
                : "Searching within ${_currentDistance/1000}km...",
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

  Widget _buildVendorsList() {
    return RefreshIndicator(
      onRefresh: _loadVendors,
      child: Column(
        children: [
          if (_currentDistance > 30000 && searchQuery.isEmpty)
             Padding(
               padding: const EdgeInsets.symmetric(vertical: 8.0),
               child: Text("Showing results up to ${_currentDistance / 1000}km", 
               style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic)),
             ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: vendors.length + (_isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == vendors.length) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          const CircularProgressIndicator(),
                          if (_isLastPage && _currentDistance < _maxDistanceLimit)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text("Expanding search radius...", 
                              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            ),
                        ],
                      ),
                    ),
                  );
                }
                final vendor = vendors[index];
                return _buildVendorCard(vendor);
              },
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildVendorCard(MixedVendorData vendor) {
    return GestureDetector(
      onTap: () {
        if (vendor.isAppVendor) {
          CommonWidget.navigateToScreen(
            context,
            SpecialistsActivity(vendor.id),
          );
        } else {
          _handleGoogleVendorTap(vendor);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: vendor.isOpen ? Colors.white : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: vendor.isOpen 
                  ? Colors.black.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.05),
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
              child: vendor.imageUrl != null && vendor.imageUrl!.isNotEmpty
                  ? Image.network(
                      vendor.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          vendor.isAppVendor ? Icons.local_car_wash : Icons.location_on,
                          size: 64,
                          color: vendor.isAppVendor ? ColorClass.base_color : Colors.blue,
                        );
                      },
                    )
                  : Icon(
                      vendor.isAppVendor ? Icons.local_car_wash : Icons.location_on,
                      size: 64,
                      color: vendor.isAppVendor ? ColorClass.base_color : Colors.blue,
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        vendor.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontFamily: "Pop600",
                          color: vendor.isOpen ? Colors.black87 : Colors.grey[500],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: vendor.isOpen ? Colors.green[100] : Colors.red[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        vendor.isOpen ? "OPEN NOW" : "CLOSED",
                        style: TextStyle(
                          fontSize: 10,
                          fontFamily: "Pop600",
                          color: vendor.isOpen ? Colors.green[700] : Colors.red[700],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  vendor.address ?? "Address not available",
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: "Pop400",
                    color: vendor.isOpen ? Colors.grey[600] : Colors.grey[400],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      size: 18,
                      color: Colors.amber[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      vendor.rating?.toStringAsFixed(1) ?? "0.0",
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: "Pop500",
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      "${(vendor.distance * 0.000621371).toStringAsFixed(1)} miles",
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: "Pop600",
                        color: vendor.isAppVendor ? ColorClass.base_color : Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: ColorClass.base_color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              vendor.isAppVendor ? Icons.visibility : Icons.map,
                              size: 18,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              vendor.isAppVendor ? "View Details" : "Open in Maps",
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: "Pop500",
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (vendor.isAppVendor) ...[
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          _toggleBookmark(vendor);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            vendor.isBookmarked == true ? Icons.bookmark : Icons.bookmark_border,
                            color: vendor.isBookmarked == true ? ColorClass.base_color : Colors.grey[600],
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  void _handleGoogleVendorTap(MixedVendorData vendor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Google Places Vendor"),
        content: const Text("This is a Google Places vendor. Would you like to open it in Maps?"),
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
              _openInMaps(vendor);
            },
            child: const Text("Open in Maps"),
          ),
        ],
      ),
    );
  }

  void _openInMaps(MixedVendorData vendor) {
    final lat = vendor.latitude;
    final lng = vendor.longitude;
    final name = Uri.encodeComponent(vendor.name);
    final url = "https://www.google.com/maps/search/?api=1&query=$lat,$lng&query_place_id=$name";
    CommonWidget.successShowSnackBarFor(context, "Opening in Maps...");
  }

  Future<void> _toggleBookmark(MixedVendorData vendor) async {
    setState(() {
      vendor.isBookmarked = !vendor.isBookmarked;
    });
    CommonWidget.successShowSnackBarFor(
      context, 
      vendor.isBookmarked ? "Added to bookmarks" : "Removed from bookmarks"
    );
  }
}
