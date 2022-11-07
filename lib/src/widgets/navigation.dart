import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:isar/isar.dart';

import '../generated/i18n.g.dart';
import '../generated/icons.g.dart';
import '../generated/models.g.dart';
import '../hooks/sync_callback_hook.dart';
import '../hooks/widget_state_hook.dart';
import '../models/cart_store.dart';
import '../models/search_entry.dart';
import '../models/settings.dart';
import '../providers/api.dart';
import '../providers/misc.dart';
import '../routes.dart';
import 'misc/delivery.dart';
import 'navigation/cart.dart';
import 'navigation/home.dart';
import 'navigation/profile.dart';

/// The main screen used for navigating the app.
class NavigationScreen extends HookConsumerWidget {
  /// The main screen used for navigating the app.
  const NavigationScreen({super.key});

  /// The height of the [AppBar] on this screen.
  static const double appBarHeight = 64;

  /// The height of the [AppBar] while using search on this screen.
  static const double searchAppBarHeight = 80;

  /// The height of the [BottomNavigationBar] on this screen.
  static const double navBarHeight = 72;

  /// If the [WillPopScope] on current screen will return true.
  static final StateProvider<bool> canPopProvider =
      StateProvider<bool>((final _) => true);

  /// The completer of [WillPopScope] on this screen.
  ///
  /// Used for closing an alert dialog with system back button press.
  static final StateProvider<Completer<void>> willPopCompleterProvider =
      StateProvider<Completer<void>>((final _) => Completer<void>());

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final I18N $ = I18NLocalizations.of(context);
    final bool searchActive = ref.watch(
      SearchField.provider.select((final _) => _ != null),
    );
    final SyncCallback syncCallback = useSyncCallback();
    final PageController pageController = usePageController();
    final ValueNotifier<int> currentPage = useState(pageController.initialPage);
    useMemoized(
      () => pageController.addListener(
        () => pageController.page != null
            ? currentPage.value = pageController.page!.round()
            : null,
      ),
    );
    final int cartCount = ref.watch(
      cartProvider.select(
        (final _) =>
            _.valueOrNull?.fold<int>(
              0,
              (final _, final CartStore store) => _ + store.products.length,
            ) ??
            0,
      ),
    );
    return WillPopScope(
      onWillPop: () async {
        ref.read(willPopCompleterProvider).complete();
        ref.refresh(willPopCompleterProvider);
        return ref.read(canPopProvider);
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: theme.colorScheme.onBackground,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
        ),
        child: KeyboardDismissOnTap(
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: theme.colorScheme.onBackground,
              systemOverlayStyle: SystemUiOverlayStyle(
                statusBarColor: theme.colorScheme.onBackground,
                statusBarIconBrightness: Brightness.light,
                statusBarBrightness: Brightness.dark,
                systemNavigationBarIconBrightness: Brightness.dark,
                systemNavigationBarColor: theme.colorScheme.surface,
              ),
              toolbarHeight: searchActive ? searchAppBarHeight : appBarHeight,
              titleSpacing: 0,
              title: searchActive
                  ? const Padding(
                      padding: EdgeInsets.only(left: 24),
                      child: SizedBox(height: 40, child: SearchField()),
                    )
                  : const DeliveryPickerField(),
              actions: <Widget>[
                Align(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: !searchActive
                        ? IconButton(
                            style: IconButton.styleFrom(
                              padding: EdgeInsets.zero,
                              foregroundColor: theme.colorScheme.primary,
                            ),
                            icon: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Icon(icons.misc.search, size: 24),
                            ),
                            onPressed: () async => syncCallback(() async {
                              if ((pageController.page ?? 0) > 1 / 2) {
                                await pageController.animateToPage(
                                  0,
                                  duration: Duration(
                                    milliseconds: currentPage.value * 200,
                                  ),
                                  curve: Curves.ease,
                                );
                              }
                              ref.read(SearchField.provider.notifier).state =
                                  '';
                            }),
                          )
                        : IconButton(
                            style: IconButton.styleFrom(
                              padding: EdgeInsets.zero,
                              foregroundColor: theme.colorScheme.surface,
                            ),
                            icon: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Icon(icons.cancel, size: 16),
                            ),
                            onPressed: () => ref
                              ..refresh(SearchField.suggestions)
                              ..refresh(SearchField.provider.notifier),
                          ),
                  ),
                ),
              ],
            ),
            body: PageView(
              controller: pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: const <Widget>[
                HomeScreen(key: PageStorageKey<String>('HomeScreen')),
                CartScreen(key: PageStorageKey<String>('CartScreen')),
                Placeholder(key: PageStorageKey<String>('OrdersScreen')),
                ProfileScreen(key: PageStorageKey<String>('ProfileScreen')),
              ],
            ),
            bottomNavigationBar: Padding(
              padding: EdgeInsets.only(bottom: mediaQuery.padding.bottom),
              child: MediaQuery(
                data: mediaQuery.removePadding(removeBottom: true),
                child: SizedBox(
                  height: navBarHeight,
                  child: BottomNavigationBar(
                    showSelectedLabels: true,
                    showUnselectedLabels: true,
                    selectedFontSize: theme.bottomNavigationBarTheme
                            .selectedLabelStyle?.fontSize ??
                        14,
                    unselectedFontSize: theme.bottomNavigationBarTheme
                            .unselectedLabelStyle?.fontSize ??
                        12,
                    type: BottomNavigationBarType.fixed,
                    currentIndex: currentPage.value,
                    onTap: (final int index) async =>
                        pageController.animateToPage(
                      index,
                      duration: Duration(
                        milliseconds: (currentPage.value - index).abs() * 233,
                      ),
                      curve: Curves.ease,
                    ),
                    items: <BottomNavigationBarItem>[
                      BottomNavigationBarItem(
                        icon: Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Icon(icons.menu.home),
                        ),
                        label: $.home.menu.home,
                        tooltip: '',
                      ),
                      BottomNavigationBarItem(
                        icon: Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Icon(icons.menu.cart, size: 24),
                        ),
                        label: $.home.menu.cart(cartCount),
                        tooltip: cartCount > 0
                            ? $.home.menu.cartTooltip(cartCount)
                            : '',
                      ),
                      BottomNavigationBarItem(
                        icon: Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Icon(icons.menu.orders, size: 24),
                        ),
                        label: $.home.menu.orders,
                        tooltip: '',
                      ),
                      BottomNavigationBarItem(
                        icon: Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Icon(icons.menu.profile, size: 24),
                        ),
                        label: $.home.menu.profile,
                        tooltip: '',
                      ),
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
}

