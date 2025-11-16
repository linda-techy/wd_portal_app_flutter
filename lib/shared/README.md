# Shared Components

This directory contains reusable components that can be shared between the portal application and future customer application.

## Structure

```
shared/
├── auth/
│   ├── base_auth_service.dart          # Base authentication service
│   ├── base_auth_provider.dart         # Base authentication provider
│   └── base_auth_interceptor.dart      # Base authentication interceptor
├── models/
│   ├── base_auth_models.dart           # Base authentication models
│   └── base_user_info.dart             # Base user information model
├── utils/
│   ├── http_client.dart                # Shared HTTP client configuration
│   ├── storage_helper.dart             # Shared storage utilities
│   └── constants.dart                  # Shared constants
└── widgets/
    ├── base_auth_wrapper.dart          # Base authentication wrapper
    └── base_login_screen.dart          # Base login screen template
```

## Usage

### For Portal Application (Current)
- Extend base classes with portal-specific functionality
- Use `portal_` prefix for portal-specific implementations
- Import from `../shared/` for base functionality

### For Customer Application (Future - Optional)
- Extend base classes with customer-specific functionality
- Use `customer_` prefix for customer-specific implementations
- Import from `../shared/` for base functionality

## Benefits

1. **Code Reusability**: Common authentication logic is shared
2. **Consistency**: Both applications follow the same patterns
3. **Maintainability**: Changes to base functionality affect both apps
4. **Separation of Concerns**: Portal-specific and customer-specific code is clearly separated
5. **Future-Proofing**: Easy to add customer application without duplicating code

## Naming Convention

- **Base Classes**: `Base*` (e.g., `BaseAuthService`)
- **Portal Implementation**: `Portal*` (e.g., `PortalAuthService`)
- **Customer Implementation**: `Customer*` (e.g., `CustomerAuthService`)
- **Shared Utilities**: No prefix (e.g., `HttpClient`, `StorageHelper`) 