import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/app_data_provider.dart';
import '../../models/barbershop_model.dart';
import '../../models/cart_provider.dart';
import '../../models/review_model.dart';
import '../../models/service_model.dart';
import '../../core/routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import 'package:barber_hub/features/membership/domain/entities/membership_plan_entity.dart';
import 'package:barber_hub/features/membership/presentation/providers/membership_providers.dart';
import 'package:barber_hub/features/membership/presentation/models/membership_plans_args.dart';

class BarbershopDetailScreen extends ConsumerStatefulWidget {
  const BarbershopDetailScreen({super.key});

  @override
  ConsumerState<BarbershopDetailScreen> createState() =>
      _BarbershopDetailScreenState();
}

class _BarbershopDetailScreenState extends ConsumerState<BarbershopDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  bool _didRequestCatalogRefresh = false;
  bool _didRequestPlans = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final routeShop =
        ModalRoute.of(context)!.settings.arguments as BarbershopModel;
    final data = context.watch<AppDataProvider>();
    final shop = data.shopFor(routeShop);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AppDataProvider>();
      provider.selectBarbershop(shop);
      if (!_didRequestCatalogRefresh) {
        _didRequestCatalogRefresh = true;
        provider.refreshCatalog();
      }
      if (!_didRequestPlans) {
        _didRequestPlans = true;
        ref.read(clientMembershipProvider.notifier).loadPlansForShop(shop.id);
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // â”€â”€ Top bar (fixo, nÃ£o rola com o conteÃºdo) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 18, color: AppTheme.textSecondary),
                    onPressed: () {
                      context.read<AppDataProvider>().clearSelectedBarbershop();
                      Navigator.pop(context);
                    },
                  ),
                  const Spacer(),
                  Text(
                    'BARBEARIA',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppTheme.textHint,
                          fontSize: 11,
                          letterSpacing: 3,
                        ),
                  ),
                  const SizedBox(width: 12),
                  _CartBadgeButton(),
                ],
              ),
            ),
            Expanded(
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  // â”€â”€ Cover â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                      child: _CoverCard(shop: shop),
                    ),
                  ),

                  // â”€â”€ Info â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                      child: _ShopInfo(shop: shop),
                    ),
                  ),

                  // â”€â”€ Stats â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                      child: _StatsRow(shop: shop),
                    ),
                  ),

                  // â”€â”€ Equipe â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(24, 24, 24, 0),
                      child: SectionHeader(title: 'Equipe'),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: SizedBox(
                        height: 100,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          scrollDirection: Axis.horizontal,
                          itemCount: shop.barbers.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (_, i) =>
                              _BarberChip(barber: shop.barbers[i]),
                        ),
                      ),
                    ),
                  ),

                  // â”€â”€ Tab bar Serviços / Produtos â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                      child:
                          _ServicesProductsTabBar(controller: _tab, shop: shop),
                    ),
                  ),
                ],

                // â”€â”€ Tab body â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                body: TabBarView(
                  controller: _tab,
                  children: [
                    _ServicesTab(shop: shop),
                    _ProductsTab(shop: shop),
                    _ReviewsTab(shop: shop),
                    _PlansTab(shop: shop),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€ Tab bar toggle â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _ServicesProductsTabBar extends StatelessWidget {
  final TabController controller;
  final BarbershopModel shop;
  const _ServicesProductsTabBar({required this.controller, required this.shop});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();
    final productCount = shop.availableProducts.length;
    final serviceCount = shop.services.where((s) => s.isActive).length;
    final reviewCount = data.reviewsForShop(shop.id).length;

    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.inputBorder),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: AppTheme.gold,
          borderRadius: BorderRadius.circular(7),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: AppTheme.background,
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle: GoogleFonts.jost(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            GoogleFonts.jost(fontSize: 11, fontWeight: FontWeight.w400),
        tabs: [
          Tab(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.content_cut_rounded, size: 13),
                const SizedBox(width: 5),
                const Text('Serviços'),
                const SizedBox(width: 4),
                _TabCount(count: serviceCount, active: controller.index == 0),
              ]),
            ),
          ),
          Tab(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.shopping_bag_outlined, size: 13),
                const SizedBox(width: 5),
                const Text('Produtos'),
                if (productCount > 0) ...[
                  const SizedBox(width: 4),
                  _TabCount(count: productCount, active: controller.index == 1),
                ],
              ]),
            ),
          ),
          Tab(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.star_outline_rounded, size: 13),
                const SizedBox(width: 5),
                const Text('Reviews'),
                if (reviewCount > 0) ...[
                  const SizedBox(width: 4),
                  _TabCount(count: reviewCount, active: controller.index == 2),
                ],
              ]),
            ),
          ),
          Tab(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(mainAxisSize: MainAxisSize.min, children: const [
                Icon(Icons.workspace_premium_outlined, size: 13),
                SizedBox(width: 5),
                Text('Planos'),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabCount extends StatelessWidget {
  final int count;
  final bool active;
  const _TabCount({required this.count, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: active
            ? AppTheme.background.withValues(alpha: 0.25)
            : AppTheme.textHint.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: GoogleFonts.jost(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: active ? AppTheme.background : AppTheme.textHint,
        ),
      ),
    );
  }
}

// â”€â”€ Tab 0: Serviços â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _ServicesTab extends StatelessWidget {
  final BarbershopModel shop;
  const _ServicesTab({required this.shop});

  @override
  Widget build(BuildContext context) {
    final active = shop.services.where((s) => s.isActive).toList();

    if (active.isEmpty) {
      return const EmptyState(
        icon: Icons.content_cut_outlined,
        title: 'Sem serviços',
        subtitle: 'Esta barbearia ainda não tem serviços cadastrados.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      itemCount: active.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, i) => _ServiceBookingCard(
        service: active[i],
        shop: shop,
      ),
    );
  }
}

// â”€â”€ Tab 1: Produtos â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _ProductsTab extends StatefulWidget {
  final BarbershopModel shop;
  const _ProductsTab({required this.shop});

  @override
  State<_ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<_ProductsTab> {
  ProductCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();
    final allProducts = data.productsFor(widget.shop);
    final categories = data.availableCategoriesFor(widget.shop);
    final featured = data.featuredProductsFor(widget.shop);

    final filtered = _selectedCategory == null
        ? allProducts
        : data.productsByCategory(widget.shop, _selectedCategory!);

    if (allProducts.isEmpty) {
      return const EmptyState(
        icon: Icons.shopping_bag_outlined,
        title: 'Sem produtos',
        subtitle: 'Esta barbearia ainda não tem produtos cadastrados.',
      );
    }

    return CustomScrollView(
      slivers: [
        // â”€â”€ Destaques â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        if (featured.isNotEmpty && _selectedCategory == null) ...[
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: SectionHeader(title: 'Destaques'),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 190,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                scrollDirection: Axis.horizontal,
                itemCount: featured.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (_, i) => _FeaturedProductCard(
                  product: featured[i],
                  shop: widget.shop,
                ),
              ),
            ),
          ),
        ],

        // â”€â”€ Filtro de categorias â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 0, 0),
            child: _CategoryFilter(
              categories: categories,
              selected: _selectedCategory,
              onSelect: (c) => setState(() => _selectedCategory = c),
            ),
          ),
        ),

        // â”€â”€ Lista de produtos â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: SectionHeader(
              title: _selectedCategory == null
                  ? 'Todos os produtos'
                  : _selectedCategory!.label,
            ),
          ),
        ),

        if (filtered.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Text(
                  'Nenhum produto nesta categoria.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppTheme.textHint),
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 40),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _ProductCard(
                    product: filtered[i],
                    shop: widget.shop,
                  ),
                ),
                childCount: filtered.length,
              ),
            ),
          ),
      ],
    );
  }
}

