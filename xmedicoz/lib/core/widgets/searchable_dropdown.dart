import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_typography.dart';
import '../utils/text_search.dart';
import 'app_button.dart';

/// Shared searchable selector for catalog records and invoice lines.
class SearchableDropdown<T> extends FormField<T> {
  SearchableDropdown({
    super.key,
    required this.items,
    required this.label,
    required this.onChanged,
    this.value,
    this.decoration,
    super.validator,
    this.loadItems,
    this.itemName = 'medicine',
    this.itemPlural = 'medicines',
    this.itemIcon = Icons.medication_outlined,
    super.onSaved,
    super.autovalidateMode,
  }) : super(
         initialValue: value,
         builder: (FormFieldState<T> field) {
           final _SearchableDropdownState<T> state =
               field as _SearchableDropdownState<T>;
           return state._buildWidget(field);
         },
       );

  final String itemName;
  final String itemPlural;
  final IconData itemIcon;
  final List<T> items;
  final T? value;
  final String Function(T) label;
  final ValueChanged<T?> onChanged;
  final InputDecoration? decoration;
  final Future<List<T>> Function()? loadItems;

  @override
  FormFieldState<T> createState() => _SearchableDropdownState<T>();
}

class _SearchableDropdownState<T> extends FormFieldState<T> {
  bool _open = false;

  SearchableDropdown<T> get _dropdown => widget as SearchableDropdown<T>;

