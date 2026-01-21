import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Common/Color.dart';
import '../../../Common/CommonWidget.dart';
import '../../categories_module/data_manager/categories_list_data_manager.dart';
import '../../categories_module/model/services_post_bean.dart';
import '../../home_module/model/services_model_data.dart';
import '../../specialists_module/ui/specialists_activity.dart';
import '../model/bookmark_model_bean.dart';

class BookmarkActivity extends StatefulWidget {
  const BookmarkActivity({super.key});

  @override
  State<BookmarkActivity> createState() => _BookmarkActivityState();
}

class _BookmarkActivityState extends State<BookmarkActivity> {
  List<BookmarkModelData> servicesData = [];

  CategoriesListDataManager? dataManager;
  SharedPreferences? sharedPreferences;
  List<String> offerList = ["car_image.png", "car_image.png"];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    start();
  }

  start() async {
    sharedPreferences = await SharedPreferences.getInstance();
    dataManager = CategoriesListDataManager(sharedPreferences!);
    getServices(context);
  }

  getServices(BuildContext context) async {
    var response = await dataManager!.getBooksMark(
      context,
    );
    var data = BookmarkModelBean.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      setState(() {
        servicesData.clear();
        servicesData.addAll(data.data!);
      });
      //CommonWidget.successShowSnackBarFor(context, data.message ?? "");
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: ColorClass.base_color,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: ColorClass.base_color,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Modern Header
          Container(
            decoration: BoxDecoration(
              color: ColorClass.base_color,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.only(top: 45, bottom: 20, left: 16, right: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CommonWidget.buildGreenHeaderBackButton(context),
                const Text(
                  "Bookmarks",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontFamily: "Pop600",
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.bookmark,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          
          // Content Area
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                if (mounted && context.mounted) {
                  await getServices(context);
                }
              },
            child: servicesData.isEmpty
                ? _buildEmptyState()
                : Container(
                    margin: const EdgeInsets.all(16),
                    child: ListView.builder(
                      itemCount: servicesData.length,
                      itemBuilder: (context, index) {
                        return _buildBookmarkCard(servicesData[index], index);
                      },
                      ),
                    ),
                  ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ColorClass.base_color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bookmark_border,
              size: 64,
              color: ColorClass.base_color.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "No Bookmarks Yet",
            style: TextStyle(
              fontSize: 20,
              fontFamily: "Pop600",
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Services you bookmark will appear here",
            style: TextStyle(
              fontSize: 14,
              fontFamily: "Pop400",
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarkCard(BookmarkModelData bookmark, int index) {
    final service = bookmark.serviceId;
    if (service == null) return const SizedBox.shrink();

    // Check if vendor is offline (only for app vendors)
    final isOffline = (service.isAppVendor ?? false) && !(service.isShopOpen ?? true);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isOffline ? Colors.grey[100] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isOffline ? Border.all(color: Colors.grey[300]!) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Prevent navigation for offline vendors
            if (isOffline) {
              _showOfflineMessage(context);
              return;
            }
            
            CommonWidget.navigateToScreen(
              context,
              SpecialistsActivity(service.sId ?? ""),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Service Image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[100],
                  ),
                  child: service.displayPicture != null && service.displayPicture!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            service.displayPicture!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildDefaultServiceIcon();
                            },
                          ),
                        )
                      : _buildDefaultServiceIcon(),
                ),
                
                const SizedBox(width: 16),
                
                // Service Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              service.displayName ?? "Service",
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: "Pop600",
                                color: isOffline ? Colors.grey[600] : Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // OFFLINE badge
                          if (isOffline)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'OFFLINE',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.red[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (service.services.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: ColorClass.base_color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            service.services.first.serviceTitle ?? "Service",
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: "Pop500",
                              color: ColorClass.base_color,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (service.location?.name != null) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                service.location!.name!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: "Pop400",
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                      if (service.services.isNotEmpty && service.services.first.price != null) ...[
                        Text(
                          "\$${service.services.first.price}",
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: "Pop600",
                            color: ColorClass.base_color,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Remove Bookmark Button
                GestureDetector(
                  onTap: () {
                    _showRemoveBookmarkDialog(bookmark, index);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.bookmark_remove,
                      size: 20,
                      color: Colors.red[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultServiceIcon() {
    return Container(
      decoration: BoxDecoration(
        color: ColorClass.base_color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.local_car_wash,
        size: 32,
        color: ColorClass.base_color,
      ),
    );
  }

  void _showRemoveBookmarkDialog(BookmarkModelData bookmark, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Remove Bookmark",
            style: TextStyle(
              fontSize: 18,
              fontFamily: "Pop600",
              color: Colors.black87,
            ),
          ),
          content: Text(
            "Are you sure you want to remove this service from your bookmarks?",
            style: TextStyle(
              fontSize: 14,
              fontFamily: "Pop400",
              color: Colors.grey[600],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => CommonWidget.safePop(context),
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontFamily: "Pop500",
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                CommonWidget.safePop(context);
                removeBookmark(
                  context,
                  bookmark.serviceId!.sId.toString(),
                );
              },
              child: Text(
                "Remove",
                style: TextStyle(
                  color: Colors.red[600],
                  fontFamily: "Pop600",
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  postBookmark(BuildContext context, String id) async {
    var response = await dataManager!.postBookmark(context, id);
    var data = ServicesPostBean.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      CommonWidget.successShowSnackBarFor(context, data.message ?? "");
      getServices(context);
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }

  removeBookmark(BuildContext context, String id) async {
    var response = await dataManager!.removeBookmark(context, id);
    var data = ServicesPostBean.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      CommonWidget.successShowSnackBarFor(context, data.message ?? "");
      getServices(context);
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }

  void _showOfflineMessage(BuildContext context) {
    CommonWidget.errorShowSnackBarFor(context, "This vendor is currently offline and not accepting bookings");
  }
}
