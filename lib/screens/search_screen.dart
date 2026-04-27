import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/weather_provider.dart';
import '../providers/location_provider.dart';
import '../models/location_model.dart';
import '../utils/constants.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _isSearching = true);

    final wp = context.read<WeatherProvider>();
    final lp = context.read<LocationProvider>();

    await wp.fetchByCity(query.trim());

    // Nếu fetch thành công → cập nhật vị trí đang chọn
    if (wp.weather != null && wp.status != WeatherStatus.error) {
      final newLoc = LocationModel(
        city: wp.weather!.cityName,
        country: wp.weather!.country,
        lat: wp.weather!.lat,
        lon: wp.weather!.lon,
      );
      lp.selectLocation(newLoc);

      if (mounted) Navigator.pop(context);
    } else {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A2A4A),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            _buildSearchBar(context),
            // Body
            Expanded(child: _buildContent(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2A3A),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white70, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          const SizedBox(width: 4),
          // Search field
          Expanded(
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                textInputAction: TextInputAction.search,
                onSubmitted: _search,
                decoration: InputDecoration(
                  hintText: 'Nhập tên thành phố...',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 15,
                  ),
                  prefixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white54,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : const Icon(Icons.search_rounded,
                          color: Colors.white54, size: 20),
                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _controller,
                    builder: (_, value, __) => value.text.isEmpty
                        ? const SizedBox.shrink()
                        : IconButton(
                            onPressed: () => _controller.clear(),
                            icon: const Icon(Icons.close_rounded,
                                color: Colors.white54, size: 18),
                          ),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Search button
          GestureDetector(
            onTap: () => _search(_controller.text),
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF667EEA),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text(
                  'Tìm',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final wp = context.watch<WeatherProvider>();
    final lp = context.watch<LocationProvider>();

    // Lỗi tìm kiếm
    if (wp.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔍', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text(
                wp.errorMessage ?? 'Không tìm thấy thành phố',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final history = wp.getSearchHistory();
    final favorites = lp.favoriteCities;

    return ListView(
      padding: const EdgeInsets.all(AppDesign.screenPadding),
      children: [
        // Yêu thích
        if (favorites.isNotEmpty) ...[
          const _SectionHeader(
            title: 'Yêu thích',
            icon: Icons.favorite_rounded,
            iconColor: Colors.pinkAccent,
          ),
          const SizedBox(height: 10),
          ...favorites.map((loc) => _CityTile(
                location: loc,
                trailing: IconButton(
                  onPressed: () async {
                    await lp.removeFromFavorites(loc);
                    setState(() {});
                  },
                  icon: const Icon(
                    Icons.favorite_rounded,
                    color: Colors.pinkAccent,
                    size: 20,
                  ),
                ),
                onTap: () => _selectFavorite(loc),
              )),
          const SizedBox(height: 20),
        ],

        // Lịch sử tìm kiếm
        if (history.isNotEmpty) ...[
          Row(
            children: [
              const _SectionHeader(
                title: 'Lịch sử tìm kiếm',
                icon: Icons.history_rounded,
                iconColor: Colors.white60,
              ),
              const Spacer(),
              TextButton(
                onPressed: () async {
                  await wp.clearSearchHistory();
                  setState(() {});
                },
                child: const Text(
                  'Xóa tất cả',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...history.map((city) => _HistoryTile(
                city: city,
                onTap: () {
                  _controller.text = city;
                  _search(city);
                },
                onDelete: () async {
                  await wp.clearSearchHistory();
                  setState(() {});
                },
              )),
        ],

        // Placeholder khi trống
        if (favorites.isEmpty && history.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Column(
                children: [
                  const Text('🌍', style: TextStyle(fontSize: 56)),
                  const SizedBox(height: 16),
                  Text(
                    'Nhập tên thành phố để tìm kiếm',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _selectFavorite(LocationModel loc) async {
    final wp = context.read<WeatherProvider>();
    final lp = context.read<LocationProvider>();

    await wp.fetchByLocation(loc);
    lp.selectLocation(loc);
    if (mounted) Navigator.pop(context);
  }
}

// Helper Widgets

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 16),
        const SizedBox(width: 6),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _CityTile extends StatelessWidget {
  final LocationModel location;
  final Widget? trailing;
  final VoidCallback onTap;

  const _CityTile({
    required this.location,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.location_city_rounded,
            color: Colors.white70,
            size: 20,
          ),
        ),
        title: Text(
          location.city,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        subtitle: location.country.isNotEmpty
            ? Text(
                location.country,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              )
            : null,
        trailing: trailing,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final String city;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _HistoryTile({
    required this.city,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        onTap: onTap,
        dense: true,
        leading: Icon(
          Icons.history_rounded,
          color: Colors.white.withValues(alpha: 0.4),
          size: 20,
        ),
        title: Text(
          city,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 14,
          ),
        ),
        trailing: IconButton(
          onPressed: onDelete,
          icon: Icon(
            Icons.close_rounded,
            color: Colors.white.withValues(alpha: 0.3),
            size: 18,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }
}
