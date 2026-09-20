import 'package:flutter/material.dart';
import '../core/localization/app_locale.dart';
import '../theme/app_theme.dart';

class CustomDropDownMenu extends StatefulWidget {
  const CustomDropDownMenu({
    super.key,
    this.dropdownWidth,
    required this.dropdownItems,
    this.value,
    required this.onChanged,
    this.validator,
    this.isTextTranslated = false,
    this.enabled = true,
    this.isShowLoading = true,
    this.label,
    this.suffixIcon,
    this.hint,
    this.disabledBorder,
    this.enabledBorder,
    this.focusedBorder,
    this.errorBorder,
    this.autoValidateMode = AutovalidateMode.onUserInteraction,
    this.onChangedIndex,
    this.isDense = false,
    this.contentPadding,
  });

  final double? dropdownWidth;
  final List<String> dropdownItems;
  final bool isTextTranslated;
  final String? value;
  final void Function(String? value) onChanged;
  final void Function(int? value)? onChangedIndex;
  final String? Function(String?)? validator;
  final String? label;
  final String? hint;
  final bool enabled;
  final bool isShowLoading;
  final Widget? suffixIcon;
  final InputBorder? disabledBorder;
  final InputBorder? enabledBorder;
  final InputBorder? focusedBorder;
  final InputBorder? errorBorder;
  final AutovalidateMode autoValidateMode;
  final bool isDense;
  final EdgeInsetsGeometry? contentPadding;

  @override
  State<CustomDropDownMenu> createState() => _CustomDropDownMenuState();
}

class _CustomDropDownMenuState extends State<CustomDropDownMenu> {
  late TextEditingController _controller;
  late ScrollController _scrollController;
  final GlobalKey _textFieldKey = GlobalKey();

  Future<void> _showPopupMenu(BuildContext context) async {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final RenderBox? renderBox =
        _textFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    // Use custom width if provided, otherwise use the width of the TextFormField
    final double menuWidth = widget.dropdownWidth ?? size.width;
    final double maxHeight = MediaQuery.sizeOf(context).height * 0.35;

    final value = await showMenu<String>(
      context: context,
      popUpAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        reverseDuration: Duration(milliseconds: 100),
        reverseCurve: Curves.easeInOut,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      color: AppColors.surface,
      position: !isRtl
          ? RelativeRect.fromLTRB(
              offset.dx,
              offset.dy + size.height + 4,
              offset.dx,
              offset.dy,
            )
          : RelativeRect.fromLTRB(
              offset.dx - (isRtl ? menuWidth - size.width : 0),
              offset.dy + size.height + 4,
              offset.dx + (isRtl ? menuWidth : size.width),
              offset.dy,
            ),
      items: [
        PopupMenuItem<String>(
          value: '',
          enabled: false,
          padding: EdgeInsets.zero,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Scrollbar(
              thumbVisibility: true,
              controller: _scrollController,
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    widget.dropdownItems.length,
                    (index) {
                      final item = widget.dropdownItems[index];
                      final displayText = widget.isTextTranslated
                          ? item.tr(context)
                          : item;
                      return PopupMenuItem<String>(
                        value: item,
                        child: Text(
                          displayText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
      elevation: 20.0,
      shadowColor: Colors.black,
      constraints: BoxConstraints(
        minWidth: menuWidth,
        maxWidth: menuWidth,
        maxHeight: maxHeight,
      ),
    );

    if (value != null && value.isNotEmpty && context.mounted) {
      widget.isTextTranslated
          ? _controller.text = value.tr(context)
          : _controller.text = value;
      if (widget.onChangedIndex != null) {
        widget.onChangedIndex!(widget.dropdownItems.indexOf(value));
      }

      widget.onChanged(value);
    }
  }

  bool get isLoading {
    return widget.dropdownItems.isEmpty && widget.isShowLoading;
  }

  @override
  void didUpdateWidget(covariant CustomDropDownMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.isTextTranslated
            ? _controller.text = widget.value?.tr(context) ?? ''
            : _controller.text = widget.value ?? '';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.value != null && widget.value!.isNotEmpty) {
        widget.isTextTranslated
            ? _controller.text = widget.value!.tr(context)
            : _controller.text = widget.value!;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: _textFieldKey,
      onTap: () {
        if (!isLoading && widget.enabled) {
          _showPopupMenu(context);
        }
      },
      autovalidateMode: widget.autoValidateMode,
      enabled: widget.enabled,
      controller: _controller,
      readOnly: true,
      validator: widget.validator,
      keyboardType: TextInputType.none,
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle:
            const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        floatingLabelStyle:
            const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        hintText: widget.hint,
        hintStyle:
            const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        suffixIcon: suffixIcon,
        disabledBorder: widget.disabledBorder,
        errorBorder: widget.errorBorder,
        enabledBorder: widget.enabledBorder,
        focusedBorder: widget.focusedBorder,
        isDense: widget.isDense,
        contentPadding: widget.contentPadding,
      ),
    );
  }

  Widget get suffixIcon {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (widget.suffixIcon == null) {
      return const Icon(
        Icons.keyboard_arrow_down_outlined,
        color: AppColors.textSecondary,
        size: 20,
      );
    } else {
      return widget.suffixIcon!;
    }
  }
}
