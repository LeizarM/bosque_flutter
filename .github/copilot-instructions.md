# Bosque Flutter - AI Agent Instructions

## Project Overview
Enterprise Flutter application ("Bosque") for logistics, HR, fuel control, and financial management for "ESPPAPEL" company. Multi-platform (Android, iOS, Web) with responsive design optimized for mobile, tablet, and desktop.

**Version**: 1.0.1+3 | **SDK**: Dart ^3.7.2 | **Backend**: Java Spring Boot at `https://app.esppapel.com:8443`

## Architecture

### Clean Architecture Pattern
```
lib/
├── core/           # Cross-cutting concerns
│   ├── config/     # Router (GoRouter), app configuration
│   ├── constants/  # API endpoints, app version
│   ├── network/    # DioClient with JWT interceptors
│   ├── state/      # Riverpod providers
│   ├── theme/      # AppTheme with Material3
│   └── utils/      # SecureStorage, validators, responsive utils
├── domain/         # Business logic layer
│   ├── entities/   # Pure Dart domain models (e.g., LoginEntity, EntregaEntity)
│   └── repositories/ # Abstract repository interfaces
├── data/           # Data layer
│   ├── models/     # JSON serialization models (fromJson/toJson/toEntity/fromEntity)
│   └── repositories/ # Repository implementations (e.g., EntregasImpl)
└── presentation/   # UI layer
    ├── screens/    # Full-screen views (organized by feature)
    └── widgets/    # Reusable components (organized by feature)
```

**Critical Pattern**: Models (`data/models`) handle JSON serialization and convert to/from Entities (`domain/entities`). Entities are immutable domain objects used throughout the app.

## State Management - Riverpod

### Provider Patterns
- **State Management**: `StateNotifierProvider` for mutable state (see `UserStateNotifier`, `ThemeNotifier`)
- **Async Data**: `FutureProvider` for async loading (e.g., `empleadosListProvider`, `asyncUserProvider`)
- **Simple State**: `StateProvider` for primitive values (e.g., `authStateProvider`, `isDarkModeProvider`)
- **Repository Injection**: Providers created in `main.dart` with overrides for dependency injection

### Key Providers
```dart
// User authentication state - central to authorization flow
final userProvider = StateNotifierProvider<UserStateNotifier, LoginEntity?>(...)
final asyncUserProvider = FutureProvider<LoginEntity?>(...)  // For async user validation

// Global auth state for router redirects
final authStateProvider = StateProvider<bool>((ref) => false);
```

**Consumer Patterns**: Use `ConsumerWidget` or `ConsumerStatefulWidget` for widgets needing provider access. Access with `ref.watch(provider)` or `ref.read(provider)`.

## Navigation - GoRouter

### Route Structure
- **Shell Route Pattern**: `DashboardScreen` wraps all authenticated routes, maintaining persistent sidebar
- **URL-based**: Routes follow `/dashboard/{module}/{action}` pattern (e.g., `/dashboard/trch_choferEntrega/Revision`)
- **Legacy Redirects**: Top-level routes redirect to dashboard equivalents for backward compatibility
- **Auth Guard**: `redirect` callback in router checks token expiration via `SecureStorage().isTokenExpired()`

### Critical Navigation Details
- Router instance stored in global `_router` variable, reused across app
- `authStateProvider` triggers router refresh via `GoRouterRefreshStream`
- Pass complex objects via `state.extra` (not URL params) - see change-password route
- `DioClient.setAuthErrorCallback()` configured to redirect to login on 401 errors

## Authentication & Security

### Token Management (`lib/core/utils/secure_storage.dart`)
- JWT tokens stored in `FlutterSecureStorage` with expiration tracking
- `saveToken()` extracts `exp` claim from JWT payload, stores as `token_expiry`
- `isTokenExpired()` checked before API calls and route navigation
- Session clearing (`clearSession()`) removes token, user data, and resets button permissions

### Auth Flow
1. Login → JWT received → `SecureStorage.saveToken()` → `UserStateNotifier.setUser()`
2. `DioClient` interceptor adds `Authorization: Bearer {token}` to all requests
3. 401 response → `DioClient` clears session → triggers `_onAuthError()` callback → redirects to `/login`
4. Version mismatch check: `AppConstants.APP_VERSION` validated against stored user data

## API Communication

### DioClient Pattern (`lib/core/network/dio_client.dart`)
```dart
final Dio _dio = DioClient.getInstance();  // Always use singleton

// Standard POST request
final response = await _dio.post(
  AppConstants.entregasEndpoint,
  data: {'uchofer': uchofer},
);

// PDF download
final bytes = await DioClient.descargarReportePdf(
  endpoint: AppConstants.depGenPdfDeposito + docNum,
  data: {'param': value},
);
```

**Error Handling**: Wrap in `try-catch` with `DioException`. Check `e.response?.statusCode` and `e.response?.data` for server errors.

### Endpoints (`lib/core/constants/app_constants.dart`)
- All API endpoints defined as constants (e.g., `loginEndpoint`, `entregasEndpoint`)
- Base URL configurable (production vs local dev)
- Non-API URLs: Nominatim geocoding, Google Maps links

## Data Flow Pattern

