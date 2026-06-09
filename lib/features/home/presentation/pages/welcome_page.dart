import 'dart:async';

import 'package:flutter/material.dart';
import 'package:share_ride/features/auth/data/auth_api.dart';
import 'package:share_ride/features/auth/presentation/pages/aadhaar_input_page.dart';
import 'package:share_ride/features/auth/presentation/pages/login_page.dart';
import 'package:share_ride/features/home/data/map_api.dart';
import 'package:share_ride/features/home/data/place_api.dart';
import 'package:share_ride/features/home/presentation/pages/directions_page.dart';
import 'package:share_ride/features/home/presentation/pages/start_location_picker_page.dart';
import 'package:latlong2/latlong.dart';

enum AppMode { rider, driver }

class WelcomePage extends StatefulWidget {
  const WelcomePage({
    super.key,
    this.userId,
    this.userName,
    this.userEmail,
    this.aadhaarVerified = false,
  });

  final int? userId;
  final bool aadhaarVerified;

  final String? userName;
  final String? userEmail;

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  int _selectedTab = 0;
  AppMode _appMode = AppMode.rider;
  late bool _aadhaarVerified;
  bool _isCheckingDriverAccess = false;

  @override
  void initState() {
    super.initState();
    _aadhaarVerified = widget.aadhaarVerified;
  }

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