/// The widget used to navigate to [DeliveryScreen].
class DeliveryPickerField extends HookConsumerWidget {
  /// The widget used to navigate to [DeliveryScreen].
  const DeliveryPickerField({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final NavigatorState rootNavigator =
        Navigator.of(context, rootNavigator: true);
    final I18N $ = I18NLocalizations.of(context);

    final AsyncValue<DeliveryType> deliveryType =
        ref.watch(deliveryTypeProvider);
    final AsyncValue<UserAddressesModel?> activeAddress =
        ref.watch(activeAddressProvider);
    final UserAddressesModel? prevActiveAddress =
        usePrevious<UserAddressesModel?>(activeAddress.valueOrNull);
    final UserAddressesModel? address =
        activeAddress.valueOrNull ?? prevActiveAddress;

    final StoreModel? store = ref.watch(
      cartProvider.select(
        (final _) =>
            _.whenOrNull<StoreModel?>(data: (final _) => _.firstOrNull?.store),
      ),
    );

    String? eta;
    if (address == null) {
      eta = $.home.addressHint;
    } else if (store?.id == null) {
      eta = $.home.storeHint;
    }
    final String? prevEta = usePrevious<String?>(eta);

    if (deliveryType is! AsyncData || deliveryType.valueOrNull == null) {
      eta ??= prevEta;
    } else if (address != null && store?.id != null) {
      switch (deliveryType.value!) {
        case DeliveryType.delivery:
          eta = ref.watch(
            storeEtaDeliveryProvider(store!.id!).select(
              (final _) =>
                  _.whenOrNull<String?>(
                    data: (final _) => _?.min != null && _?.max != null
                        ? $.delivery.deliveryToTime(
                            _!.min!,
                            _.max!,
                            address.displayLong!,
                          )
                        : null,
                  ) ??
                  $.home.storeHint,
            ),
          );
          break;

        case DeliveryType.pickup:
          eta = ref.watch(
            storeEtaPickupProvider(store!.id!).select(
              (final _) =>
                  _.whenOrNull<String?>(
                    data: (final _) => _?.min != null && _?.max != null
                        ? $.delivery.pickupFromTime(
                            _!.min!,
                            _.max!,
                            address.displayLong!,
                          )
                        : null,
                  ) ??
                  $.home.storeHint,
            ),
          );
      }
    }

    final SyncCallback syncCallback = useSyncCallback();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: theme.colorScheme.surface,
          textStyle: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        onPressed: () async => syncCallback(
          () async => rootNavigator.pushNamed(
            Routes.delivery.name,
            arguments: DeliveryScreen(
              deliveryType: await ref.read(deliveryTypeProvider.future),
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Icon(icons.delivery, size: 16),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  eta ?? $.home.addressHint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 11),
              Icon(icons.misc.arrowDown, size: 10),
            ],
          ),
        ),
      ),
    );
  }
}

