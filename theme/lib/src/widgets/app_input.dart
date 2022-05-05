import 'dart:async';

import 'package:flutter/material.dart';
import 'package:theme/src/data/typography_data.dart';
import 'package:theme/src/theme_resolver.dart';
import 'package:theme/src/widgets/app_text.dart';
import 'package:theme/src/widgets/tooltip_shape_border.dart';

class AppInput extends StatefulWidget {
  const AppInput.primary({
    Key? key,
    required this.hintText,
    required this.onChanged,
    this.errorText,
    this.icon,
    this.obscureText = false,
    this.showHiddenInput,
    this.keyboardType,
    this.textInputAction,
  }) : super(key: key);

  final IconData? icon;
  final String hintText;
  final bool obscureText;
  final String? errorText;
  final VoidCallback? showHiddenInput;
  final Function(String)? onChanged;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  Timer? _debounce;
  String textBeingTyped = '';
  bool showErrorTooltip = false;

  final FocusNode _focusNode = FocusNode();
  final TextEditingController _controller = TextEditingController();

  bool get inputIsFilled => textBeingTyped.isNotEmpty;
  bool get inputIsInvalid => widget.errorText != null;

  void _remember(String text) {
    setState(() {
      textBeingTyped = text;
    });
  }

  final _debounceDuration = const Duration(milliseconds: 500);
  _debounceErrorEvaluation() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    setState(() {
      showErrorTooltip = false;
    });
    _debounce = Timer(_debounceDuration, () {
      setState(() {
        showErrorTooltip = inputIsInvalid;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    super.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
  }

  void _onFocusChange() {
    setState(() {
      showErrorTooltip = !_focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeResolver.of(context);
    return Stack(clipBehavior: Clip.none, children: [
      TextField(
        focusNode: _focusNode,
        controller: _controller,
        onChanged: (str) {
          if (widget.onChanged != null) {
            widget.onChanged!(str);
          }

          _remember(str);
          _debounceErrorEvaluation();
        },
        keyboardType: widget.keyboardType,
        autofillHints: const [AutofillHints.email],
        obscureText: widget.obscureText,
        textInputAction: widget.textInputAction,
        style: TypographyData.main(theme.colors)
            .titleLarge
            .copyWith(color: theme.colors.sunrise),
        cursorColor: theme.colors.eclipse,
        decoration: InputDecoration(
          fillColor: theme.colors.lightSkin,
          filled: true,
          hintText: widget.hintText,
          hintStyle: TypographyData.main(theme.colors)
              .titleSmall
              .copyWith(color: theme.colors.eclipse.withOpacity(0.5)),
          prefixIcon: widget.icon != null
              ? Padding(
                  padding: EdgeInsets.symmetric(horizontal: theme.sizes.m),
                  child: Icon(
                    widget.icon,
                    color: inputIsFilled
                        ? theme.colors.sunrise
                        : theme.colors.eclipse.withOpacity(0.5),
                  ),
                )
              : null,
          suffix: (widget.showHiddenInput != null)
              ? GestureDetector(
                  onTap: widget.showHiddenInput,
                  child: AppText.p3("Show",
                      textDecoration: TextDecoration.underline),
                )
              : null,
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(theme.sizes.s),
          ),
        ),
      ),
      if (showErrorTooltip && inputIsFilled && _focusNode.hasFocus)
        _ErrorTooltip(widget: widget),
    ]);
  }
}

class _ErrorTooltip extends StatefulWidget {
  const _ErrorTooltip({
    Key? key,
    required this.widget,
  }) : super(key: key);

  final AppInput widget;

  @override
  State<_ErrorTooltip> createState() => _ErrorTooltipState();
}

class _ErrorTooltipState extends State<_ErrorTooltip>
    with TickerProviderStateMixin {
  late AnimationController _opacityController;
  late AnimationController _scaleController;

  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _opacityController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _opacityAnimation =
        CurvedAnimation(parent: _opacityController, curve: Curves.easeIn);

    _scaleController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500), value: 0.3);
    _scaleAnimation =
        CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack);

    _scaleController.forward();
    _opacityController.forward();
  }

  @override
  void dispose() {
    _opacityController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeResolver.of(context);

    return Positioned(
      top: -40,
      left: 20,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            decoration: ShapeDecoration(
              color: Colors.red,
              shape: TooltipShapeBorder(arrowArc: 0.3, radius: theme.sizes.xs),
              shadows: const [
                BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4.0,
                    offset: Offset(2, 2))
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(theme.sizes.m),
              child: AppText.p4(widget.widget.errorText!, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
