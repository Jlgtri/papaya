import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../generated/i18n.g.dart';
import '../../hooks/sync_callback_hook.dart';

/// The screen used to edit user's profile.
class ProfileEditScreen extends HookConsumerWidget {
  /// The screen used to edit user's profile.
  const ProfileEditScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final NavigatorState navigator = Navigator.of(context);
    final I18N $ = I18NLocalizations.of(context);

    final SyncCallback syncCallback = useSyncCallback();
    final TextEditingController firstNameController =
        useTextEditingController(text: 'Jonathan');
    final TextEditingController lastNameController =
        useTextEditingController(text: 'Smith');
    final TextEditingController phoneController =
        useTextEditingController(text: '+1 (212) 200 7898');
    final TextEditingController emailController =
        useTextEditingController(text: 'jonathansmith@example.com');

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: theme.colorScheme.surface,
      ),
      child: SafeArea(
        child: KeyboardDismissOnTap(
          child: Material(
            clipBehavior: Clip.antiAlias,
            color: theme.colorScheme.surface,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Padding(
              padding: mediaQuery.viewInsets,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  /// Grab Widget
                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Material(
                        color: theme.colorScheme.onSurface,
                        clipBehavior: Clip.antiAlias,
                        borderRadius: BorderRadius.circular(4),
                        child: const SizedBox(height: 4, width: 36),
                      ),
                    ),
                  ),

                  /// Title
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Text(
                      $.profile.edit.title,
                      style: theme.textTheme.displayMedium,
                    ),
                  ),

                  /// Input Form
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: ColoredBox(
                        color: theme.colorScheme.surfaceTint,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              /// First Name Title
                              Flexible(
                                child: Text(
                                  $.profile.edit.firstName,
                                  style: theme.textTheme.titleMedium,
                                  maxLines: 1,
                                ),
                              ),

                              /// First Name Field
                              const SizedBox(height: 16),
                              TextField(
                                autocorrect: false,
                                autofillHints: null,
                                controller: firstNameController,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: theme.colorScheme.surface,
                                  hintText: $.profile.edit.firstNameHint,
                                ),
                                inputFormatters: <TextInputFormatter>[
                                  LengthLimitingTextInputFormatter(64),
                                ],
                              ),

                              /// Last Name Title
                              const SizedBox(height: 24),
                              Flexible(
                                child: Text(
                                  $.profile.edit.lastName,
                                  style: theme.textTheme.titleMedium,
                                  maxLines: 1,
                                ),
                              ),

                              /// Last Name Field
                              const SizedBox(height: 16),
                              TextField(
                                autocorrect: false,
                                autofillHints: null,
                                controller: lastNameController,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: theme.colorScheme.surface,
                                  hintText: $.profile.edit.lastNameHint,
                                ),
                                inputFormatters: <TextInputFormatter>[
                                  LengthLimitingTextInputFormatter(64),
                                ],
                              ),

                              /// Phone Title
                              const SizedBox(height: 24),
                              Flexible(
                                child: Text(
                                  $.profile.edit.phone,
                                  style: theme.textTheme.titleMedium,
                                  maxLines: 1,
                                ),
                              ),

                              /// Phone Field
                              const SizedBox(height: 16),
                              TextField(
                                autocorrect: false,
                                autofillHints: null,
                                controller: phoneController,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: theme.colorScheme.surface,
                                  hintText: $.profile.edit.phoneHint,
                                ),
                                inputFormatters: <TextInputFormatter>[
                                  LengthLimitingTextInputFormatter(32),
                                ],
                              ),

                              /// Email Title
                              const SizedBox(height: 24),
                              Flexible(
                                child: Text(
                                  $.profile.edit.email,
                                  style: theme.textTheme.titleMedium,
                                  maxLines: 1,
                                ),
                              ),

                              /// Email Field
                              const SizedBox(height: 16),
                              TextField(
                                autocorrect: false,
                                autofillHints: null,
                                controller: emailController,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: theme.colorScheme.surface,
                                  hintText: $.profile.edit.email,
                                ),
                                inputFormatters: <TextInputFormatter>[
                                  LengthLimitingTextInputFormatter(256),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  /// Confirm
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
                            .copyWith(bottom: 7),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(),
                      onPressed: () async => syncCallback(navigator.maybePop),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Text($.profile.edit.confirm),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
