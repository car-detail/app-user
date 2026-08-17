import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../Common/Color.dart';
import '../../../Common/CommonWidget.dart';
import '../model/booking_list_bean.dart';

/// A shareable "Ride Card" generated from a completed booking — the core
/// growth loop: every finished wash becomes a branded, Instagram/WhatsApp
/// -story-ready image with zero backend changes (built entirely from data
/// already on the booking record).
class RideShareCardActivity extends StatefulWidget {
  final Records booking;

  const RideShareCardActivity(this.booking, {super.key});

  @override
  State<RideShareCardActivity> createState() => _RideShareCardActivityState();
}

class _RideShareCardActivityState extends State<RideShareCardActivity> {
  final GlobalKey _cardKey = GlobalKey();
  bool _ready = false;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _preload();
  }

  Future<void> _preload() async {
    final url = widget.booking.vendorDisplayPicture;
    if (url != null && url.isNotEmpty) {
      try {
        await precacheImage(NetworkImage(url), context);
      } catch (_) {
        // fall through — card still renders with the fallback avatar
      }
    }
    if (mounted) setState(() => _ready = true);
  }

  Future<void> _shareCard() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final boundary = _cardKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/cahrz_ride_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            "My ride just got the Cahrz treatment 🚗✨ Book yours on Cahrz!",
      );
    } catch (e) {
      if (mounted) {
        CommonWidget.errorShowSnackBarFor(context, "Couldn't create the share card, try again");
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final serviceLabel =
        booking.serviceTitle ?? booking.packageName ?? booking.serviceCategory ?? "Service";

    String dateLabel = "";
    try {
      dateLabel = DateFormat("MMM d, yyyy").format(DateTime.parse(booking.date ?? ""));
    } catch (_) {
      dateLabel = booking.date ?? "";
    }

    return Scaffold(
      backgroundColor: const Color(0xff0E1116),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Share Your Ride",
          style: TextStyle(color: Colors.white, fontFamily: "Pop600", fontSize: 17),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: _ready
                    ? SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: RepaintBoundary(
                          key: _cardKey,
                          child: _RideCard(
                            vendorImage: booking.vendorDisplayPicture,
                            vendorName: booking.vendorDisplayName ?? "Cahrz Vendor",
                            serviceLabel: serviceLabel,
                            category: booking.serviceCategory,
                            dateLabel: dateLabel,
                            price: booking.price,
                          ),
                        ),
                      )
                    : const CircularProgressIndicator(color: Colors.white),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _ready ? _shareCard : null,
                  icon: _sharing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.ios_share_rounded, size: 18),
                  label: Text(_sharing ? "Preparing…" : "Share to Instagram / WhatsApp",
                      style: const TextStyle(fontFamily: "Pop600", fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: ColorClass.base_color,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RideCard extends StatelessWidget {
  final String? vendorImage;
  final String vendorName;
  final String serviceLabel;
  final String? category;
  final String dateLabel;
  final int? price;

  const _RideCard({
    required this.vendorImage,
    required this.vendorName,
    required this.serviceLabel,
    required this.category,
    required this.dateLabel,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: 460,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff192028), Color(0xff2B3A55), Color(0xff3F51B5)],
        ),
      ),
      child: Stack(
        children: [
          // Decorative artistic blobs
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -50,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            top: 90,
            left: -20,
            child: Icon(Icons.auto_awesome_rounded, color: Colors.white.withOpacity(0.12), size: 46),
          ),
          Positioned(
            bottom: 130,
            right: 10,
            child: Icon(Icons.auto_awesome_rounded, color: Colors.white.withOpacity(0.1), size: 28),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.asset(
                          CommonWidget.getImagePath("ChatGPT Image Aug 17, 2026, 05_32_28 AM.png"),
                          width: 22,
                          height: 22,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "CAHRZ",
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: "Pop700",
                        fontSize: 16,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Vendor avatar
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 38,
                      backgroundColor: Colors.white.withOpacity(0.15),
                      backgroundImage: (vendorImage != null && vendorImage!.isNotEmpty)
                          ? NetworkImage(vendorImage!)
                          : null,
                      child: (vendorImage == null || vendorImage!.isEmpty)
                          ? const Icon(Icons.local_car_wash_rounded, color: Colors.white, size: 32)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                Center(
                  child: Text(
                    "My ride got the\nCahrz treatment 🚗✨",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: "Pop700",
                      fontSize: 19,
                      height: 1.25,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                Center(
                  child: Text(
                    "at $vendorName",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontFamily: "Pop500",
                      fontSize: 13,
                    ),
                  ),
                ),

                const Spacer(),

                // Chips row
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _pill(Icons.local_car_wash_rounded, serviceLabel),
                    if (category != null && category!.isNotEmpty) _pill(Icons.category_rounded, category!),
                    if (dateLabel.isNotEmpty) _pill(Icons.calendar_today_rounded, dateLabel),
                  ],
                ),

                const SizedBox(height: 16),
                Container(height: 1, color: Colors.white.withOpacity(0.15)),
                const SizedBox(height: 12),

                Center(
                  child: Text(
                    "Book your wash on Cahrz",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontFamily: "Pop500",
                      fontSize: 11,
                      letterSpacing: 0.5,
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

  Widget _pill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontFamily: "Pop500", fontSize: 11),
          ),
        ],
      ),
    );
  }
}
