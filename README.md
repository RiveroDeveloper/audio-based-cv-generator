# 📄 CV Generator - Audio-based Resume Generator

## 🌐 Live Demo

**🎉 The app is live and deployed!**

**Web App:** https://scanner-6c414.web.app

Try it out directly in your browser - no installation needed!

## 🚀 Main Features

### 🎤 **Audio-based CV Generation**
- **Section-based recording**: Guided system that allows recording audio for each CV section
- **Smart AI**: Uses OpenRouter API to automatically process and organize audio information
- **Automatic transcription**: Converts audio to text and extracts structured data
- **Smart validation**: System automatically validates and organizes information

### ✍️ **Manual Form**
- **Intuitive interface**: Complete form for manually entering CV information
- **Real-time preview**: Allows viewing how the CV will look before generating the PDF
- **Data validation**: Validation system to ensure correct information

### 📑 **Professional PDF Generation**
- **Modern design**: CV with blue-purple gradient, Inter typography, and professional layout
- **Responsive**: Properly adapts to A4 format
- **Interactive preview**: Allows reviewing the CV before downloading
- **Direct download**: Automatically generates and downloads the PDF

### 🔐 **Authentication System**
- **Secure login**: Authentication system with Supabase
- **User registration**: Allows creating new accounts
- **Session management**: Automatic user session handling
- **Password recovery**: System for changing passwords

### 💾 **Database**
- **Cloud storage**: Uses Supabase to store information
- **CV history**: Saves all CVs created by the user
- **Synchronization**: Access information from any device

## 🛠️ Technologies Used

- **Flutter Web** - Main framework for the interface
- **Dart** - Programming language
- **Supabase** - Backend as a Service (BaaS)
- **OpenRouter API** - AI processing for audio
- **HTML2Canvas & jsPDF** - PDF generation
- **Google Fonts** - Modern typography
- **Audio Recording** - Audio recording and playback

## 📋 Prerequisites

To run this project locally you need:

- **Flutter SDK** >= 3.7.0
- **Dart SDK** >= 3.7.0
- **Chrome** (recommended browser)
- **Internet connection** (for APIs and Supabase)

## 🔧 Installation and Configuration

### 1. Clone the repository
```bash
git clone [REPOSITORY_URL]
cd scanner_personal
```

### 2. Verify Flutter configuration
```bash
flutter doctor
flutter config --enable-web
```

### 3. Install dependencies
```bash
flutter clean
flutter pub get
```

### 4. Configure environment variables
Create a `.env` file in the project root and configure the following variables:

```env
# Supabase Configuration
SUPABASE_URL=your_supabase_url_here
SUPABASE_ANON_KEY=your_supabase_anon_key_here

# AI APIs - Get your keys from the respective services
ASSEMBLY_API_KEY=your_assemblyai_api_key_here
OPENROUTER_API_KEY=your_openrouter_api_key_here

# PDF Generation
PDFMONKEY_API_KEY=your_pdfmonkey_api_key_here
```