// â”€â”€ Category filter â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _CategoryFilter extends StatelessWidget {
  final List<ProductCategory> categories;
  final ProductCategory? selected;
  final ValueChanged<ProductCategory?> onSelect;

  const _CategoryFilter({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(right: 24),
      child: Row(
        children: [
          // Chip "Todos"
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _FilterChip(
              label: 'Todos',
              iconData: Icons.shopping_bag_outlined,
              selected: selected == null,
              onTap: () => onSelect(null),
            ),
          ),
          ...categories.map((cat) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _FilterChip(
                  label: cat.label,
                  iconData: cat.iconData,
                  selected: selected == cat,
                  onTap: () => onSelect(selected == cat ? null : cat),
                ),
              )),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData iconData;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.iconData,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.gold.withValues(alpha: 0.15)
              : AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.gold : AppTheme.inputBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(iconData, size: 14, color: AppTheme.textSecondary),
            const SizedBox(width: 5),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    color: selected ? AppTheme.gold : AppTheme.textSecondary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€ Featured product card (horizontal scroll) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _FeaturedProductCard extends StatelessWidget {
  final ProductModel product;
  final BarbershopModel shop;

  const _FeaturedProductCard({required this.product, required this.shop});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.productDetail,
        arguments: {'product': product, 'barbershop': shop},
      ),
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.gold.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.gold.withValues(alpha: 0.07),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(product.imageEmoji,
                        style: const TextStyle(fontSize: 44)),
                  ),
                  if (product.hasDiscount)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.error,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '-${product.discountPercent}%',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    product.formattedPrice,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.gold,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€ Product card (list) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final BarbershopModel shop;

  const _ProductCard({required this.product, required this.shop});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.inputBorder),
      ),
      child: Column(
        children: [
          // â”€â”€ Conteúdo â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Emoji / imagem
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppTheme.gold.withValues(alpha: 0.15)),
                  ),
                  child: Center(
                    child: Text(product.imageEmoji,
                        style: const TextStyle(fontSize: 30)),
                  ),
                ),
                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nome + destaque
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontSize: 14),
                            ),
                          ),
                          if (product.isFeatured)
                            const Icon(Icons.star_rounded,
                                size: 14, color: AppTheme.gold),
                        ],
                      ),
                      const SizedBox(height: 3),

                      // Marca + categoria
                      Text(
                        '${product.brand} Â· ${product.category.label}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 11,
                              color: AppTheme.textHint,
                            ),
                      ),
                      const SizedBox(height: 6),

                      // Descrição curta
                      Text(
                        product.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              height: 1.4,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Preço
                      Row(
                        children: [
                          Text(
                            product.formattedPrice,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: AppTheme.gold,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          if (product.hasDiscount) ...[
                            const SizedBox(width: 8),
                            Text(
                              product.formattedOriginalPrice!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontSize: 12,
                                    color: AppTheme.textHint,
                                    decoration: TextDecoration.lineThrough,
                                    decorationColor: AppTheme.textHint,
                                  ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.error.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '-${product.discountPercent}%',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: AppTheme.error,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // â”€â”€ CTA (dois botões lado a lado) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Container(height: 1, color: AppTheme.divider),
          _ProductCardActions(product: product, shop: shop),
        ],
      ),
    );
  }
}

// â”€â”€ Tab 2: Reviews â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _ReviewsTab extends StatelessWidget {
  final BarbershopModel shop;
  const _ReviewsTab({required this.shop});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();
    final reviews = data.reviewsForShop(shop.id);
    final rating = data.ratingForShop(shop.id);
    final dist = data.ratingDistributionForShop(shop.id);

    if (reviews.isEmpty) {
      return const EmptyState(
        icon: Icons.star_outline_rounded,
        title: 'Sem avaliações',
        subtitle:
            'Seja o primeiro a avaliar esta barbearia\napós seu atendimento.',
      );
    }

    return CustomScrollView(
      slivers: [
        // â”€â”€ Rating summary â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: _RatingSummary(
              rating: rating,
              count: reviews.length,
              distribution: dist,
            ),
          ),
        ),

        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 14),
            child: SectionHeader(title: 'Avaliações'),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ReviewCard(review: reviews[i]),
              ),
              childCount: reviews.length,
            ),
          ),
        ),
      ],
    );
  }
}

