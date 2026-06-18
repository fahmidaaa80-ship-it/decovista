import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/services/supabase_service.dart';
import '../../../providers/auth_provider.dart';

// ─── Model ───────────────────────────────────────────────────────────────────

class Booking {
  final String id;
  final String userId;
  final String? designerId;
  final DateTime bookingDate;
  final String bookingTime;
  final String meetingType;
  final String? meetingLink;
  final double? paymentAmount;
  final String? notes;
  final String status;
  final DateTime createdAt;

  Booking({
    required this.id,
    required this.userId,
    this.designerId,
    required this.bookingDate,
    required this.bookingTime,
    required this.meetingType,
    this.meetingLink,
    this.paymentAmount,
    this.notes,
    required this.status,
    required this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      designerId: json['designer_id'],
      bookingDate: DateTime.parse(
        json['booking_date'] ?? DateTime.now().toIso8601String(),
      ),
      bookingTime: json['booking_time'] ?? '',
      meetingType: json['meeting_type'] ?? 'online',
      meetingLink: json['meeting_link'],
      paymentAmount: json['payment_amount'] != null
          ? (json['payment_amount'] as num).toDouble()
          : null,
      notes: json['notes'],
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final bookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final response = await SupabaseService.getBookings(user.id);
  final bookings = response.map((json) => Booking.fromJson(json)).toList();
  return bookings.where((b) => b.status != 'cancelled').toList();
});

// ─── Screen ──────────────────────────────────────────────────────────────────

class BookingsScreen extends ConsumerStatefulWidget {
  const BookingsScreen({super.key});

  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen> {
  final Set<String> _cancelledIds = {};

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(bookingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        actions: [
          IconButton(
            onPressed: () => context.push('/booking'),
            icon: const Icon(Icons.add),
            tooltip: 'New Booking',
          ),
        ],
      ),
      body: bookingsAsync.when(
        data: (bookings) {
          final visible = bookings.where((b) => !_cancelledIds.contains(b.id)).toList();
          if (visible.isEmpty) {
            return _buildEmptyState();
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(bookingsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: visible.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) =>
                  _BookingCard(
                    booking: visible[index],
                    ref: ref,
                    onCancel: () {
                      setState(() => _cancelledIds.add(visible[index].id));
                    },
                  ),
            ),
          );
        },
        loading: () => const LoadingWidget(message: 'Loading bookings...'),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                e.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(bookingsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/booking'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.calendar_month, color: Colors.white),
        label: const Text(
          'Book Consultation',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_today_outlined,
              size: 60,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Bookings Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Book a consultation with our\ninterior design experts',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => context.push('/booking'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding:
              const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text(
              'Book Now',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Booking Card ─────────────────────────────────────────────────────────────

class _BookingCard extends StatelessWidget {
  final Booking booking;
  final WidgetRef ref;
  final VoidCallback onCancel;

  const _BookingCard({
    required this.booking,
    required this.ref,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isUpcoming = booking.bookingDate.isAfter(DateTime.now());

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Top color bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: _statusColor(booking.status),
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            booking.meetingType == 'online'
                                ? Icons.video_camera_front_outlined
                                : Icons.location_on_outlined,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.meetingType == 'online'
                                  ? 'Online Consultation'
                                  : 'In-Person Consultation',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isUpcoming ? 'Upcoming' : 'Past',
                              style: TextStyle(
                                fontSize: 12,
                                color: isUpcoming
                                    ? AppColors.success
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    _StatusBadge(status: booking.status),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // ── Date & Time
                Row(
                  children: [
                    Expanded(
                      child: _InfoTile(
                        icon: Icons.calendar_today_outlined,
                        label: 'Date',
                        value: DateFormat('MMM dd, yyyy')
                            .format(booking.bookingDate),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InfoTile(
                        icon: Icons.access_time_outlined,
                        label: 'Time',
                        value: booking.bookingTime,
                      ),
                    ),
                  ],
                ),

                if (booking.paymentAmount != null) ...[
                  const SizedBox(height: 12),
                  _InfoTile(
                    icon: Icons.payment_outlined,
                    label: 'Fee',
                    value: '৳${booking.paymentAmount!.toStringAsFixed(2)}',
                  ),
                ],

                if (booking.notes != null &&
                    booking.notes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.greyLight.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.notes_outlined,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            booking.notes!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // ── Action buttons
                Row(
                  children: [
                    if (booking.meetingType == 'online' &&
                        booking.meetingLink != null &&
                        isUpcoming)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            launchUrl(Uri.parse(booking.meetingLink!));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.videocam, size: 18),
                          label: const Text('Join Meeting'),
                        ),
                      ),
                    if (booking.meetingType == 'online' &&
                        booking.meetingLink != null &&
                        isUpcoming &&
                        booking.status != 'cancelled')
                      const SizedBox(width: 12),
                    if (booking.status != 'cancelled')
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              _showCancelDialog(context, ref),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side:
                            const BorderSide(color: AppColors.error),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                    if (!isUpcoming || booking.status == 'completed')
                      const SizedBox(width: 12),
                    if (!isUpcoming || booking.status == 'completed')
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              context.push('/booking'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(
                                color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Book Again'),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'cancelled':
        return AppColors.error;
      case 'completed':
        return AppColors.primary;
      default:
        return AppColors.grey;
    }
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text(
          'Are you sure you want to cancel this booking?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              onCancel();
              SupabaseService.cancelBooking(booking.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Booking cancelled'),
                  backgroundColor: AppColors.error,
                ),
              );
              ref.invalidate(bookingsProvider);
            },
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helper Widgets ───────────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'confirmed':
        bgColor = AppColors.success.withOpacity(0.1);
        textColor = AppColors.success;
        break;
      case 'pending':
        bgColor = AppColors.warning.withOpacity(0.1);
        textColor = AppColors.warning;
        break;
      case 'cancelled':
        bgColor = AppColors.error.withOpacity(0.1);
        textColor = AppColors.error;
        break;
      case 'completed':
        bgColor = AppColors.primary.withOpacity(0.1);
        textColor = AppColors.primary;
        break;
      default:
        bgColor = AppColors.greyLight;
        textColor = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}