import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../generated/i18n.g.dart';
import '../../../generated/icons.g.dart';
import '../../../generated/models.g.dart';
import '../../../hooks/sync_callback_hook.dart';
import '../../../providers/api.dart';
import '../../../routes.dart';

/// The screen used to edit user's [profile].
@immutable
class ProfileEditScreen extends HookConsumerWidget {
  /// The screen used to edit user's [profile].
  const ProfileEditScreen(this.profile, {super.key});

  /// The profile being edited on this screen.
  final UserProfileModel profile;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final NavigatorState navigator = Navigator.of(context);
    final I18N $ = I18NLocalizations.of(context);

    final SyncCallback syncCallback = useSyncCallback();
    final List<String> nameParts =
        profile.name?.split(RegExp(r'\s+')) ?? const <String>[];
    final TextEditingController firstNameController = useTextEditingController(
      text:
          profile.givenName ?? (nameParts.isNotEmpty ? nameParts.first : null),
    );
    final TextEditingController lastNameController = useTextEditingController(
      text:
          profile.familyName ?? (nameParts.length > 1 ? nameParts.last : null),
    );
    final TextEditingController phoneController =
        useTextEditingController(text: profile.phone);
    final TextEditingController emailController =
        useTextEditingController(text: profile.email);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
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
              padding: mediaQuery.viewInsets.copyWith(top: 0),
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
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Text(
                      $.profile.edit.title,
                      style: theme.textTheme.displayMedium,
                    ),
                  ),

                  Flexible(
                    child: KeyboardVisibilityBuilder(
                      builder: (final _, final bool isVisible) =>
                          SingleChildScrollView(
                        physics: !isVisible
                            ? const NeverScrollableScrollPhysics()
                            : null,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            /// Input Form
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: ColoredBox(
                                color: theme.colorScheme.surfaceTint,
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: ProfileEditForm(
                                    firstNameController: firstNameController,
                                    lastNameController: lastNameController,
                                    phoneController: phoneController,
                                    emailController: emailController,
                                  ),
                                ),
                              ),
                            ),

                            /// Confirm
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ).copyWith(bottom: 7),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(),
                                onPressed: () async => syncCallback(() async {
                                  final UserProfileModel profile =
                                      (this.profile).copyWith(
                                    givenName: firstNameController.text,
                                    familyName: lastNameController.text,
                                    phone: phoneController.text
                                        .replaceAll(RegExp(r'\D'), ''),
                                    email: emailController.text,
                                  );
                                  try {
                                    await ref
                                        .read(profileProvider(profile).future);
                                    await navigator.maybePop();
                                  } on DioError catch (_, __) {
                                    await navigator.pushNamed(
                                      Routes.profileEditError.name,
                                      arguments: ProfileEditErrorScreen(
                                        profile,
                                        _,
                                        __,
                                      ),
                                    );
                                  }
                                }),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) =>
      super.debugFillProperties(
        properties
          ..add(DiagnosticsProperty<UserProfileModel>('profile', profile)),
      );
}

/// The form used to edit user's profile.
@immutable
class ProfileEditForm extends HookConsumerWidget {
  /// The form used to edit user's profile.
  const ProfileEditForm({
    this.firstNameController,
    this.lastNameController,
    this.phoneController,
    this.emailController,
    super.key,
  });

  /// The controller for the first name field.
  final TextEditingController? firstNameController;

  /// The controller for the last name field.
  final TextEditingController? lastNameController;

  /// The controller for the phone number field.
  final TextEditingController? phoneController;

  /// The controller for the email field.
  final TextEditingController? emailController;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final I18N $ = I18NLocalizations.of(context);
    final PhoneInputFormatter phoneFormatter =
        useMemoized(PhoneInputFormatter.new);
    useMemoized(
      () => WidgetsBinding.instance.addPostFrameCallback((final _) {
        if (phoneController?.text.isNotEmpty ?? false) {
          phoneController!.value = phoneFormatter.formatEditUpdate(
            TextEditingValue.empty,
            TextEditingValue(
              text: phoneController!.text,
              selection: const TextSelection.collapsed(offset: 0),
            ),
          );
        }
      }),
    );

    final GlobalKey firstNameKey = useMemoized(GlobalKey.new);
    final GlobalKey lastNameKey = useMemoized(GlobalKey.new);
    final FocusNode lastNameFocusNode = useFocusNode();
    final GlobalKey phoneKey = useMemoized(GlobalKey.new);
    final FocusNode phoneFocusNode = useFocusNode();
    final GlobalKey emailKey = useMemoized(GlobalKey.new);
    final FocusNode emailFocusNode = useFocusNode();

