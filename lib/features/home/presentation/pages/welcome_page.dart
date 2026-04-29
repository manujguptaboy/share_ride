import 'package:flutter/material.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  int _passengers = 1;

  void _updatePassengers(int delta) {
    setState(() {
      final next = _passengers + delta;
      _passengers = next < 1 ? 1 : next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
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
              ),
              const SizedBox(height: 14),
              _RideInput(
                icon: Icons.location_on_outlined,
                iconColor: const Color(0xFFE53935),
                hint: 'Drop-off location',
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
              Row(
                children: [
                  const Icon(Icons.group_outlined, color: Color(0xFF5B4AE5)),
                  const SizedBox(width: 8),
                  Text(
                    'Number of passengers',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _PassengerButton(
                    icon: Icons.remove,
                    onTap: () => _updatePassengers(-1),
                  ),
                  const SizedBox(width: 26),
                  Text(
                    '$_passengers',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 26),
                  _PassengerButton(
                    icon: Icons.add,
                    onTap: () => _updatePassengers(1),
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
  });

  final IconData icon;
  final Color iconColor;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
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
    );
  }
}

class _PassengerButton extends StatelessWidget {
  const _PassengerButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFDADADA)),
        ),
        child: Icon(icon, size: 28),
      ),
    );
  }
}

