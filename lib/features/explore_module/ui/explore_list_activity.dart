import 'dart:convert';
import 'package:car_app/Common/Color.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Common/CommonWidget.dart';
import '../../bookmark_model/ui/bookmark_activity.dart';
import '../../categories_module/model/services_post_bean.dart';
import '../../home_module/model/services_model_data.dart';
import '../../specialists_module/ui/specialists_activity.dart';
import '../data_manager/explore_list_data_manager.dart';

class ExploreListActivity extends StatefulWidget {
  const ExploreListActivity({super.key});

  @override
  State<ExploreListActivity> createState() => _ExploreListActivityState();
}

class _ExploreListActivityState extends State<ExploreListActivity> {
  List<ServicesData> servicesData = [];
  ExploreListDataManager? dataManager;
  SharedPreferences? sharedPreferences;

  String selectedCategory = 'All';
  List<String> categories = ['All'];
  String searchTerm = '';
  final TextEditingController _searchController = TextEditingController();

  // Pagination & Distance states
  final ScrollController _scrollController = ScrollController();
  int _pageNumber = 1;
  bool _isLoading = false;
  bool _isLastPage = false;
  final int _pageSize = 20;
  int _currentDistance = 30000; // Start with 30km
  final int _maxDistanceLimit = 150000; // Limit to 150km

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    start();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.95 &&
        !_isLoading) {
      if (!_isLastPage) {
        getVendors(context, isLoadMore: true);
      } else if (_currentDistance < _maxDistanceLimit) {
        // Results ended, but we can expand distance
        debugPrint("🔄 Auto-expanding distance from ${_currentDistance/1000}km...");
        getVendors(context, isLoadMore: true, isExpandingDistance: true);
      }
    }
  }

  start() async {
    sharedPreferences = await SharedPreferences.getInstance();
    dataManager = ExploreListDataManager(sharedPreferences!);
    await loadCategories();
    _currentDistance = 30000;
    getVendors(context);
  }

  Future<void> loadCategories() async {
    try {
      var response = await dataManager!.getCategories(context);
      var data = jsonDecode(response.body);
      if (data['status'] == 'success' && data['data'] != null) {
        setState(() {
          categories = ['All'];
          for (var category in data['data']) {
            if (category['categoryTitle'] != null && category['isActive'] == true) {
              categories.add(category['categoryTitle']);
            }
          }
        });
      }
    } catch (e) {
      debugPrint("Error loading categories: $e");
    }
  }

  getVendors(BuildContext context, {bool isLoadMore = false, bool isExpandingDistance = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      if (!isLoadMore) {
        _pageNumber = 1;
        _isLastPage = false;
        _currentDistance = 30000;
      }
      if (isExpandingDistance) {
        _currentDistance += 20000; // Add 20km
        _isLastPage = false;
        _pageNumber = 1;
      }
    });

    try {
      debugPrint("🔵 Explore List: Fetching page $_pageNumber for category $selectedCategory at ${_currentDistance/1000}km");
      var response = await dataManager!.getAllVendors(
        context, 
        pageNumber: _pageNumber, 
        count: _pageSize,
        category: selectedCategory,
        searchTerm: searchTerm.isNotEmpty ? searchTerm : null,
        maxDistance: _currentDistance,
      );
      
      var data = ServicesModelData.fromJson(jsonDecode(response.body));

      if (data.status == "success") {
        setState(() {
          if (!isLoadMore) {
            servicesData.clear();
          }
          
          if (data.data != null && data.data!.isNotEmpty) {
            servicesData.addAll(data.data!);
            _pageNumber++;
            
            if (data.data!.length < _pageSize) {
              _isLastPage = true;
              debugPrint("🛑 Explore List: Last page reached at ${_currentDistance/1000}km");
              
              // If we reached last page and have very few results, expand immediately
              if (servicesData.length < 5 && _currentDistance < _maxDistanceLimit) {
                _isLoading = false; 
                getVendors(context, isLoadMore: true, isExpandingDistance: true);
                return;
              }
            }
          } else {
            _isLastPage = true;
            debugPrint("🛑 Explore List: No more items at ${_currentDistance/1000}km");
            
            // If we reached the end, expand immediately to avoid user needing to scroll again
            if (_currentDistance < _maxDistanceLimit) {
              _isLoading = false; 
              getVendors(context, isLoadMore: true, isExpandingDistance: true);
              return;
            }
          }
          _isLoading = false;
        });
        
        // If results are still empty and we can expand, try again automatically once
        if (servicesData.isEmpty && _currentDistance < _maxDistanceLimit && !isExpandingDistance) {
           getVendors(context, isLoadMore: true, isExpandingDistance: true);
        }
      } else {
        setState(() => _isLoading = false);
        CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error fetching vendors: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF166534), Color(0xFF1CB273), Color(0xFF00E676)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            padding: const EdgeInsets.only(top: 45, bottom: 10),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CommonWidget.buildGreenHeaderBackButton(context),
                      Expanded(child: CommonWidget.getTextWidget500("Explore Nearby", color: Colors.white, size: 18)),
                      InkWell(
                        onTap: () {
                          CommonWidget.navigateToScreen(context, const BookmarkActivity());
                        },
                        child: Image.asset(
                          CommonWidget.getImagePath("bookmark.png"),
                          height: 35,
                          width: 35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                // Search Bar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 15),
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        searchTerm = value;
                      });
                      getVendors(context);
                    },
                    decoration: InputDecoration(
                      hintText: "Search vendors or services...",
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                      border: InputBorder.none,
                      icon: Icon(Icons.search, color: ColorClass.base_color, size: 20),
                      suffixIcon: searchTerm.isNotEmpty 
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                searchTerm = '';
                              });
                              getVendors(context);
                            },
                          )
                        : null,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          
          // Categories Horizontal List
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                bool isSelected = selectedCategory == categories[index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCategory = categories[index];
                    });
                    getVendors(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                    decoration: BoxDecoration(
                      color: isSelected ? ColorClass.base_color : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? ColorClass.base_color : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        categories[index],
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          Expanded(
            child: Container(
              margin: const EdgeInsets.all(12),
              child: RefreshIndicator(
                onRefresh: () async {
                  if (mounted) {
                    await getVendors(context);
                  }
                },
                child: Column(
                  children: [
                    if (_currentDistance > 30000 && servicesData.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          "Showing results up to ${_currentDistance / 1000}km",
                          style: TextStyle(fontSize: 11, color: Colors.grey[500], fontStyle: FontStyle.italic),
                        ),
                      ),
                    Expanded(
                      child: servicesData.isEmpty && !_isLoading
                          ? Center(child: Text("No vendors found", style: TextStyle(color: Colors.grey[600])))
                          : ListView.builder(
                              controller: _scrollController,
                              padding: EdgeInsets.zero,
                              itemCount: servicesData.length + (_isLoading ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == servicesData.length) {
                                  return Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        children: [
                                          const CircularProgressIndicator(),
                                          if (_isLastPage && _currentDistance < _maxDistanceLimit)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 8.0),
                                              child: Text("Searching further...", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                                
                                final vendor = servicesData[index];
                                final isAppVendor = (vendor.isAppVendor == true) || (vendor.category?.toLowerCase() != "google places");
                                final isOffline = isAppVendor && !(vendor.isShopOpen ?? true);
                                
                                return GestureDetector(
                                    onTap: () {
                                      CommonWidget.navigateToScreen(context, SpecialistsActivity(vendor.sId ?? ''));
                                    },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isOffline ? Colors.grey[50] : Colors.white,
                                      borderRadius: BorderRadius.circular(15),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: _buildVendorImage(vendor, isOffline),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      vendor.displayName ?? "",
                                                      style: TextStyle(
                                                        fontSize: 15,
                                                        fontWeight: FontWeight.bold,
                                                        color: isOffline ? Colors.grey[600] : Colors.black87,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  if (isOffline)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: Colors.red[50],
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text("OFFLINE", style: TextStyle(color: Colors.red[700], fontSize: 9, fontWeight: FontWeight.bold)),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(Icons.location_on, size: 12, color: isOffline ? Colors.grey[400] : Colors.red[300]),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      vendor.location?.name ?? "Distance: ${vendor.distance?.toStringAsFixed(1) ?? '0.0'} km",
                                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  Icon(Icons.star, size: 14, color: Colors.amber[600]),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    vendor.averageRating?.toStringAsFixed(1) ?? "4.5",
                                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    width: 4,
                                                    height: 4,
                                                    decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    !isAppVendor ? "Google Places" : "App Vendor",
                                                    style: TextStyle(fontSize: 11, color: isAppVendor ? ColorClass.base_color : Colors.blue[700], fontWeight: FontWeight.w500),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  postBookmark(BuildContext context, String id) async {
    var response = await dataManager!.postBookmark(context, id);
    var data = ServicesPostBean.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      CommonWidget.successShowSnackBarFor(context, data.message ?? "");
      getVendors(context);
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }

  removeBookmark(BuildContext context, String id) async {
    var response = await dataManager!.removeBookmark(context, id);
    var data = ServicesPostBean.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      CommonWidget.successShowSnackBarFor(context, data.message ?? "");
      getVendors(context);
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }

  void _showOfflineMessage(BuildContext context) {
    CommonWidget.errorShowSnackBarFor(context, "This vendor is currently offline and not accepting bookings");
  }

  Widget _buildVendorImage(ServicesData vendor, bool isOffline) {
    String? imageUrl = vendor.displayPicture;
    if ((imageUrl == null || imageUrl.isEmpty) && vendor.services.isNotEmpty) {
      imageUrl = vendor.services.first.coverImage;
    }

    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: imageUrl != null && imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              width: 90,
              height: 90,
              fit: BoxFit.cover,
              color: isOffline ? Colors.grey : null,
              colorBlendMode: isOffline ? BlendMode.saturation : null,
              errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(isOffline),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    strokeWidth: 2,
                  ),
                );
              },
            )
          : _buildPlaceholderImage(isOffline),
    );
  }

  Widget _buildPlaceholderImage(bool isOffline) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: isOffline ? Colors.grey[200] : ColorClass.base_color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.store,
        size: 35,
        color: isOffline ? Colors.grey[400] : ColorClass.base_color,
      ),
    );
  }
}
