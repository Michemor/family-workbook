# Family Growth System - Authentication UI

This Flutter app now includes beautiful Sign In and Sign Up screens themed after "The Family Toolbox" aesthetic.

## 🎨 Design Features

### Color Palette
- **Primary Purple**: `#6B4BA0` - Deep purple from the app icon
- **Accent Gold**: `#D4A574` - Warm gold reminiscent of the book cover
- **Dark Brown**: `#5C4033` - Rich earth tone
- **Light Beige**: `#F5F1E8` - Soft cream background
- **Soft Tan**: `#E8DCC8` - Subtle accent color

### Theme Inspiration
The design draws from the Family Toolbox brand identity:
- Warm, earthy tones
- Modern, clean interface
- Welcoming and inviting atmosphere
- Professional yet approachable

## 📱 Screens Created

### 1. Sign In Screen (`lib/screens/sign_in_screen.dart`)
- Email and password fields
- Password visibility toggle
- "Forgot Password?" link
- Sign up link for new users
- Form validation
- Loading indicator during authentication

**Features:**
- Beautiful gradient background
- Rounded form container
- Icon prefix inputs
- Email validation
- Password length validation

### 2. Sign Up Screen (`lib/screens/sign_up_screen.dart`)
- Full name field
- Email field
- Password field
- Password confirmation field
- Family Information section:
  - Family name field
  - Family type dropdown (Nuclear, Extended, Single Parent, Blended, Adoptive, Other)
  - Country field
- Form validation
- Loading indicator

**Features:**
- Complete family profile setup
- Multi-section form layout
- Custom dropdown styling
- Comprehensive validation
- Smooth scrolling on small screens

## 🎯 Theme Configuration

### `lib/theme/app_theme.dart`
Centralized theme configuration including:
- Color constants
- Typography styles
- Input field decoration
- Button styles
- App bar theme
- Complete ThemeData setup

## 🔗 Navigation

Routes configured in `main.dart`:
- `/signin` - Sign in screen
- `/signup` - Sign up screen

Current home screen: `SignInScreen`

## 📋 Form Validation

Both screens include:
- Email validation (format checking)
- Password validation (minimum 6 characters)
- Password confirmation matching
- Required field validation
- Name validation (minimum 2 characters)

## 🚀 Next Steps to Integrate Firebase

The screens are ready for Firebase integration. In each screen, replace the TODO comments with actual Firebase Authentication logic:

### Sign In Screen (`sign_in_screen.dart` - line ~48)
```dart
void _handleSignIn() {
  if (_formKey.currentState!.validate()) {
    setState(() {
      _isLoading = true;
    });
    
    // Add Firebase authentication here
    FirebaseAuth.instance.signInWithEmailAndPassword(
      email: _emailController.text,
      password: _passwordController.text,
    ).then((_) {
      // Navigate to home
      Navigator.pushReplacementNamed(context, '/home');
    }).catchError((e) {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }).whenComplete(() {
      setState(() {
        _isLoading = false;
      });
    });
  }
}
```

### Sign Up Screen (`sign_up_screen.dart` - line ~58)
```dart
void _handleSignUp() {
  if (_formKey.currentState!.validate()) {
    // Add Firebase authentication here
    FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: _emailController.text,
      password: _passwordController.text,
    ).then((_) {
      // Save family information to Firestore
      // Navigate to home
    }).catchError((e) {
      // Show error
    });
  }
}
```

## 💡 Customization Tips

1. **Colors**: Modify constants in `lib/theme/app_theme.dart`
2. **Typography**: Adjust text styles in the theme
3. **Validation**: Enhance validators in form fields
4. **Icons**: Change `Icons` used throughout the screens
5. **Spacing**: Adjust `SizedBox` heights and padding

## 📦 Dependencies

Already configured in your project:
- `flutter/material.dart` - UI components
- `firebase_core` - Firebase initialization
- `firebase_auth` - Authentication (ready to use)

Optionally add:
- `cloud_firestore` - For storing family data
- `provider` - For state management
- `google_sign_in` - For Google authentication

---

**Happy coding! 🎨✨**
