import 'package:flutter/material.dart';
import 'package:car_app/Common/Color.dart';
import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/Common/ShimmerLoader.dart';

class AllOffersScreen extends StatefulWidget {
  final String vendorId;
  final String vendorName;
  final List<Map<String, dynamic>> offers;

  const AllOffersScreen({
    Key? key,
    required this.vendorId,
    required this.vendorName,
    required this.offers,
  }) : super(key: key);

  @override
  _AllOffersScreenState createState() => _AllOffersScreenState();
}

class _AllOffersScreenState extends State<AllOffersScreen> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: ColorClass.base_color,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => CommonWidget.safePop(context),
        ),
        title: Text(
          "Offers - ${widget.vendorName}",
          style: const TextStyle(
            color: Colors.white,
            fontFamily: "Pop600",
            fontSize: 18,
          ),
        ),
      ),
      body: isLoading
          ? _buildLoadingState()
          : widget.offers.isEmpty
              ? _buildEmptyState()
              : _buildOffersList(),
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
            Icons.local_offer_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            "No Offers Available",
            style: TextStyle(
              fontSize: 24,
              fontFamily: "Pop600",
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Offers will appear here when available",
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

  Widget _buildOffersList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.offers.length,
      itemBuilder: (context, index) {
        final offer = widget.offers[index];
        return _buildOfferCard(offer);
      },
    );
  }

  Widget _buildOfferCard(Map<String, dynamic> offer) {
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
              child: offer['image'] != null && offer['image'].isNotEmpty
                  ? Image.network(
                      offer['image'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.local_offer,
                          size: 64,
                          color: Colors.orange[600],
                        );
                      },
                    )
                  : Icon(
                      Icons.local_offer,
                      size: 64,
                      color: Colors.orange[600],
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${offer['discount'] ?? 0}% OFF",
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: "Pop600",
                          color: Colors.orange[800],
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (offer['validUntil'] != null)
                      Text(
                        "Valid until ${_formatDate(offer['validUntil'])}",
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: "Pop400",
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  offer['title'] ?? 'Special Offer',
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
                  offer['description'] ?? 'No description available',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: "Pop400",
                    color: Colors.grey[600],
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      offer['duration'] ?? 'Duration not specified',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: "Pop400",
                        color: Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    if (offer['originalPrice'] != null && offer['discountedPrice'] != null)
                      Row(
                        children: [
                          Text(
                            "\$${offer['originalPrice']}",
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: "Pop400",
                              color: Colors.grey[500],
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "\$${offer['discountedPrice']}",
                            style: TextStyle(
                              fontSize: 18,
                              fontFamily: "Pop600",
                              color: ColorClass.base_color,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _claimOffer(offer);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Claim Offer",
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

  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown';
    try {
      final DateTime dateTime = DateTime.parse(date.toString());
      return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
    } catch (e) {
      return 'Invalid Date';
    }
  }

  void _claimOffer(Map<String, dynamic> offer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Claim ${offer['title'] ?? 'Offer'}"),
        content: Text("This offer provides ${offer['discount'] ?? 0}% discount. Would you like to claim it?"),
        actions: [
          TextButton(
            onPressed: () => CommonWidget.safePop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              CommonWidget.safePop(context);
              CommonWidget.successShowSnackBarFor(context, "Offer claimed successfully!");
            },
            child: const Text("Claim Now"),
          ),
        ],
      ),
    );
  }
}
