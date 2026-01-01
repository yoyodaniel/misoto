# Localization Setup Guide

This app uses iOS's built-in localization system with runtime language switching.

## How It Works

1. **Base Language**: English (for AI models)
2. **UI Translation**: Uses iOS Localizable.strings files
3. **Runtime Switching**: Language can be changed in Settings

## Setting Up Localization Files

### Step 1: Create .lproj Folders in Xcode

1. In Xcode, right-click on the `Misoto` folder
2. Select "New Group" and name it "Localizations"
3. For each language you want to support, create a folder:
   - `en.lproj` (English - base)
   - `es.lproj` (Spanish)
   - `fr.lproj` (French)
   - `de.lproj` (German)
   - `zh-Hans.lproj` (Simplified Chinese)
   - `ja.lproj` (Japanese)
   - etc.

### Step 2: Create Localizable.strings Files

In each `.lproj` folder, create a `Localizable.strings` file.

**Example: `en.lproj/Localizable.strings`** (Base - English)
```
/* App name */
"Misoto" = "Misoto";

/* App tagline */
"Share and discover amazing recipes" = "Share and discover amazing recipes";

/* Settings */
"Settings" = "Settings";
"Dark Mode" = "Dark Mode";
"Language" = "Language";
"English" = "English";
"System Language (%@)" = "System Language (%@)";
```

**Example: `es.lproj/Localizable.strings`** (Spanish)
```
/* App name */
"Misoto" = "Misoto";

/* App tagline */
"Share and discover amazing recipes" = "Comparte y descubre recetas increíbles";

/* Settings */
"Settings" = "Configuración";
"Dark Mode" = "Modo Oscuro";
"Language" = "Idioma";
"English" = "Inglés";
"System Language (%@)" = "Idioma del Sistema (%@)";
```

### Step 3: Add Languages to Xcode Project

1. Select your project in Xcode
2. Go to "Project" → "Info" → "Localizations"
3. Click "+" and add the languages you want to support
4. Make sure "Localizable.strings" is checked for each language

## Using Localization in Code

The app uses `NSLocalizedString` which will automatically use the selected language:

```swift
Text(NSLocalizedString("Settings", comment: "Settings title"))
```

The `LocalizationManager` handles switching between languages at runtime based on the user's setting.

## Language Selection

- **English**: Always uses English
- **System Language**: Uses the device's system language (if supported), falls back to English

## Notes

- AI models will always use English (base language)
- UI text is translated based on the selected language
- If a translation is missing, it falls back to English

