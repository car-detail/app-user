import 'package:flutter/material.dart';
import 'package:car_app/Common/Color.dart';
import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/features/home_module/model/mixed_vendor_data.dart';
import 'package:car_app/features/specialists_module/ui/specialists_activity.dart';

class SearchResultsScreen extends StatefulWidget {
  final String searchQuery;
  final List<MixedVendorData> searchResults;

  const SearchResultsScreen({
    super.key,
    required this.searchQuery,
    required this.searchResults,
  });

  @override
  _SearchResultsScreenState createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 48,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF166534), Color(0xFF1CB273), Color(0xFF00E676)],
            ),
          ),
        ),
        leading: CommonWidget.buildAppBarBackButton(
          context,
          backgroundColor: Colors.white.withOpacity(0.2),
          iconColor: Colors.white,
        ),
        title: const Text(
          "Search Results",
          style: TextStyle(
            color: Colors.white,
            fontFamily: "Pop600",
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF166534),
                  Color(0xFF1CB273),
                  Color(0xFF00E676),
                ],
              ),
            ),
            padding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
            child: Text(
              "Found ${widget.searchResults.length} results for \"${widget.searchQuery}\"",
              style: const TextStyle(
                color: Colors.white70,
                fontFamily: "Pop400",
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: widget.searchResults.isEmpty
                ? _buildNoResultsState()
                : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            "No results found",
            style: TextStyle(
              fontSize: 24,
              fontFamily: "Pop600",
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "No vendors found for \"${widget.searchQuery}\"\nTry a different search term",
            style: TextStyle(
              fontSize: 16,
              fontFamily: "Pop400",
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text("Go Back"),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorClass.base_color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.searchResults.length,
      itemBuilder: (context, index) {
        final vendor = widget.searchResults[index];
        return _buildVendorCard(vendor);
      },
    );
  }

  Widget _buildVendorCard(MixedVendorData vendor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: vendor.isOpen ? Colors.white : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: vendor.isOpen ? null : Border.all(color: Colors.grey[300]!),
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
                          color: vendor.isOpen ? Colors.black87 : Colors.grey[600],
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
                    color: Colors.grey[600],
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
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (vendor.isAppVendor) {
                            CommonWidget.navigateToScreen(
                              context,
                              SpecialistsActivity(vendor.id),
                            );
                          } else {
                            _handleGoogleVendorTap(vendor);
                          }
                        },
                        icon: Icon(
                          vendor.isAppVendor ? Icons.visibility : Icons.map,
                          size: 18,
                        ),
                        label: Text(
                          vendor.isAppVendor ? "View Details" : "Open in Maps",
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorClass.base_color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    if (vendor.isAppVendor) ...[
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () {
                          _toggleBookmark(vendor);
                        },
                        icon: Icon(
                          vendor.isBookmarked == true ? Icons.bookmark : Icons.bookmark_border,
                          color: vendor.isBookmarked == true ? ColorClass.base_color : Colors.grey[600],
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
    // Open the vendor location in Google Maps
    final lat = vendor.latitude;
    final lng = vendor.longitude;
    final name = Uri.encodeComponent(vendor.name);
    
    final url = "https://www.google.com/maps/search/?api=1&query=$lat,$lng&query_place_id=$name";
    
    // You can use url_launcher here if available
    // launchUrl(Uri.parse(url));
    
    // For now, show a message
    CommonWidget.successShowSnackBarFor(context, "Opening in Maps...");
  }

  Future<void> _toggleBookmark(MixedVendorData vendor) async {
    // Implement bookmark functionality here
    setState(() {
      vendor.isBookmarked = !vendor.isBookmarked;
    });
    
    CommonWidget.successShowSnackBarFor(
      context, 
      vendor.isBookmarked ? "Added to bookmarks" : "Removed from bookmarks"
    );
  }

  void _showOfflineMessage(BuildContext context) {
    CommonWidget.errorShowSnackBarFor(context, "This vendor is currently offline and not accepting bookings");
  }
}
