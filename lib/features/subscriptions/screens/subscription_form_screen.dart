import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:subtracker/core/extensions/datetime_extensions.dart';
import 'package:subtracker/core/widgets/centered_content.dart';
import 'package:subtracker/core/widgets/responsive_layout.dart';
import 'package:subtracker/features/subscriptions/models/billing_cycle.dart';
import 'package:subtracker/features/subscriptions/models/subscription_category.dart';
import 'package:subtracker/features/subscriptions/providers/subscription_providers.dart';

class SubscriptionFormScreen extends ConsumerStatefulWidget {
  const SubscriptionFormScreen({super.key, this.subscriptionId});

  final String? subscriptionId;

  bool get isEditing => subscriptionId != null;

  @override
  ConsumerState<SubscriptionFormScreen> createState() =>
      _SubscriptionFormScreenState();
}

class _SubscriptionFormScreenState
    extends ConsumerState<SubscriptionFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;

  BillingCycle _billingCycle = BillingCycle.monthly;
  SubscriptionCategory _category = SubscriptionCategory.other;
  DateTime _startDate = DateTime.now();
  String _currency = 'EUR';
  bool _isActive = true;
  bool _initialized = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _amountController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(subscriptionsNotifierProvider.notifier);
      final amount = double.parse(_amountController.text.replaceAll(',', '.'));

      if (widget.isEditing) {
        final existing =
            ref.read(subscriptionByIdProvider(widget.subscriptionId!));
        if (existing != null) {
          await notifier.updateSubscription(
            existing.copyWith(
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
              amount: amount,
              currency: _currency,
              billingCycle: _billingCycle,
              category: _category,
              startDate: _startDate,
              nextBillingDate: _billingCycle.nextBillingDate(_startDate),
              isActive: _isActive,
            ),
          );
        }
      } else {
        await notifier.create(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          amount: amount,
          currency: _currency,
          billingCycle: _billingCycle,
          category: _category,
          startDate: _startDate,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditing
                  ? '"${_nameController.text}" updated'
                  : '"${_nameController.text}" added',
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        context.pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${error.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subscription'),
        content:
            const Text('Are you sure you want to delete this subscription?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);

      try {
        await ref
            .read(subscriptionsNotifierProvider.notifier)
            .delete(widget.subscriptionId!);

        if (mounted) {
          context.pop();
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Delete failed: ${error.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Load existing data if editing
    if (widget.isEditing && !_initialized) {
      final existing =
          ref.watch(subscriptionByIdProvider(widget.subscriptionId!));
      if (existing != null) {
        _nameController.text = existing.name;
        _amountController.text = existing.amount.toStringAsFixed(2);
        _descriptionController.text = existing.description ?? '';
        _billingCycle = existing.billingCycle;
        _category = existing.category;
        _startDate = existing.startDate;
        _currency = existing.currency;
        _isActive = existing.isActive;
        _initialized = true;
      }
    }

    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !isDesktop,
        titleSpacing: isDesktop ? 0 : null,
        title: isDesktop
            ? CenteredContent(
                maxWidth: 500,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.pop(),
                      tooltip: 'Back',
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.isEditing
                          ? 'Edit Subscription'
                          : 'Add Subscription',
                    ),
                    const Spacer(),
                    if (widget.isEditing)
                      IconButton(
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.delete_outline),
                        onPressed: _isLoading ? null : _delete,
                        tooltip: 'Delete',
                      ),
                  ],
                ),
              )
            : Text(
                widget.isEditing ? 'Edit Subscription' : 'Add Subscription',
              ),
        actions: isDesktop
            ? const [SizedBox.shrink()]
            : [
                if (widget.isEditing)
                  IconButton(
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_outline),
                    onPressed: _isLoading ? null : _delete,
                    tooltip: 'Delete',
                  ),
              ],
      ),
      body: CenteredContent(
        maxWidth: 500,
        padding: EdgeInsets.zero,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g., Netflix, Spotify',
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        hintText: '9.99',
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+[,.]?\d{0,2}'),
                        ),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final amount =
                            double.tryParse(value.replaceAll(',', '.'));
                        if (amount == null || amount <= 0) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _currency,
                      decoration: const InputDecoration(
                        labelText: 'Currency',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                        DropdownMenuItem(value: 'USD', child: Text('USD')),
                        DropdownMenuItem(value: 'GBP', child: Text('GBP')),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _currency = value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<BillingCycle>(
                value: _billingCycle,
                decoration: const InputDecoration(
                  labelText: 'Billing Cycle',
                ),
                items: BillingCycle.values.map((cycle) {
                  return DropdownMenuItem(
                      value: cycle, child: Text(cycle.label));
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _billingCycle = value);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<SubscriptionCategory>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                ),
                items: SubscriptionCategory.values.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Row(
                      children: [
                        Icon(cat.icon, size: 20, color: cat.color),
                        const SizedBox(width: 8),
                        Text(cat.label),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _category = value);
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Start Date',
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_startDate.formatted),
                      const Icon(Icons.calendar_today_outlined, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Add notes about this subscription',
                ),
                maxLines: 2,
              ),
              if (widget.isEditing) ...[
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Active'),
                  subtitle: const Text('Pause to stop tracking'),
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Saving...'),
                        ],
                      )
                    : Text(
                        widget.isEditing ? 'Save Changes' : 'Add Subscription'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