// â”€â”€ Rating summary widget â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _RatingSummary extends StatelessWidget {
  final double rating;
  final int count;
  final Map<int, int> distribution;

  const _RatingSummary({
    required this.rating,
    required this.count,
    required this.distribution,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.inputBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Nota grande
          Column(
            children: [
              Text(
                rating.toStringAsFixed(1),
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: AppTheme.gold,
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < rating.round()
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 14,
                    color: AppTheme.gold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$count avaliações',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 11,
                      color: AppTheme.textHint,
                    ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Container(width: 1, height: 80, color: AppTheme.divider),
          const SizedBox(width: 20),
          // Barras de distribuição
          Expanded(
            child: Column(
              children: List.generate(5, (i) {
                final star = 5 - i;
                final qty = distribution[star] ?? 0;
                final pct = count > 0 ? qty / count : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    children: [
                      Text(
                        '$star',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 11,
                              color: AppTheme.textHint,
                            ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.star_rounded,
                          size: 10, color: AppTheme.gold),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 6,
                            backgroundColor: AppTheme.inputBorder,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.gold.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 16,
                        child: Text(
                          '$qty',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontSize: 11,
                                    color: AppTheme.textHint,
                                  ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Review card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final r = review;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: nome + estrelas + data
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.gold.withValues(alpha: 0.12),
                  border:
                      Border.all(color: AppTheme.gold.withValues(alpha: 0.25)),
                ),
                child: Center(
                  child: Text(
                    r.clientName.isNotEmpty
                        ? r.clientName[0].toUpperCase()
                        : '?',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: AppTheme.gold, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.clientName,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontSize: 13)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(r.barberName,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 11, color: AppTheme.textHint)),
                        const SizedBox(width: 6),
                        Icon(Icons.star_rounded,
                            size: 11, color: AppTheme.gold.withValues(alpha: 0.7)),
                        const SizedBox(width: 2),
                        Text('${r.barberRating}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 11, color: AppTheme.textHint)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < r.barbershopRating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 13,
                        color: AppTheme.gold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(r.formattedDate,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontSize: 10, color: AppTheme.textHint)),
                ],
              ),
            ],
          ),

          // Serviço
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppTheme.inputBorder),
            ),
            child: Text(
              r.serviceName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
            ),
          ),

          // Comentário
          if (r.comment != null && r.comment!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              r.comment!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

// -- Tab 3: Planos de assinatura ---------------------------------------------
class _PlansTab extends ConsumerWidget {
  final BarbershopModel shop;
  const _PlansTab({required this.shop});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membershipState = ref.watch(clientMembershipProvider);
    final plans =
        membershipState.availablePlans.where((p) => p.isActive).toList();

    if (membershipState.isLoading && plans.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.gold));
    }

    if (plans.isEmpty) {
      return const EmptyState(
        icon: Icons.workspace_premium_outlined,
        title: 'Sem planos disponíveis',
        subtitle: 'Esta barbearia ainda não oferece planos de assinatura.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
      children: [
        ...plans.map((plan) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child:
                  _PlanPreviewCard(plan: plan, onTap: () => _openPlans(context)),
            )),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => _openPlans(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.gold,
              foregroundColor: AppTheme.background,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(4))),
            ),
            child: const Text('VER PLANOS E ASSINAR'),
          ),
        ),
      ],
    );
  }

  void _openPlans(BuildContext context) {
    Navigator.pushNamed(
      context,
      AppRoutes.membershipPlans,
      arguments: MembershipPlansArgs(shopId: shop.id, shopName: shop.name),
    );
  }
}