/// The field used for searching on [NavigationScreen].
class SearchField extends HookConsumerWidget {
  /// The field used for searching on [NavigationScreen].
  const SearchField({super.key});

  /// The provider of the current search value.
  static final StateProvider<String?> provider =
      StateProvider<String?>((final _) => null);

  /// The provider of the current search value.
  static final AutoDisposeStateProvider<Set<String>> suggestions =
      StateProvider.autoDispose<Set<String>>((final _) => const <String>{});

  /// The provider that specifies if [suggestions] should be shown.
  static final AutoDisposeStateProvider<bool> showSuggestions =
      StateProvider.autoDispose<bool>((final _) => true);

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final I18N $ = I18NLocalizations.of(context);

    final IsMounted isMounted = useIsMounted();
    final SyncCallback syncCallback = useSyncCallback();
    final ObjectRef<bool> pickedSuggestion = useRef(false);
    final GlobalKey searchKey = useMemoized(GlobalKey.new);
    final FocusNode focusNode = useFocusNode();
    useMemoized(
      () => focusNode.addListener(
        () => isMounted()
            ? ref.read(showSuggestions.notifier).state = focusNode.hasFocus
            : null,
      ),
    );
    unawaited(
      useMemoized(
        () => Future<void>.delayed(const Duration(milliseconds: 200))
            .then((final _) => isMounted() ? focusNode.requestFocus() : null),
      ),
    );

    final TextEditingController controller = useTextEditingController();
    final LayerLink layerLink = useMemoized(LayerLink.new);
    final ObjectRef<OverlayEntry?> entry = useRef(null);
    useWidgetState(dispose: () => entry.value?.remove());
    useMemoized(
      () => WidgetsBinding.instance.addPostFrameCallback((final _) {
        if (!isMounted()) {
          return;
        }
        final RenderBox? textFieldRenderBox =
            searchKey.currentContext?.findRenderObject() as RenderBox?;
        final OverlayState? overlay = Overlay.of(context);
        if (overlay == null || textFieldRenderBox == null) {
          return;
        }
        overlay.insert(
          entry.value = OverlayEntry(
            builder: (final _) => Positioned(
              left: textFieldRenderBox.localToGlobal(Offset.zero).dx,
              width: textFieldRenderBox.size.width,
              child: CompositedTransformFollower(
                link: layerLink,
                offset: Offset(0, textFieldRenderBox.size.height),
                child: SearchFieldSuggestions(
                  onTap: (final String suggestion) async =>
                      syncCallback(() async {
                    ref.refresh(suggestions);
                    focusNode.unfocus();
                    final String inputText = controller.text.trim();
                    controller
                      ..text = suggestion
                      ..selection = TextSelection.fromPosition(
                        TextPosition(offset: suggestion.length),
                      );
                    ref.read(suggestions.notifier).state = <String>{
                      'diki',
                      'flex'
                    };
                    if (inputText.isNotEmpty) {
                      final Isar isar = await ref.read(isarProvider.future);
                      await isar.writeTxn(
                        () => isar.searchEntrys.put(
                          SearchEntry()
                            ..value = inputText
                            ..timestamp = ref.read(serverTimeProvider),
                        ),
                      );
                    }
                  }),
                ),
              ),
            ),
          ),
        );
      }),
    );

