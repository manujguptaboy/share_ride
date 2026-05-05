import 'dart:async';

import 'package:flutter/material.dart';
import 'package:share_ride/features/auth/presentation/pages/login_page.dart';
import 'package:share_ride/features/home/data/place_api.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({
    super.key,
    this.userName,
    this.userEmail,
  });

  final String? userName;
  final String? userEmail;

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  int _selectedTab = 0;

  String get _displayName {
    final n = widget.userName?.trim();
    if (n == null || n.isEmpty) return 'Guest';
    return n;
  }

  String get _displayEmail {
    final e = widget.userEmail?.trim();
    if (e == null || e.isEmpty) return '—';
    return e;
  }

  String get _homeCardSubtitle {
    final e = widget.userEmail?.trim();
    if (e != null && e.isNotEmpty) return e;
    return 'Your account is active';
  }

  String _initialsFor(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      final p = parts[0];
      if (p.length >= 2) return p.substring(0, 2).toUpperCase();
      return p[0].toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropoffController = TextEditingController();
  Timer? _pickupDebounce;
  Timer? _dropoffDebounce;
  List<String> _pickupSuggestions = [];
  List<String> _dropoffSuggestions = [];

  @override
  void dispose() {
    _pickupDebounce?.cancel();
    _dropoffDebounce?.cancel();
    _pickupController.dispose();
    _dropoffController.dispose();
    super.dispose();
  }

  Future<void> _fetchSuggestions({
    required bool isPickup,
    required String input,
  }) async {
    if (input.trim().length < 2) {
      if (!mounted) return;
      setState(() {
        if (isPickup) {
          _pickupSuggestions = [];
        } else {
          _dropoffSuggestions = [];
        }
      });
      return;
    }

    final suggestions = await PlaceApi.autocomplete(input.trim());
    if (!mounted) return;
    setState(() {
      if (isPickup) {
        _pickupSuggestions = suggestions;
      } else {
        _dropoffSuggestions = suggestions;
      }
    });
  }

  Widget _buildHomeTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [Color(0xFF6F5BFF), Color(0xFF4A35F3)],
                ),
              ),
              child: const Icon(Icons.near_me_rounded, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Find Your Ride',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Enter your journey details',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 24),
          _RideInput(
            icon: Icons.location_on_outlined,
            iconColor: const Color(0xFF27AE60),
            hint: 'Pickup location',
            controller: _pickupController,
            suggestions: _pickupSuggestions,
            onChanged: (value) {
              _pickupDebounce?.cancel();
              _pickupDebounce = Timer(const Duration(milliseconds: 350), () {
                _fetchSuggestions(isPickup: true, input: value);
              });
            },
            onSuggestionTap: (value) {
              _pickupController.text = value;
              setState(() {
                _pickupSuggestions = [];
              });
            },
          ),
          const SizedBox(height: 14),
          _RideInput(
            icon: Icons.location_on_outlined,
            iconColor: const Color(0xFFE53935),
            hint: 'Drop-off location',
            controller: _dropoffController,
            suggestions: _dropoffSuggestions,
            onChanged: (value) {
              _dropoffDebounce?.cancel();
              _dropoffDebounce = Timer(const Duration(milliseconds: 350), () {
                _fetchSuggestions(isPickup: false, input: value);
              });
            },
            onSuggestionTap: (value) {
              _dropoffController.text = value;
              setState(() {
                _dropoffSuggestions = [];
              });
            },
          ),
          const SizedBox(height: 14),
          Row(
            children: const [
              Expanded(
                child: _RideInput(
                  icon: Icons.calendar_today_outlined,
                  iconColor: Color(0xFF5B4AE5),
                  hint: 'dd/mm/yyyy',
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: _RideInput(
                  icon: Icons.access_time_outlined,
                  iconColor: Color(0xFF5B4AE5),
                  hint: '--:-- --',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 56,
            child: FilledButton.icon(
              onPressed: () {},
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                backgroundColor: const Color(0xFF4A35F3),
              ),
              icon: const Icon(Icons.search),
              label: const Text(
                'Search Available Rides',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 26),
          const Divider(height: 1),
          const SizedBox(height: 20),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedTab = 1;
                });
              },
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F3F7),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFF4A35F3),
                      child: Text(
                        _initialsFor(_displayName),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hi, $_displayName',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _homeCardSubtitle,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _selectedTab = 1;
                        });
                      },
                      icon: const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF4A35F3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Recent searches',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F3F7),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.place_outlined, color: Colors.black45),
                const SizedBox(width: 12),
                Text(
                  'Downtown -> Airport',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Profile',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your account details',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F3F7),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: const Color(0xFF4A35F3),
                  child: Text(
                    _initialsFor(_displayName),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _displayName,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _displayEmail,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text(
                'Log out',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFC62828),
                side: const BorderSide(color: Color(0xFFE57373)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateRideTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [Color(0xFF6F5BFF), Color(0xFF4A35F3)],
                ),
              ),
              child: const Icon(Icons.add_road_rounded, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Create a ride',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Offer seats on your route',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                backgroundColor: const Color(0xFF4A35F3),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderTab(String title, ThemeData theme) {
    return Center(
      child: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          color: Colors.black45,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) {
          setState(() {
            _selectedTab = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Account',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_road_outlined),
            selectedIcon: Icon(Icons.add_road),
            label: 'Create ride',
          ),
          NavigationDestination(
            icon: Icon(Icons.miscellaneous_services_outlined),
            selectedIcon: Icon(Icons.miscellaneous_services),
            label: 'Service',
          ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedTab,
          children: [
            _buildHomeTab(theme),
            _buildAccountTab(theme),
            _buildCreateRideTab(theme),
            _buildPlaceholderTab('Service', theme),
          ],
        ),
      ),
    );
  }
}

class _RideInput extends StatelessWidget {
  const _RideInput({
    required this.icon,
    required this.iconColor,
    required this.hint,
    this.controller,
    this.suggestions = const [],
    this.onChanged,
    this.onSuggestionTap,
  });

  final IconData icon;
  final Color iconColor;
  final String hint;
  final TextEditingController? controller;
  final List<String> suggestions;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSuggestionTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: iconColor),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFFD8D8D8)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFFD8D8D8)),
            ),
          ),
        ),
        if (suggestions.isNotEmpty) const SizedBox(height: 8),
        if (suggestions.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE1E1E1)),
            ),
            child: Column(
              children: suggestions
                  .take(4)
                  .map(
                    (item) => ListTile(
                      dense: true,
                      title: Text(
                        item,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => onSuggestionTap?.call(item),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}

