import 'package:flutter/material.dart';
import '../../../Common/Color.dart';
import '../../../Common/CommonWidget.dart';
import '../../home_module/model/services_model_data.dart';
import '../../home_module/model/mixed_vendor_data.dart';
import '../../home_module/data_manager/home_data_manager.dart';

class BookingActivity extends StatefulWidget {
  final MixedVendorData vendor;
  
  const BookingActivity({super.key, required this.vendor});

  @override
  State<BookingActivity> createState() => _BookingActivityState();
}

class _BookingActivityState extends State<BookingActivity> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            decoration: BoxDecoration(
              color: ColorClass.base_color,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    "Book Service",
                    style: TextStyle(
                      fontSize: 20,
                      fontFamily: "Pop600",
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vendor Info Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Vendor Image and Name
                        Row(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.grey[100],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: widget.vendor.imageUrl != null && widget.vendor.imageUrl!.isNotEmpty
                                    ? Image.network(
                                        widget.vendor.imageUrl!,
                                        fit: BoxFit.cover,
                                        headers: const {
                                          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          return Icon(
                                            Icons.business,
                                            size: 40,
                                            color: ColorClass.base_color,
                                          );
                                        },
                                      )
                                    : Icon(
                                        Icons.business,
                                        size: 40,
                                        color: ColorClass.base_color,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.vendor.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontFamily: "Pop600",
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.vendor.address ?? "Location not available",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontFamily: "Pop400",
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: 16,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "${(widget.vendor.distance! * 0.000621371).toStringAsFixed(1)} miles away",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontFamily: "Pop400",
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Services List
                        if (widget.vendor.services.isNotEmpty) ...[
                          const Text(
                            "Available Services",
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: "Pop600",
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...widget.vendor.services.map((service) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        service.replaceAll('_', ' ').split(' ').map((word) => 
                                          word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : ''
                                        ).join(' '),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontFamily: "Pop500",
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.vendor.category ?? "Car Service",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontFamily: "Pop400",
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  "Contact for Price",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: "Pop500",
                                    color: ColorClass.base_color,
                                  ),
                                ),
                              ],
                            ),
                          )),
                        ] else ...[
                          Text(
                            "No services available",
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: "Pop400",
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Booking Form
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Booking Details",
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: "Pop600",
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Service Selection
                        const Text(
                          "Select Service",
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: "Pop500",
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: widget.vendor.services.isNotEmpty ? widget.vendor.services.first : null,
                                hint: const Text("Choose a service"),
                                isExpanded: true,
                                items: widget.vendor.services.map((service) {
                                  return DropdownMenuItem<String>(
                                    value: service,
                                    child: Text(service.replaceAll('_', ' ').split(' ').map((word) => 
                                      word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : ''
                                    ).join(' ')),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  // Handle service selection
                                },
                              ),
                            ),
                        ),
                        const SizedBox(height: 16),
                        // Date Selection
                        const Text(
                          "Select Date",
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: "Pop500",
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, color: Colors.grey[600], size: 20),
                              const SizedBox(width: 8),
                              Text(
                                "Select date",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: "Pop400",
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Time Selection
                        const Text(
                          "Select Time",
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: "Pop500",
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.access_time, color: Colors.grey[600], size: 20),
                              const SizedBox(width: 8),
                              Text(
                                "Select time",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: "Pop400",
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Book Now Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              // Handle booking
                              _showBookingConfirmation();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorClass.base_color,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "Book Now",
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: "Pop600",
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBookingConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "Booking Confirmation",
          style: TextStyle(
            fontFamily: "Pop600",
            color: Colors.black87,
          ),
        ),
        content: Text(
          "Your booking request has been submitted successfully! The vendor will contact you soon to confirm the details.",
          style: TextStyle(
            fontFamily: "Pop400",
            color: Colors.grey[600],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to previous screen
            },
            child: Text(
              "OK",
              style: TextStyle(
                color: ColorClass.base_color,
                fontFamily: "Pop500",
              ),
            ),
          ),
        ],
      ),
    );
  }
}