class _PlanPreviewCard extends StatelessWidget {
  final MembershipPlanEntity plan;
  final VoidCallback onTap;
  const _PlanPreviewCard({required this.plan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: plan.tier.accentColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(plan.tier.icon, color: plan.tier.accentColor, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plan.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontSize: 15)),
                  const SizedBox(height: 3),
                  Text('${plan.formattedPrice}/mês · ${plan.cutsLabel}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}

// -- Shared sub-widgets (cover, info, stats, barber chip, service card) -------

class _CoverCard extends StatelessWidget {
  final BarbershopModel shop;
  const _CoverCard({required this.shop});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.gold.withValues(alpha: 0.20),
            AppTheme.gold.withValues(alpha: 0.04),
          ],
        ),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.22)),
      ),
      child: Stack(
        children: [
          Center(
              child: Icon(shop.coverIconData, size: 64, color: AppTheme.gold)),
          Positioned(
            top: 12,
            right: 12,
            child: _OpenBadge(isOpen: shop.isOpen),
          ),
        ],
      ),
    );
  }
}

class _OpenBadge extends StatelessWidget {
  final bool isOpen;
  const _OpenBadge({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    final color = isOpen ? const Color(0xFF2ECC71) : AppTheme.error;
    final bg = isOpen ? const Color(0xFF1A3A1A) : const Color(0xFF3A1A1A);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 5),
        Text(isOpen ? 'Aberto' : 'Fechado',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _ShopInfo extends StatelessWidget {
  final BarbershopModel shop;
  const _ShopInfo({required this.shop});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(shop.name,
                  style: Theme.of(context)
                      .textTheme
                      .displayMedium
                      ?.copyWith(fontSize: 28, height: 1.1)),
            ),
            const SizedBox(width: 12),
            _RatingPill(rating: shop.rating, count: shop.reviewCount),
          ],
        ),
        const SizedBox(height: 10),
        _IconRow(icon: Icons.location_on_outlined, text: shop.address),
        if (shop.phone != null) ...[
          const SizedBox(height: 6),
          _IconRow(icon: Icons.phone_outlined, text: shop.phone!),
        ],
        if (shop.description != null) ...[
          const SizedBox(height: 14),
          const GoldAccent(),
          const SizedBox(height: 12),
          Text(shop.description!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary, fontSize: 13, height: 1.6)),
        ],
      ],
    );
  }
}

