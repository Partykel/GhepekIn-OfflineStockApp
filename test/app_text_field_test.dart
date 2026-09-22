import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghepek_in/main.dart';
import 'package:ghepek_in/shared/constants/app_colors.dart';
import 'package:ghepek_in/shared/widgets/app_text_field.dart';

void main() {
  testWidgets('Input inherits app theme and preserves disabled styling', (
    tester,
  ) async {
    for (final enabled in [true, false]) {
      await tester.pumpWidget(
        Builder(
          builder: (context) => MaterialApp(
            theme: (const GhepekInApp().build(context) as MaterialApp).theme,
            home: Scaffold(
              body: AppTextField(label: 'Produk', enabled: enabled),
            ),
          ),
        ),
      );
      final decoration = tester
          .widget<InputDecorator>(find.byType(InputDecorator))
          .decoration;
      final theme = Theme.of(
        tester.element(find.byType(AppTextField)),
      ).inputDecorationTheme;
      expect(decoration.filled, isTrue);
      expect(decoration.contentPadding, theme.contentPadding);
      expect(decoration.enabledBorder, theme.enabledBorder);
      expect(decoration.focusedBorder, theme.focusedBorder);
      expect(decoration.errorBorder, theme.errorBorder);
      expect(decoration.focusedErrorBorder, theme.focusedErrorBorder);
      expect(
        decoration.fillColor,
        enabled ? AppColors.surface : AppColors.surfaceMuted,
      );
      expect(decoration.disabledBorder, theme.enabledBorder);
    }
  });
}
