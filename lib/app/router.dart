import 'package:go_router/go_router.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/product/screens/product_list_screen.dart';
import '../features/product/screens/add_edit_product_screen.dart';
import '../features/product/screens/low_stock_screen.dart';
import '../features/transaction/screens/add_sale_screen.dart';
import '../features/transaction/screens/add_expense_screen.dart';
import '../features/transaction/screens/transaction_history_screen.dart';
import '../features/report/screens/report_screen.dart';
import '../features/report/screens/report_detail_screen.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/products',
      name: 'products',
      builder: (context, state) => const ProductListScreen(),
    ),
    GoRoute(
      path: '/products/new',
      name: 'product-new',
      builder: (context, state) => const AddEditProductScreen(),
    ),
    GoRoute(
      path: '/products/:id/edit',
      name: 'product-edit',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return AddEditProductScreen(productId: id);
      },
    ),
    GoRoute(
      path: '/low-stock',
      name: 'low-stock',
      builder: (context, state) => const LowStockScreen(),
    ),
    GoRoute(
      path: '/sale/new',
      name: 'sale-new',
      builder: (context, state) => const AddSaleScreen(),
    ),
    GoRoute(
      path: '/expense/new',
      name: 'expense-new',
      builder: (context, state) => const AddExpenseScreen(),
    ),
    GoRoute(
      path: '/transactions',
      name: 'transactions',
      builder: (context, state) => const TransactionHistoryScreen(),
    ),
    GoRoute(
      path: '/reports',
      name: 'reports',
      builder: (context, state) => const ReportScreen(),
    ),
    GoRoute(
      path: '/reports/detail',
      name: 'report-detail',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return ReportDetailScreen(
          period: extra['period'] as String? ?? 'harian',
          date: extra['date'] as String? ?? '',
          label: extra['label'] as String?,
        );
      },
    ),
  ],
);