class _IconRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _IconRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppTheme.textHint),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppTheme.textSecondary, fontSize: 13)),
          ),
        ],
      );
}

class _RatingPill extends StatelessWidget {
  final double rating;
  final int count;
  const _RatingPill({required this.rating, required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.gold.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.gold.withValues(alpha: 0.28)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.star_rounded, size: 14, color: AppTheme.gold),
            const SizedBox(width: 4),
            Text(rating.toStringAsFixed(1),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.gold,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
          ]),
        ),
        const SizedBox(height: 4),
        Text('$count avaliações',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontSize: 11, color: AppTheme.textHint)),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final BarbershopModel shop;
  const _StatsRow({required this.shop});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatTile(
            icon: Icons.content_cut_rounded,
            value: '${shop.services.where((s) => s.isActive).length}',
            label: 'serviços'),
        const SizedBox(width: 10),
        _StatTile(
            icon: Icons.people_outline_rounded,
            value: '${shop.barbers.where((b) => b.isActive).length}',
            label: 'barbeiros'),
        const SizedBox(width: 10),
        _StatTile(
            icon: Icons.shopping_bag_outlined,
            value: '${shop.availableProducts.length}',
            label: 'produtos'),
        const SizedBox(width: 10),
        _StatTile(
            icon: Icons.star_outline_rounded,
            value: shop.formattedRating,
            label: 'avaliação'),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatTile(
      {required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.inputBorder),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: AppTheme.gold),
            const SizedBox(height: 5),
            Text(value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 2),
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontSize: 9, color: AppTheme.textHint)),
          ],
        ),
      ),
    );
  }
}

