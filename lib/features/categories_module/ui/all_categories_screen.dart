import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:car_app/Common/Color.dart';
import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/features/categories_module/ui/categories_list_activity.dart';
import 'package:car_app/features/categories_module/data_manager/categories_list_data_manager.dart';
import 'package:car_app/features/home_module/model/category_model_data.dart';
import 'package:car_app/design_system/components/car_loader.dart';

class AllCategoriesScreen extends StatefulWidget {
  const AllCategoriesScreen({super.key});

  @override
  _AllCategoriesScreenState createState() => _AllCategoriesScreenState();
}

class _AllCategoriesScreenState extends State<AllCategoriesScreen> {
  CategoriesListDataManager? dataManager;
  List<CategoryData> categories = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeDataManager();
  }

  Future<void> _initializeDataManager() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    dataManager = CategoriesListDataManager(prefs);
    await _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      if (mounted) {
        setState(() {
          isLoading = true;
        });
      }
      
      final response = await dataManager!.getcategory(context);
      if (!mounted) return;
      final responseData = response.data;

      if (responseData['status'] == 'success' && responseData['data'] != null) {
        final categoriesData = responseData['data'] as List;
        if (mounted) {
          setState(() {
            categories = categoriesData
                .map((category) => CategoryData.fromJson(category))
                .toList();
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: ColorClass.base_color,
        elevation: 0,
        leading: CommonWidget.buildAppBarBackButton(
          context,
          backgroundColor: Colors.white.withOpacity(0.2),
          iconColor: Colors.white,
        ),
        title: const Text(
          "All Categories",
          style: TextStyle(
            color: Colors.white,
            fontFamily: "Pop600",
            fontSize: 18,
          ),
        ),
      ),
      body: isLoading
          ? _buildLoadingState()
          : categories.isEmpty
              ? _buildEmptyState()
              : _buildCategoriesList(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CarLoader());
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            "No Categories Available",
            style: TextStyle(
              fontSize: 24,
              fontFamily: "Pop600",
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Categories will appear here when available",
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

  Widget _buildCategoriesList() {
    return RefreshIndicator(
      onRefresh: _loadCategories,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return _buildCategoryCard(category);
        },
      ),
    );
  }

  Widget _buildCategoryCard(CategoryData category) {
    return GestureDetector(
      onTap: () {
        CommonWidget.navigateToScreen(
          context,
          CategoriesListActivity(category),
        );
      },
      child: Container(
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: ColorClass.base_light_color,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                Icons.category,
                color: ColorClass.base_color,
                size: 30,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                category.categoryTitle ?? 'Category',
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: "Pop600",
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "View services",
              style: TextStyle(
                fontSize: 12,
                fontFamily: "Pop400",
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