  @override
  void didUpdateWidget(covariant SearchableDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != _dropdown.value) {
      setValue(_dropdown.value);
    }
  }

  @override
  void reset() {
    super.reset();
    setValue(_dropdown.value);
  }

  Future<void> _show() async {
    if (_open) return;
    _open = true;
    FocusScope.of(context).unfocus();
    try {
      final selected = await showDialog<T>(
        context: context,
        useRootNavigator: true,
        builder: (_) => _SearchDialog<T>(
          items: _dropdown.items,
          label: _dropdown.label,
          loadItems: _dropdown.loadItems,
          itemName: _dropdown.itemName,
          itemPlural: _dropdown.itemPlural,
          itemIcon: _dropdown.itemIcon,
        ),
      );
      if (!mounted || selected == null) return;
      didChange(selected);
      _dropdown.onChanged(selected);
    } finally {
      _open = false;
    }
  }

  Widget _buildWidget(FormFieldState<T> field) {
    final effectiveValue = value ?? _dropdown.value;
    return InkWell(
      onTap: _show,
      borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
      child: InputDecorator(
        isEmpty: effectiveValue == null,
        decoration:
            (_dropdown.decoration ??
                    AppDecorations.inputDecoration(hintText: 'Select medicine'))
                .copyWith(errorText: field.errorText),
        child: Row(
          children: [
            Expanded(
              child: Text(
                effectiveValue == null ? '' : _dropdown.label(effectiveValue),
                style: AppTypography.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary,
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchDialog<T> extends StatefulWidget {
  const _SearchDialog({
    required this.items,
    required this.label,
    this.loadItems,
    required this.itemName,
    required this.itemPlural,
    required this.itemIcon,
  });
  final String itemName;
  final String itemPlural;
  final IconData itemIcon;
  final List<T> items;
  final String Function(T) label;
  final Future<List<T>> Function()? loadItems;

  @override
  State<_SearchDialog<T>> createState() => _SearchDialogState<T>();
}

class _SearchDialogState<T> extends State<_SearchDialog<T>> {
  final _text = TextEditingController();
  final _focus = FocusNode();
  Animation<double>? _routeAnimation;
  bool _started = false;
  bool _closing = false;

  void _close([T? value]) {
    if (_closing) return;
    _closing = true;
    _focus.unfocus();
    Navigator.pop(context, value);
  }

  final _scroll = ScrollController();
  final _query = ''.obs;
  final _loading = false.obs;
  final _failed = false.obs;
  final _revision = 0.obs;
  late List<T> _items;
  late List<String> _labels;

  void _index(List<T> items) {
    _items = List.of(items);
    _labels = _items.map((item) => widget.label(item).toLowerCase()).toList();
  }

  @override
  void initState() {
    super.initState();
    _index(widget.items);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animation = ModalRoute.of(context)?.animation;
    if (_routeAnimation != animation) {
      _routeAnimation?.removeStatusListener(_onRouteStatus);
      _routeAnimation = animation;
      animation?.addStatusListener(_onRouteStatus);
    }
    if (animation == null || animation.status == AnimationStatus.completed) {
      _onRouteStatus(AnimationStatus.completed);
    }
  }

  void _onRouteStatus(AnimationStatus status) {
    if (status == AnimationStatus.reverse) _closing = true;
    if (status == AnimationStatus.completed && !_started && !_closing) {
      _started = true;
      _focus.requestFocus(); // Smoothly open keyboard AFTER dialog animation
      _load();
    }
  }

  Future<void> _load() async {
    if (widget.loadItems == null || _loading.value || _closing) return;
    _loading.value = true;
    _failed.value = false;
    try {
      final items = await widget.loadItems!();
      if (!mounted || _closing) return;
      _index(items);
      _revision.value++;
    } catch (_) {
      if (mounted && !_closing) _failed.value = true;
    } finally {
      if (mounted && !_closing) _loading.value = false;
    }
  }

  void _search(String value) {
    _query.value = TextSearch.normalize(value);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_onRouteStatus);
    _focus.dispose();
    _text.dispose();
    _scroll.dispose();
    _query.close();
    _loading.close();
    _failed.close();
    _revision.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope<T>(
    onPopInvokedWithResult: (didPop, result) {
      if (didPop) {
        _closing = true;
        _focus.unfocus();
      }
    },
    child: Dialog(
      alignment: Alignment.topCenter,
      insetAnimationDuration: Duration.zero,
      backgroundColor: AppColors.bgSurface,
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      child: SizedBox(
        width: 520.w.clamp(0, 600),
        height: 480.h,
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    widget.itemIcon,
                    color: AppColors.primaryEmerald,
                    size: 22.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Find ${widget.itemName}',
                      style: AppTypography.labelBold,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => _close(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              TextField(
                controller: _text,
                focusNode: _focus,
                onChanged: _search,
                style: AppTypography.bodyMedium,
                decoration: AppDecorations.searchDecoration(
                  hintText: 'Search ${widget.itemPlural}...',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.primaryEmerald,
                  ),
                  suffixIcon: IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      _text.clear();
                      _search('');
                    },
                    icon: const Icon(Icons.clear_rounded),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Obx(
                () => _loading.value
                    ? const LinearProgressIndicator(
                        color: AppColors.primaryEmerald,
                      )
                    : const SizedBox.shrink(),
              ),
              Obx(
                () => _failed.value
                    ? Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Could not load the full list. Showing available ${widget.itemPlural}.',
                              style: AppTypography.bodySmall,
                            ),
                          ),
                          TextButton(
                            onPressed: _load,
                            child: const Text('Retry'),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
              Expanded(
                child: Obx(() {
                  _revision.value;
                  final query = _query.value;
                  final matches = <int>[
                    for (var i = 0; i < _items.length; i++)
                      if (TextSearch.matches(_labels[i], query)) i,
                  ];
                  if (matches.isEmpty) {
                    return Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 36.sp,
                              color: AppColors.primaryEmerald,
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              _loading.value
                                  ? 'Loading ${widget.itemPlural}…'
                                  : query.isEmpty
                                  ? 'No ${widget.itemPlural} available'
                                  : 'No ${widget.itemPlural} match your search',
                              style: AppTypography.labelBold,
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              query.isEmpty
                                  ? 'Add a ${widget.itemName} from the entry screen, then try again.'
                                  : 'Try a different name or clear the search.',
                              style: AppTypography.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 12.h),
                            AppButton(
                              title: query.isEmpty
                                  ? 'Back to entry'
                                  : 'Clear search',
                              onPressed: () {
                                if (query.isEmpty) {
                                  _close();
                                } else {
                                  _text.clear();
                                  _search('');
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return Scrollbar(
                    controller: _scroll,
                    child: ListView.builder(
                      controller: _scroll,
                      itemCount: matches.length,
                      itemBuilder: (context, index) {
                        final item = _items[matches[index]];
                        return ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 4.w,
                            vertical: 4.h,
                          ),
                          leading: Icon(
                            widget.itemIcon,
                            color: AppColors.primaryEmerald,
                            size: 20.sp,
                          ),
                          title: Text(
                            widget.label(item),
                            style: AppTypography.bodyMedium,
                          ),
                          onTap: () => _close(item),
                        );
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