    Future<void> requestFocus(final GlobalKey key) async {
      final KeyboardVisibilityController controller =
          KeyboardVisibilityController();
      if (!controller.isVisible) {
        await for (final bool state in controller.onChange) {
          if (state) {
            break;
          }
        }
      }
      WidgetsBinding.instance.addPostFrameCallback((final _) async {
        if (key.currentContext != null) {
          await Scrollable.ensureVisible(
            key.currentContext!,
            duration: const Duration(milliseconds: 150),
            alignment: 1 / 2,
          );
        }
      });
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        /// First Name
        if (firstNameController != null) ...<Widget>[
          Flexible(
            child: Text(
              $.profile.edit.firstName,
              style: theme.textTheme.titleMedium,
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            key: firstNameKey,
            autocorrect: false,
            autofillHints: null,
            controller: firstNameController,
            textInputAction: TextInputAction.next,
            onTap: () async => requestFocus(firstNameKey),
            onEditingComplete: () async {
              lastNameFocusNode.requestFocus();
              await requestFocus(lastNameKey);
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: theme.colorScheme.surface,
              hintText: $.profile.edit.firstNameHint,
            ),
            inputFormatters: <TextInputFormatter>[
              LengthLimitingTextInputFormatter(64),
            ],
          ),
        ],

        /// Last Name
        if (lastNameController != null) ...<Widget>[
          const SizedBox(height: 24),
          Flexible(
            child: Text(
              $.profile.edit.lastName,
              style: theme.textTheme.titleMedium,
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            key: lastNameKey,
            autocorrect: false,
            autofillHints: null,
            controller: lastNameController,
            focusNode: lastNameFocusNode,
            textInputAction: TextInputAction.next,
            onTap: () async => requestFocus(lastNameKey),
            onEditingComplete: () async {
              phoneFocusNode.requestFocus();
              await requestFocus(phoneKey);
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: theme.colorScheme.surface,
              hintText: $.profile.edit.lastNameHint,
            ),
            inputFormatters: <TextInputFormatter>[
              LengthLimitingTextInputFormatter(64),
            ],
          ),
        ],

        /// Phone Number
        if (phoneController != null) ...<Widget>[
          const SizedBox(height: 24),
          Flexible(
            child: Text(
              $.profile.edit.phone,
              style: theme.textTheme.titleMedium,
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            key: phoneKey,
            autocorrect: false,
            autofillHints: null,
            controller: phoneController,
            focusNode: phoneFocusNode,
            textInputAction: TextInputAction.next,
            onTap: () async => requestFocus(phoneKey),
            onEditingComplete: () async {
              emailFocusNode.requestFocus();
              await requestFocus(emailKey);
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: theme.colorScheme.surface,
              hintText: $.profile.edit.phoneHint,
            ),
            keyboardType: TextInputType.phone,
            inputFormatters: <TextInputFormatter>[phoneFormatter],
          ),
        ],

        /// Email
        if (emailController != null) ...<Widget>[
          const SizedBox(height: 24),
          Flexible(
            child: Text(
              $.profile.edit.email,
              style: theme.textTheme.titleMedium,
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            key: emailKey,
            autocorrect: false,
            autofillHints: null,
            controller: emailController,
            focusNode: emailFocusNode,
            onTap: () async => requestFocus(emailKey),
            decoration: InputDecoration(
              filled: true,
              fillColor: theme.colorScheme.surface,
              hintText: $.profile.edit.emailHint,
            ),
            inputFormatters: <TextInputFormatter>[
              LengthLimitingTextInputFormatter(256),
            ],
          ),
        ],
      ],
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) =>
      super.debugFillProperties(
        properties
          ..add(
            DiagnosticsProperty<TextEditingController?>(
              'firstNameController',
              firstNameController,
            ),
          )
          ..add(
            DiagnosticsProperty<TextEditingController?>(
              'lastNameController',
              lastNameController,
            ),
          )
          ..add(
            DiagnosticsProperty<TextEditingController?>(
              'phoneController',
              phoneController,
            ),
          )
          ..add(
            DiagnosticsProperty<TextEditingController?>(
              'emailController',
              emailController,
            ),
          ),
      );
}

/// The screen that notifies about an error on [ProfileEditScreen].
@immutable
class ProfileEditErrorScreen extends HookConsumerWidget {
  /// The screen that notifies about an error on [ProfileEditScreen].
  const ProfileEditErrorScreen(
    this.profile,
    this.error,
    this.stackTrace, {
    super.key,
  });

  /// The profile to show this error screen for.
  final UserProfileModel profile;

  /// The error that caused this screen to appear.
  final Object error;

  /// The [StackTrace] of an [error] that caused this screen to appear.
  final StackTrace stackTrace;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final NavigatorState navigator = Navigator.of(context);
    final I18N $ = I18NLocalizations.of(context);
    final SyncCallback syncCallback = useSyncCallback();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
      ),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              child: ColoredBox(
                color: theme.colorScheme.surface,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      /// Title / Clear
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              $.alert.profileEditError.title,
                              style: theme.textTheme.displaySmall,
                              textAlign: TextAlign.start,
                            ),
                          ),
                          IconButton(
                            style: IconButton.styleFrom(
                              fixedSize: const Size.square(30),
                              foregroundColor: theme.colorScheme.outline,
                              padding: const EdgeInsets.all(6),
                              shape: const CircleBorder(),
                            ),
                            icon: Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Icon(icons.cross, size: 16),
                            ),
                            onPressed: () async =>
                                syncCallback(navigator.maybePop),
                          ),
                          const SizedBox(width: 10),
                        ],
                      ),

                      /// Body
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          $.alert.profileEditError.body,
                          style: theme.textTheme.bodyMedium,
                          maxLines: 5,
                          textAlign: TextAlign.start,
                        ),
                      ),

                      /// Approve
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: theme.colorScheme.surface,
                            minimumSize: const Size.fromHeight(0),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(8)),
                              side: BorderSide(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                            textStyle: theme.textTheme.titleSmall,
                          ),
                          onPressed: () async =>
                              syncCallback(navigator.maybePop),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Text($.alert.profileEditError.approve),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) =>
      super.debugFillProperties(
        properties
          ..add(DiagnosticsProperty<UserProfileModel>('profile', profile))
          ..add(DiagnosticsProperty<Object>('error', error))
          ..add(DiagnosticsProperty<StackTrace>('stackTrace', stackTrace)),
      );
}
