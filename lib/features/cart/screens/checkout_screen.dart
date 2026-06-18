import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/services/supabase_service.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? buyNowData;

  const CheckoutScreen({super.key, this.buyNowData});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedPaymentMethod = 'Cash on Delivery';
  bool _isProcessing = false;

  final List<String> _paymentMethods = [
    'Cash on Delivery',
    'bKash',
  ];

  // ✅ buyNow কিনা check
  bool get _isBuyNow =>
      widget.buyNowData != null && widget.buyNowData!['buyNow'] == true;

  // ✅ total amount calculate
  double get _orderTotal {
    if (_isBuyNow) {
      final price = (widget.buyNowData!['price'] as num).toDouble();
      final qty = widget.buyNowData!['quantity'] as int;
      return price * qty;
    }
    return ref.read(cartTotalProvider);
  }

  // ✅ item count
  int get _itemCount {
    if (_isBuyNow) {
      return widget.buyNowData!['quantity'] as int;
    }
    return ref.read(cartProvider).maybeWhen(
      data: (items) => items.length,
      orElse: () => 0,
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _zipCodeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPaymentMethod == 'bKash') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('bKash payment coming soon'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('User not logged in');

      final shippingAddress = {
        'full_name': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'zip_code': _zipCodeController.text.trim(),
      };

      List<Map<String, dynamic>> orderItems;
      double totalAmount;

      if (_isBuyNow) {
        // ✅ Buy Now — single product
        orderItems = [
          {
            'product_id': widget.buyNowData!['productId'],
            'package_id': null,
            'quantity': widget.buyNowData!['quantity'],
            'price': widget.buyNowData!['price'],
            'is_package': false,
            'customizations': widget.buyNowData!['customizations'],
          }
        ];
        totalAmount = _orderTotal;
      } else {
        // ✅ Cart checkout
        final cartAsyncValue = ref.read(cartProvider);
        final cartItems = cartAsyncValue.maybeWhen(
          data: (items) => items,
          orElse: () => [],
        );

        if (cartItems.isEmpty) throw Exception('Cart is empty');

        totalAmount = ref.read(cartTotalProvider);
        orderItems = cartItems
            .map((item) => {
          'product_id': item.productId,
          'package_id': item.packageId,
          'quantity': item.quantity,
          'price': item.itemPrice,
          'is_package': item.isPackage,
          'customizations': item.customizations,
        })
            .toList();
      }

      await SupabaseService.createOrder(
        userId: user.id,
        totalAmount: totalAmount,
        shippingAddress: shippingAddress,
        paymentMethod: _selectedPaymentMethod,
        items: orderItems,
      );

      // ✅ Cart checkout হলেই cart clear করবে, Buy Now তে না
      if (!_isBuyNow) {
        await ref.read(cartProvider.notifier).clearCart();
      }

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(child: Text('Order Placed!')),
              ],
            ),
            content: const Text(
              'Your order has been placed successfully. You can track your order from your profile.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/home');
                },
                child: const Text('Go to Home'),
              ),
              CustomButton(
                text: 'View Orders',
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/profile/orders');
                },
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ buyNow হলে cartProvider watch করার দরকার নেই
    if (_isBuyNow) {
      return _buildScaffold(context, isReady: true);
    }

    final cartAsync = ref.watch(cartProvider);
    return cartAsync.when(
      data: (items) => _buildScaffold(context, isReady: items.isNotEmpty),
      loading: () => const Scaffold(body: LoadingWidget()),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context, {required bool isReady}) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: !isReady
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_cart_outlined,
                size: 80, color: AppColors.grey),
            const SizedBox(height: 16),
            const Text('Your cart is empty'),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Start Shopping',
              onPressed: () => context.go('/home'),
            ),
          ],
        ),
      )
          : Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Shipping Address'),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Full Name',
                    hint: 'Enter your full name',
                    controller: _fullNameController,
                    prefixIcon: const Icon(Icons.person_outline),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Please enter your full name'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Phone Number',
                    hint: 'Enter your phone number',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    prefixIcon: const Icon(Icons.phone_outlined),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Please enter your phone number'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Address',
                    hint: 'Enter your street address',
                    controller: _addressController,
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    maxLines: 2,
                    validator: (value) => value == null || value.isEmpty
                        ? 'Please enter your address'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'City',
                          hint: 'Enter city',
                          controller: _cityController,
                          validator: (value) =>
                          value == null || value.isEmpty
                              ? 'Required'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomTextField(
                          label: 'ZIP Code',
                          hint: 'Enter ZIP',
                          controller: _zipCodeController,
                          keyboardType: TextInputType.number,
                          validator: (value) =>
                          value == null || value.isEmpty
                              ? 'Required'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Payment Method'),
                  const SizedBox(height: 16),
                  ..._paymentMethods.map((method) {
                    return RadioListTile<String>(
                      value: method,
                      groupValue: _selectedPaymentMethod,
                      onChanged: (value) {
                        setState(() => _selectedPaymentMethod = value!);
                      },
                      title: Row(
                        children: [
                          Icon(
                            method == 'Cash on Delivery'
                                ? Icons.money
                                : Icons.account_balance_wallet,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(method),
                        ],
                      ),
                      activeColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                    );
                  }),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Order Notes (Optional)'),
                  const SizedBox(height: 16),
                  CustomTextField(
                    hint: 'Any special instructions for your order',
                    controller: _notesController,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Order Summary'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.greyLight.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        // ✅ buyNow হলে product name দেখাবে
                        if (_isBuyNow)
                          _buildSummaryRow(
                            widget.buyNowData!['name'] as String,
                            'x${widget.buyNowData!['quantity']}',
                          ),
                        if (!_isBuyNow)
                          _buildSummaryRow(
                            '${_itemCount} item${_itemCount > 1 ? 's' : ''}',
                            '৳${ref.watch(cartTotalProvider).toStringAsFixed(2)}',
                          ),
                        const SizedBox(height: 8),
                        _buildSummaryRow(
                          'Shipping',
                          'Free',
                          valueColor: AppColors.success,
                        ),
                        const SizedBox(height: 8),
                        _buildSummaryRow('Tax', '৳0.00'),
                        const Divider(height: 24),
                        _buildSummaryRow(
                          'Total',
                          '৳${_orderTotal.toStringAsFixed(2)}',
                          isTotal: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const LoadingWidget(
                  message: 'Processing your order...'),
            ),
        ],
      ),
      bottomNavigationBar: !isReady
          ? null
          : Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: CustomButton(
            text: 'Place Order',
            onPressed: _isProcessing ? null : _placeOrder,
            isLoading: _isProcessing,
            width: double.infinity,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildSummaryRow(
      String label,
      String value, {
        bool isTotal = false,
        Color? valueColor,
      }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: valueColor ??
                (isTotal ? AppColors.primary : AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}