    useMemoized(
      () => WidgetsBinding.instance.addPostFrameCallback(
        (final _) async => syncCallback(() async {
          final Iterable<String> isarSuggestions =
              await ref.read(recentSearchEntriesProvider.future);
          if (isMounted()) {
            ref.read(suggestions.notifier).state = isarSuggestions.toSet();
          }
        }),
      ),
    );

    final BorderRadius borderRadius = ref.watch(showSuggestions) &&
            ref.watch(suggestions.select((final _) => _.isNotEmpty))
        ? const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          )
        : const BorderRadius.all(Radius.circular(8));
    return CompositedTransformTarget(
      link: layerLink,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: TextField(
            key: searchKey,
            controller: controller,
            focusNode: focusNode,
            style: theme.textTheme.bodyMedium,
            decoration: InputDecoration(
              filled: true,
              fillColor: theme.colorScheme.surface,
              prefixIcon: Icon(
                icons.misc.search,
                size: 16,
                color: theme.colorScheme.onBackground,
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 36, maxWidth: 36),
              hintText: $.home.searchHint,
              hintStyle: theme.textTheme.bodyMedium,
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide.none,
              ),
              enabledBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide.none,
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (final String value) async => syncCallback(() async {
              final StateController<String?> notifier =
                  ref.read(provider.notifier);
              if (notifier.state != value) {
                notifier.state = value;
                ref.read(suggestions.select((final _) => _.isEmpty))
                    ? WidgetsBinding.instance.addPostFrameCallback(
                        (final _) =>
                            isMounted() ? pickedSuggestion.value = false : null,
                      )
                    : pickedSuggestion.value = false;
              }
              if (value.isEmpty) {
                final Iterable<String> isarSuggestions =
                    await ref.read(recentSearchEntriesProvider.future);
                ref.read(suggestions.notifier).state = isarSuggestions.toSet();
              } else {
                ref.read(suggestions.notifier).state =
                    (await ref.read(filteredStoresProvider.future))
                        .map((final StoreModel store) => store.name!)
                        .toSet();
              }
            }),
          ),
        ),
      ),
    );
  }
}

/// The widget used to display [SearchField.suggestions].
class SearchFieldSuggestions extends HookConsumerWidget {
  /// The widget used to display [SearchField.suggestions].
  const SearchFieldSuggestions({this.onTap, super.key});

  /// The callback on suggestion tap.
  final void Function(String suggestion)? onTap;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final Iterable<String> suggestions = ref.watch(SearchField.showSuggestions)
        ? ref.watch(SearchField.suggestions.select((final _) => _))
        : const Iterable<String>.empty();
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(8),
        bottomRight: Radius.circular(8),
      ),
      child: Material(
        color: suggestions.isNotEmpty
            ? theme.colorScheme.outline
            : Colors.transparent,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
        child: Padding(
          padding:
              const EdgeInsetsDirectional.only(start: 1, end: 1, bottom: 1),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(7),
                bottomRight: Radius.circular(7),
              ),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              physics: suggestions.length <= 1
                  ? const NeverScrollableScrollPhysics()
                  : null,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  for (final String suggestion in suggestions)
                    SizedBox(
                      height: 40,
                      child: DecoratedBox(
                        decoration: suggestion != suggestions.last
                            ? BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                              )
                            : const BoxDecoration(),
                        child: TextButton(
                          style: TextButton.styleFrom(
                            shape: const RoundedRectangleBorder(),
                            minimumSize: const Size.fromHeight(0),
                            alignment: Alignment.centerLeft,
                          ),
                          onPressed: () => onTap?.call(suggestion),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: <Widget>[
                                Icon(
                                  ref.watch(
                                    SearchField.provider.select(
                                      (final _) => _?.isEmpty ?? true,
                                    ),
                                  )
                                      ? icons.misc.searchHistory
                                      : icons.misc.search,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Flexible(child: Text(suggestion)),
                              ],
                            ),
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
          ..add(
            ObjectFlagProperty<void Function(String suggestion)?>.has(
              'onTap',
              onTap,
            ),
          ),
      );
}