**Where to get API keys:**
- **AssemblyAI**: Sign up at [assemblyai.com](https://assemblyai.com) for speech-to-text services
- **OpenRouter**: Get your key at [openrouter.ai](https://openrouter.ai) for AI text processing
- **PDF Monkey**: Register at [pdfmonkey.io](https://pdfmonkey.io) for PDF generation
- **Supabase**: Create a project at [supabase.com](https://supabase.com) for database services

> ⚠️ **Important**: Never commit your `.env` file to version control. The `.gitignore` file is already configured to exclude it.

### 5. Verify everything is ready
```bash
flutter devices
# Should show Chrome as an available device
```

### 6. First run
```bash
flutter run -d chrome
```

> 💡 **Tip**: If this is your first time running Flutter web, it may take a few minutes to download the necessary web dependencies.

## 🚀 Project Execution

### **Main command to run:**
```bash
flutter run -d chrome
```

### **For development with hot reload:**
```bash
flutter run -d chrome --debug
```

### **For release build and execution:**
```bash
flutter build web
flutter run -d chrome --release
```

### **To serve the built web application:**
```bash
flutter build web
cd build/web
python -m http.server 8000
# Or if you have Node.js installed:
# npx serve .
```

### Additional useful commands:
```bash
# Clean and rebuild completely
flutter clean && flutter pub get && flutter run -d chrome

# Build for production
flutter build web --release

# Run in debug mode with detailed information
flutter run -d chrome --debug --verbose

# Explicitly enable web (if needed)
flutter config --enable-web
flutter run -d chrome
```

> ⚠️ **Important**: 
> - This project is optimized for **Chrome** due to audio and PDF generation APIs
> - If you have issues, first run `flutter clean && flutter pub get`
> - Make sure Flutter web is enabled with `flutter config --enable-web`

## 📁 Project Structure

```
lib/
├── main.dart                          # Application entry point
├── Funcion_Audio/                     # Audio generation module
│   ├── cv_generator.dart              # Main CV audio generator
│   └── monkey_pdf_integration.dart    # PDF generation integration
├── Formulario/                        # Manual form module
│   └── cv_form.dart                   # Form for manual CV creation
├── Login/                             # Authentication system
│   ├── login_screen.dart              # Login screen
│   ├── register_screen.dart           # Registration screen
│   └── auth_router.dart               # Authentication router
├── Home/                              # Main screen
├── Perfil_Cv/                         # Profile and CV management
├── Configuracion/                     # App settings
└── AI/                                # AI integration
```

## 🎯 Usage Flow

### **Method 1: Audio Generation**
1. **Login**: Sign in to the application
2. **Select audio**: Choose "Create CV with Audio"
3. **Record by sections**: System guides through different sections
4. **AI Processing**: AI automatically processes and organizes information
5. **Review**: Review and edit extracted information
6. **Generate PDF**: Create preview and download PDF

### **Method 2: Manual Form**
1. **Login**: Sign in to the application
2. **Form**: Choose "Create Manual CV"
3. **Complete information**: Fill in all form fields
4. **Preview**: Review how the CV will look
5. **Generate PDF**: Create and download CV as PDF

## 🔑 Key Features

### **Smart Audio System**
- Recording for specific sections (personal data, experience, education, etc.)
- AI processing to extract relevant information
- Automatic transcription with error correction
- Smart data organization

### **Advanced PDF Generation**
- Professional design with gradients and modern typography
- Interactive preview before downloading
- Support for special characters and UTF-8
- A4 format optimized for printing

### **Smart Database**
- Automatic CV storage
- Real-time synchronization
- Modification history
- Automatic cloud backup

## 🐛 Troubleshooting

### **Error: "Could not find an option named '--web-renderer'"**
- This error indicates you're using a Flutter version that no longer supports that flag
- **Solution**: Simply use `flutter run -d chrome`

### **Error: "No supported devices connected"**
- Flutter web is not enabled or Chrome is not installed
- **Solution**: 
  ```bash
  flutter config --enable-web
  flutter devices
  ```

### **Error: "Cannot connect to Supabase"**
- Verify that environment variables are properly configured
- Confirm you have internet connection
- Check that Supabase credentials are valid
- **Solution**: Check the `.env` file and restart the application

### **Error: "PDF not generating correctly"**
- Issues with JavaScript PDF generation libraries
- **Solution**:
  ```bash
  flutter clean
  flutter pub get
  flutter run -d chrome
  ```
- Make sure to use **Chrome** (not other browsers)
- Confirm JavaScript is enabled

### **Error: "Audio not recording"**
- Microphone permissions not granted or HTTPS issues
- **Solution**:
  - Allow microphone permissions in Chrome
  - Verify microphone is working
  - If on localhost, it should work automatically
  - For production, HTTPS is required

### **Error: "Target of URI doesn't exist" when loading files**
- Issues with asset paths
- **Solution**:
  ```bash
  flutter pub get
  flutter clean
  flutter run -d chrome
  ```

### **Error: "XMLHttpRequest error" with Supabase**
- CORS or network configuration issues
- **Solution**:
  - Check your internet connection
  - Confirm Supabase URLs are correct

## ✅ Installation Verification

### **Checklist after cloning:**

1. **✅ Flutter configured correctly**
   ```bash
   flutter doctor
   # Should show checkmarks for Web development
   ```

2. **✅ Dependencies installed**
   ```bash
   flutter pub get
   # Should not show errors
   ```

3. **✅ Chrome available as device**
   ```bash
   flutter devices
   # Should list "Chrome" as available device
   ```

4. **✅ Environment variables configured**
   - Verify existence of `.env` file
   - Confirm it contains `SUPABASE_URL` and `SUPABASE_ANON_KEY`

5. **✅ First run successful**
   ```bash
   flutter run -d chrome
   # Application should open in Chrome and show login screen
   ```

### **All working?**
If you completed all the steps above without errors, your installation is complete! 🎉

If any step failed, refer to the "🐛 Troubleshooting" section above.

## 📝 Important Notes

- **Requires internet**: Needs connection for Supabase and AI APIs
- **Microphone permissions**: Browser will ask for microphone permissions