  Widget _pickerTheme(BuildContext context, Widget? child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF4A35F3),
          onPrimary: Colors.white,
          onSurface: Colors.black87,
        ),
      ),
      child: child!,
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: _pickerTheme,
    );
    if (!mounted || picked == null) return;

    final day = picked.day.toString().padLeft(2, '0');
    final month = picked.month.toString().padLeft(2, '0');
    _dateController.text = '$day/$month/${picked.year}';
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: _pickerTheme,
    );
    if (!mounted || picked == null) return;

    final hour = picked.hourOfPeriod.toString().padLeft(2, '0');
    final minute = picked.minute.toString().padLeft(2, '0');
    final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
    _timeController.text = '$hour:$minute $period';
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  Future<void> _openStartLocationPicker() async {
    final selected = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(builder: (_) => const StartLocationPickerPage()),
    );
    if (!mounted || selected == null) return;

    final address = await MapApi.reverseGeocode(
      lat: selected.latitude,
      lng: selected.longitude,
    );
    if (!mounted) return;

    _pickupController.text = address.isNotEmpty
        ? address
        : '${selected.latitude.toStringAsFixed(5)}, ${selected.longitude.toStringAsFixed(5)}';

    setState(() {
      _pickupSuggestions = [];
      _pickupSearching = false;
    });
  }
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropoffController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  Timer? _pickupDebounce;
  Timer? _dropoffDebounce;
  List<String> _pickupSuggestions = [];
  List<String> _dropoffSuggestions = [];
  bool _pickupSearching = false;

  @override
  void dispose() {
    _pickupDebounce?.cancel();
    _dropoffDebounce?.cancel();
    _pickupController.dispose();
    _dropoffController.dispose();
    _dateController.dispose();
    _timeController.dispose();
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

  void _openDirections() {
    final origin = _pickupController.text.trim();
    final destination = _dropoffController.text.trim();

    if (origin.isEmpty || destination.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both pickup and drop-off locations'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DirectionsPage(
          origin: origin,
          destination: destination,
        ),
      ),
    );
  }

  Future<void> _enterDriverMode() async {
    if (_appMode == AppMode.driver || _isCheckingDriverAccess) return;

    final userId = widget.userId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in again to use driver mode.')),
      );
      return;
    }

    setState(() => _isCheckingDriverAccess = true);

    try {
      final status = await AuthApi.getVerificationStatus(userId);
      if (!mounted) return;

      setState(() {
        _aadhaarVerified = status.aadhaarVerified;
      });

      if (!status.aadhaarVerified) {
        setState(() => _isCheckingDriverAccess = false);

        final verified = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => AadhaarInputPage(
              userId: userId,
              forDriverOnboarding: true,
            ),
          ),
        );

        if (!mounted) return;
        if (verified != true) return;

        setState(() {
          _aadhaarVerified = true;
          _appMode = AppMode.driver;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aadhaar verified. Driver mode enabled.')),
        );
        return;
      }

      setState(() {
        _isCheckingDriverAccess = false;
        _appMode = AppMode.driver;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCheckingDriverAccess = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', 'Could not check driver access'),
          ),
        ),
      );
    }
  }

  Widget _buildModeToggle(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEEECF9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeToggleButton(
              label: 'Rider',
              icon: Icons.person_outline,
              selected: _appMode == AppMode.rider,
              onTap: () {
                if (_appMode == AppMode.rider) return;
                setState(() => _appMode = AppMode.rider);
              },
            ),
          ),
          Expanded(
            child: _ModeToggleButton(
              label: 'Driver',
              icon: Icons.directions_car_outlined,
              selected: _appMode == AppMode.driver,
              onTap: () {
                if (_isCheckingDriverAccess) return;
                _enterDriverMode();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiderHome(ThemeData theme) {
    return Column(
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
          showCurrentLocationOption: _pickupSearching,
          onCurrentLocationTap: _openStartLocationPicker,
          onChanged: (value) {
            setState(() {
              _pickupSearching = value.trim().isNotEmpty;
            });
            _pickupDebounce?.cancel();
            _pickupDebounce = Timer(const Duration(milliseconds: 350), () {
              _fetchSuggestions(isPickup: true, input: value);
            });
          },
          onSuggestionTap: (value) {
            _pickupController.text = value;
            setState(() {
              _pickupSuggestions = [];
              _pickupSearching = false;
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
          children: [
            Expanded(
              child: _RideInput(
                icon: Icons.calendar_today_outlined,
                iconColor: const Color(0xFF5B4AE5),
                hint: 'dd/mm/yyyy',
                controller: _dateController,
                readOnly: true,
                onTap: _pickDate,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _RideInput(
                icon: Icons.access_time_outlined,
                iconColor: const Color(0xFF5B4AE5),
                hint: '--:-- --',
                controller: _timeController,
                readOnly: true,
                onTap: _pickTime,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 56,
          child: FilledButton.icon(
            onPressed: _openDirections,
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
      ],
    );
  }

  Widget _buildDriverVerificationGate(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.badge_outlined,
          size: 56,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'Aadhaar verification required',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Complete Aadhaar verification to access driver mode.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _enterDriverMode,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            backgroundColor: const Color(0xFF4A35F3),
          ),
          child: const Text('Verify Aadhaar'),
        ),
      ],
    );
  }

  Widget _buildDriverHome(ThemeData theme) {
    return Column(
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
          'Offer a Ride',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Share your route and available seats',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 24),
        _RideInput(
          icon: Icons.location_on_outlined,
          iconColor: const Color(0xFF27AE60),
          hint: 'Start location',
          controller: _pickupController,
          suggestions: _pickupSuggestions,
          showCurrentLocationOption: _pickupSearching,
          onCurrentLocationTap: _openStartLocationPicker,
          onChanged: (value) {
            setState(() {
              _pickupSearching = value.trim().isNotEmpty;
            });
            _pickupDebounce?.cancel();
            _pickupDebounce = Timer(const Duration(milliseconds: 350), () {
              _fetchSuggestions(isPickup: true, input: value);
            });
          },
          onSuggestionTap: (value) {
            _pickupController.text = value;
            setState(() {
              _pickupSuggestions = [];
              _pickupSearching = false;
            });
          },
        ),
        const SizedBox(height: 14),
        _RideInput(
          icon: Icons.location_on_outlined,
          iconColor: const Color(0xFFE53935),
          hint: 'End location',
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
          children: [
            Expanded(
              child: _RideInput(
                icon: Icons.calendar_today_outlined,
                iconColor: const Color(0xFF5B4AE5),
                hint: 'dd/mm/yyyy',
                controller: _dateController,
                readOnly: true,
                onTap: _pickDate,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _RideInput(
                icon: Icons.access_time_outlined,
                iconColor: const Color(0xFF5B4AE5),
                hint: '--:-- --',
                controller: _timeController,
                readOnly: true,
                onTap: _pickTime,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 56,
          child: FilledButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Publish ride coming soon')),
              );
            },
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              backgroundColor: const Color(0xFF4A35F3),
            ),
            icon: const Icon(Icons.publish_rounded),
            label: const Text(
              'Publish Ride',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHomeTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildModeToggle(theme),
          if (_isCheckingDriverAccess)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(),
            ),
          const SizedBox(height: 20),
          if (_appMode == AppMode.rider)
            _buildRiderHome(theme)
          else if (_aadhaarVerified)
            _buildDriverHome(theme)
          else
            _buildDriverVerificationGate(theme),
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
          const SizedBox(height: 20),
          if (_aadhaarVerified)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFA5D6A7)),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified_rounded, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Aadhaar verified',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: () async {
                  final userId = widget.userId;
                  if (userId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('User id missing. Please log in again.'),
                      ),
                    );
                    return;
                  }

                  final verified = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AadhaarInputPage(userId: userId),
                    ),
                  );

                  if (!mounted || verified != true) return;
                  setState(() => _aadhaarVerified = true);
                },
                icon: const Icon(Icons.badge_outlined),
                label: const Text(
                  'Verify Aadhaar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4A35F3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
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

class _ModeToggleButton extends StatelessWidget {
  const _ModeToggleButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF4A35F3) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected ? Colors.white : const Color(0xFF4A35F3),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : const Color(0xFF4A35F3),
                  ),
                ),
              ],
            ),
          ),
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
    this.showCurrentLocationOption = false,
    this.onCurrentLocationTap,
    this.readOnly = false,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String hint;
  final TextEditingController? controller;
  final List<String> suggestions;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSuggestionTap;
  final bool showCurrentLocationOption;
  final VoidCallback? onCurrentLocationTap;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final shouldShowCurrentLocation = showCurrentLocationOption;
    final hasDropdown = shouldShowCurrentLocation || suggestions.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          onChanged: onChanged,
          readOnly: readOnly,
          onTap: onTap,
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
        if (hasDropdown) const SizedBox(height: 8),
        if (hasDropdown)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE1E1E1)),
            ),  
            child: Column(
              children: [
                ...suggestions.take(6).map(
                  (item) => ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.place_outlined,
                      color: Colors.black45,
                    ),
                    title: Text(
                      item,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => onSuggestionTap?.call(item),
                  ),
                ),
                if (shouldShowCurrentLocation && suggestions.isNotEmpty)
                  const Divider(height: 1),
                if (shouldShowCurrentLocation)
                  ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.my_location_rounded,
                      color: Color(0xFF27AE60),
                    ),
                    title: const Text('Choose current location'),
                    onTap: onCurrentLocationTap,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