### Repository Implementation Example
```dart
// 1. Domain layer defines contract
abstract class EntregasRepository {
  Future<List<EntregaEntity>> getEntregas(int uchofer);
}

// 2. Data layer implements with Model conversion
class EntregasImpl implements EntregasRepository {
  final Dio _dio = DioClient.getInstance();
  
  Future<List<EntregaEntity>> getEntregas(int uchofer) async {
    final response = await _dio.post(AppConstants.entregasEndpoint, data: {'uchofer': uchofer});
    final items = (response.data as List<dynamic>)
        .map((json) => EntregaModel.fromJson(json))  // JSON → Model
        .toList();
    return items.map((model) => model.toEntity()).toList();  // Model → Entity
  }
}
```

**Always**: JSON → Model (`fromJson`) → Entity (`toEntity`) → UI | UI → Entity → Model (`fromEntity`) → JSON (`toJson`) → API

## Responsive Design

### Utility Class (`lib/core/utils/responsive_utils_bosque.dart`)
```dart
// Device detection
ResponsiveUtilsBosque.isDesktop(context)  // > 801px or large displays
ResponsiveUtilsBosque.isTablet(context)   // 451-800px
ResponsiveUtilsBosque.isMobile(context)   // < 451px

// Adaptive values
ResponsiveUtilsBosque.getResponsiveValue<double>(
  context: context,
  mobile: 16.0,
  tablet: 20.0,
  desktop: 32.0,
);
```

**Breakpoints**: Defined with `responsive_framework` package - MOBILE (0-450), TABLET (451-800), DESKTOP (801-1920), 4K (1921+)

**Special Cases**: iPad Pro detection (1000-1366px) for optimized layouts

## UI Patterns

### Widget Structure
- **Feature Folders**: Screens and widgets organized by module (e.g., `entregas/`, `ventas/`, `control-combustible/`)
- **Shared Widgets**: Common components in `presentation/widgets/shared/` (e.g., `auth_gate.dart`)
- **Consumer Widgets**: Prefer `ConsumerStatefulWidget` for forms and complex state; `ConsumerWidget` for simple reactive UIs

### Theme System
- **Material3** with `useMaterial3: true`
- Theme managed by `ThemeNotifier` (Riverpod): `state.copyWith(isDarkMode: !state.isDarkMode)`
- Color schemes: 9 predefined colors in `colorList`, selectable via `selectedColorProvider`
- Desktop optimizations: `MouseRegion` wrapper in `main.dart` for hover effects

## Development Workflow

### Running the App
```powershell
# Development run
flutter run -d windows  # or chrome, android, ios

# Build APK
flutter build apk --release

# Build web
flutter build web --release
```

### Linting & Analysis
- **analyzer** configured in `analysis_options.yaml`
- `use_build_context_synchronously: ignore` - allowed for async navigation
- `deprecated_member_use: ignore` - legacy API usage permitted
- Lints from `package:flutter_lints/flutter.yaml`

### Testing
No test infrastructure currently configured. Unit tests would go in `test/` directory.

## Common Tasks

### Adding a New Feature Module
1. **Define entity** in `lib/domain/entities/{feature}_entity.dart`
2. **Create repository interface** in `lib/domain/repositories/{feature}_repository.dart`
3. **Add API endpoint** to `AppConstants` in `lib/core/constants/app_constants.dart`
4. **Implement model** in `lib/data/models/{feature}_model.dart` with `fromJson`, `toJson`, `toEntity`, `fromEntity`
5. **Implement repository** in `lib/data/repositories/{feature}_impl.dart`
6. **Create provider** in `lib/core/state/{feature}_provider.dart`
7. **Build screen** in `lib/presentation/screens/{feature}/`
8. **Add route** to `lib/core/config/router.dart` under `ShellRoute` for dashboard

### Adding a New API Endpoint
1. Add constant to `AppConstants`: `static const String myEndpoint = '/my/endpoint';`
2. Implement repository method using `DioClient.getInstance()`
3. Handle errors with try-catch around `DioException`

### Managing User Permissions
- Button-level permissions: `buttonPermissionsProvider` loads per-user
- Check permissions: `ref.watch(buttonPermissionsProvider).contains(buttonId)`
- Permissions cleared on logout in `UserStateNotifier.clearUser()`

## Critical Gotchas

1. **Context After Async**: `use_build_context_synchronously` warning suppressed - verify context is still valid before navigation
2. **Token Expiration**: Always check `SecureStorage().isTokenExpired()` before sensitive operations
3. **Version Mismatch**: User data cleared if `APP_VERSION` doesn't match stored version
4. **Model vs Entity**: Never pass Models to UI - always convert to Entities
5. **Router Singleton**: Don't recreate router - use global `_router` instance from `routerProvider`
6. **Provider Overrides**: Repository providers overridden in `main.dart` - update `overrides` list for new repos
7. **Date Formatting**: Backend expects `yyyy-MM-dd HH:mm:ss` format - use `.toIso8601String().substring(0, 19).replaceAll('T', ' ')`

## Key Dependencies
- **flutter_riverpod**: State management
- **go_router**: Declarative routing
- **dio**: HTTP client
- **flutter_secure_storage**: Encrypted credential storage
- **responsive_framework**: Responsive breakpoints
- **pluto_grid**: Data tables for desktop
- **geolocator/geocoding**: Location services for deliveries
- **pdf/printing**: PDF generation and viewing

## Code Style
- Immutable entities with `final` fields
- Repository pattern with abstract interfaces
- Async/await for all API calls
- Error handling with try-catch and `DioException`
- Provider naming: `{feature}Provider`, `{feature}NotifierProvider`
- File naming: snake_case (e.g., `entregas_home_screen.dart`)
