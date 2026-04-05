import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subtracker/features/auth/widgets/auth_form_field.dart';

void main() {
  group('AuthFormField', () {
    testWidgets('renders label text', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthFormField(
              controller: controller,
              label: 'Email',
            ),
          ),
        ),
      );

      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('renders hint text', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthFormField(
              controller: controller,
              label: 'Email',
              hintText: 'you@example.com',
            ),
          ),
        ),
      );

      expect(find.text('you@example.com'), findsOneWidget);
    });

    testWidgets('obscures text when obscureText is true', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthFormField(
              controller: controller,
              label: 'Password',
              obscureText: true,
            ),
          ),
        ),
      );

      final editableText =
          tester.widget<EditableText>(find.byType(EditableText));
      expect(editableText.obscureText, isTrue);
    });

    testWidgets('does not obscure text by default', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthFormField(
              controller: controller,
              label: 'Email',
            ),
          ),
        ),
      );

      final editableText =
          tester.widget<EditableText>(find.byType(EditableText));
      expect(editableText.obscureText, isFalse);
    });

    testWidgets('calls validator on form submission', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: Column(
                children: [
                  AuthFormField(
                    controller: controller,
                    label: 'Email',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required field';
                      }
                      return null;
                    },
                  ),
                  ElevatedButton(
                    onPressed: () => formKey.currentState!.validate(),
                    child: const Text('Submit'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      expect(find.text('Required field'), findsOneWidget);
    });

    testWidgets('validator passes for valid input', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: Column(
                children: [
                  AuthFormField(
                    controller: controller,
                    label: 'Email',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required field';
                      }
                      return null;
                    },
                  ),
                  ElevatedButton(
                    onPressed: () => formKey.currentState!.validate(),
                    child: const Text('Submit'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'user@example.com');
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      expect(find.text('Required field'), findsNothing);
    });

    testWidgets('sets autofocus on the underlying TextField', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthFormField(
              controller: controller,
              label: 'Email',
              autofocus: true,
            ),
          ),
        ),
      );

      // The TextFormField delegates autofocus to TextField.
      // Verify the field has focus after build.
      final focusNode = FocusScope.of(
        tester.element(find.byType(TextFormField)),
      );
      expect(focusNode.hasFocus, isTrue);
    });

    testWidgets('calls onFieldSubmitted when user submits', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      var submitted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthFormField(
              controller: controller,
              label: 'Password',
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => submitted = true,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'test');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(submitted, isTrue);
    });

    testWidgets('has Semantics wrapper', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthFormField(
              controller: controller,
              label: 'Email',
            ),
          ),
        ),
      );

      // AuthFormField wraps content in a Semantics widget.
      final semantics = tester.widgetList<Semantics>(find.byType(Semantics));
      expect(
        semantics.any((s) => s.properties.label == 'Email'),
        isTrue,
      );
    });

    testWidgets('sets keyboard type', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthFormField(
              controller: controller,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
            ),
          ),
        ),
      );

      final editableText =
          tester.widget<EditableText>(find.byType(EditableText));
      expect(editableText.keyboardType, TextInputType.emailAddress);
    });
  });
}
