import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/loading_widget.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final adminBookingsProvider =
FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final client = Supabase.instance.client;

  final response = await client
      .from('bookings')
      .select('*')
      .order('booking_date', ascending: false);
  debugPrint('Supabase raw response: $response');


  final bookings = List<Map<String, dynamic>>.from(response);

  for (var booking in bookings) {
    if (booking['user_id'] != null) {
      final user = await client
          .from('users')
          .select('full_name, email')
          .eq('id', booking['user_id'])
          .maybeSingle();
      booking['users'] = user;
    }
  }

  return bookings;
});

// ── Screen ────────────────────────────────────────────────────────────────────

class AdminBookingsScreen extends ConsumerStatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  ConsumerState<AdminBookingsScreen> createState() =>
      _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends ConsumerState<AdminBookingsScreen> {
  String _selectedStatus = 'all';

  final _statusOptions = [
    'all',
    'pending',
    'confirmed',
    'completed',
    'cancelled',
  ];

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(adminBookingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Bookings'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(adminBookingsProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Status Filter Bar ──
          Container(
            height: 48,
            color: AppColors.white,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _statusOptions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final status = _statusOptions[index];
                final isSelected = _selectedStatus == status;
                return GestureDetector(
                  onTap: () => setState(() => _selectedStatus = status),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.greyLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      status == 'all'
                          ? 'All'
                          : status[0].toUpperCase() + status.substring(1),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1),

          // ── Bookings List ──
          Expanded(
            child: bookingsAsync.when(
              data: (bookings) {
                debugPrint('Total bookings: ${bookings.length}');
                debugPrint('First booking: ${bookings.isNotEmpty ? bookings.first : 'empty'}');
                debugPrint('Selected status: $_selectedStatus');

                final filtered = _selectedStatus == 'all'
                    ? bookings
                    : bookings
                    .where((b) =>
                (b['status'] ?? 'pending').toString().toLowerCase() ==
                    _selectedStatus)
                    .toList();

                debugPrint('Filtered count: ${filtered.length}');

                if (filtered.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 64, color: AppColors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No bookings found',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(adminBookingsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                    const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        _BookingCard(
                          booking: filtered[index],
                          onStatusChange: (newStatus) =>
                              _updateStatus(filtered[index]['id'], newStatus),
                        ),
                  ),
                );
              },
              loading: () => const LoadingWidget(),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(String bookingId, String newStatus) async {
    try {
      await Supabase.instance.client
          .from('bookings')
          .update({'status': newStatus})
          .eq('id', bookingId);

      ref.invalidate(adminBookingsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to $newStatus'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Color _statusColor(String status) {
  switch (status) {
    case 'confirmed':
      return AppColors.info;
    case 'completed':
      return AppColors.success;
    case 'cancelled':
      return AppColors.error;
    default:
      return AppColors.warning;
  }
}

IconData _statusIcon(String status) {
  switch (status) {
    case 'confirmed':
      return Icons.check_circle_outline;
    case 'completed':
      return Icons.verified_outlined;
    case 'cancelled':
      return Icons.cancel_outlined;
    default:
      return Icons.schedule_outlined;
  }
}

// ── Booking Card ──────────────────────────────────────────────────────────────

class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final void Function(String) onStatusChange;

  const _BookingCard({
    required this.booking,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    final user = booking['users'] as Map<String, dynamic>?;
    final status =
    (booking['status'] ?? 'pending').toString().toLowerCase();
    final meetingType =
    (booking['meeting_type'] ?? 'online').toString();
    final bookingDate = booking['booking_date'] != null
        ? DateTime.tryParse(booking['booking_date'].toString())
        : null;
    final bookingTime = booking['booking_time'] ?? '--';
    final notes = booking['notes']?.toString() ?? '';
    final amount = booking['payment_amount'];
    final sc = _statusColor(status);

    String contactInfo = '';
    String cleanNotes = notes;
    if (notes.startsWith('Contact:')) {
      final idx = notes.indexOf('\n');
      if (idx != -1) {
        contactInfo = notes.substring(0, idx).replaceFirst('Contact:', '').trim();
        cleanNotes = notes.substring(idx + 1).trim();
      } else {
        contactInfo = notes.replaceFirst('Contact:', '').trim();
        cleanNotes = '';
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Top Row ──
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: sc.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _statusIcon(status),
                    color: sc,
                  ),
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?['full_name'] ?? 'Unknown User',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?['email'] ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: sc.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sc.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon(status), size: 14, color: sc),
                      const SizedBox(width: 4),
                      Text(
                        status[0].toUpperCase() + status.substring(1),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: sc,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Contact Info ──
          if (contactInfo.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.phone_outlined, size: 16, color: AppColors.primary),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    contactInfo,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

          // ── Divider ──
          const Divider(height: 1),

          // ── Details Row ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _InfoChip(
                  icon: Icons.calendar_today_outlined,
                  label: bookingDate != null
                      ? '${bookingDate.day}/${bookingDate.month}/${bookingDate.year}'
                      : '--',
                ),
                const SizedBox(width: 12),
                _InfoChip(
                  icon: Icons.access_time,
                  label: bookingTime,
                ),
                const SizedBox(width: 12),
                _InfoChip(
                  icon: meetingType.toLowerCase() == 'online'
                      ? Icons.video_camera_front_outlined
                      : Icons.location_on_outlined,
                  label: meetingType,
                ),
                if (amount != null) ...[
                  const SizedBox(width: 12),
                  _InfoChip(
                    icon: Icons.attach_money,
                    label: '৳$amount',
                  ),
                ],
              ],
            ),
          ),

          // ── Notes ──
          if (cleanNotes.isNotEmpty)
            Padding(
              padding:
              const EdgeInsets.only(left: 16, right: 16, bottom: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withOpacity(0.08)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.notes_outlined, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        cleanNotes,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Action Buttons ──
          if (status == 'pending')
            Padding(
              padding:
              const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => onStatusChange('cancelled'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side:
                        const BorderSide(color: AppColors.error),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => onStatusChange('confirmed'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Confirm'),
                    ),
                  ),
                ],
              ),
            )
          else if (status == 'confirmed')
            Padding(
              padding:
              const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => onStatusChange('completed'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Mark as Completed'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