class _BarberChip extends StatelessWidget {
  final dynamic barber;
  const _BarberChip({required this.barber});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.inputBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.gold.withValues(alpha: 0.12),
              border: Border.all(
                  color: AppTheme.gold.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Center(
              child: Text(barber.avatarInitials,
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: AppTheme.gold, fontSize: 12)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(barber.name.split(' ').first,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontSize: 13),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(barber.specialty,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontSize: 10, color: AppTheme.textHint),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.star_rounded,
                      size: 11, color: AppTheme.gold),
                  const SizedBox(width: 3),
                  Text((barber.rating as double).toStringAsFixed(1),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 11, color: AppTheme.textSecondary)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Service booking card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _ServiceBookingCard extends StatelessWidget {
  final ServiceModel service;
  final BarbershopModel shop;

  const _ServiceBookingCard({required this.service, required this.shop});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: AppTheme.gold.withValues(alpha: 0.2)),
                  ),
                  child: Icon(ServiceCard.iconFor(service.iconName),
                      color: AppTheme.gold, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(service.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontSize: 15)),
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.schedule_outlined,
                            size: 12, color: AppTheme.textHint),
                        const SizedBox(width: 4),
                        Text(service.formattedDuration,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontSize: 12)),
                      ]),
                      const SizedBox(height: 4),
                      Text(service.description,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontSize: 11,
                                    color: AppTheme.textHint,
                                    height: 1.4,
                                  ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(service.formattedPrice,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.gold,
                        fontSize: 17,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Container(height: 1, color: AppTheme.divider),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.booking,
                arguments: {'service': service, 'barbershop': shop},
              ),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(10)),
              splashColor: AppTheme.gold.withValues(alpha: 0.08),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_month_outlined,
                        size: 14, color: AppTheme.gold),
                    const SizedBox(width: 7),
                    Text('Agendar este serviço',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: AppTheme.gold,
                              fontSize: 12,
                              letterSpacing: 0.4,
                            )),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Product card actions (Ver detalhes + Adicionar ao carrinho) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _ProductCardActions extends StatelessWidget {
  final ProductModel product;
  final BarbershopModel shop;
  const _ProductCardActions({required this.product, required this.shop});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final inCart = cart.contains(product.id);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
      child: Row(
        children: [
          // Botão "Ver detalhes"
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.productDetail,
                  arguments: {'product': product, 'barbershop': shop},
                ),
                splashColor: AppTheme.gold.withValues(alpha: 0.06),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        'Detalhes',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Container(width: 1, height: 36, color: AppTheme.divider),

          // Botão "Adicionar" / "No carrinho"
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: product.inStock
                    ? () {
                        final added = cart.addItem(product, shop);
                        if (!added && cart.pendingConflict != null) {
                          _showConflictDialog(context, cart);
                          return;
                        }
                        if (inCart) {
                          Navigator.pushNamed(context, AppRoutes.cart);
                        } else {
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              duration: const Duration(seconds: 2),
                              content: Text(
                                '${product.name} adicionado!',
                                overflow: TextOverflow.ellipsis,
                              ),
                              action: SnackBarAction(
                                label: 'Ver',
                                textColor: AppTheme.gold,
                                onPressed: () => Navigator.pushNamed(
                                    context, AppRoutes.cart),
                              ),
                            ),
                          );
                        }
                      }
                    : null,
                splashColor: AppTheme.gold.withValues(alpha: 0.08),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        inCart
                            ? Icons.shopping_bag_rounded
                            : Icons.add_shopping_cart_rounded,
                        size: 14,
                        color: !product.inStock
                            ? AppTheme.textHint
                            : AppTheme.gold,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        !product.inStock
                            ? 'Indisponível'
                            : inCart
                                ? 'No carrinho'
                                : 'Adicionar',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: !product.inStock
                                  ? AppTheme.textHint
                                  : AppTheme.gold,
                              fontSize: 12,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showConflictDialog(BuildContext context, CartProvider cart) {
    final conflict = cart.pendingConflict!;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Carrinho de outra barbearia',
            style: Theme.of(context).textTheme.titleLarge),
        content: Text(
          'Você tem itens de "${cart.barbershop?.name}" no carrinho.\n\nDeseja descartá-los e começar com "${conflict.shop.name}"?',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              cart.cancelConflict();
              Navigator.pop(context);
            },
            child: const Text('Manter atual'),
          ),
          TextButton(
            onPressed: () {
              cart.confirmConflictSwitch();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Descartar e trocar'),
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Cart badge button (usado no top bar do detalhe) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _CartBadgeButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.cart),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.inputBorder),
            ),
            child: Icon(
              cart.isNotEmpty
                  ? Icons.shopping_bag_rounded
                  : Icons.shopping_bag_outlined,
              color: cart.isNotEmpty ? AppTheme.gold : AppTheme.textSecondary,
              size: 18,
            ),
          ),
          if (cart.itemCount > 0)
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                width: 17,
                height: 17,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.gold,
                ),
                child: Center(
                  child: Text(
                    cart.itemCount > 9 ? '9+' : '${cart.itemCount}',
                    style: const TextStyle(
                      color: AppTheme.background,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
