# QR Code & Code 128 Generator

A powerful macOS application built with SwiftUI that allows users to generate high-quality **QR Codes** and **Code 128 barcodes**. Perfect for managing product labels, inventory tracking, or any scenario requiring visually clean and accurate code generation.

## Features

### 🛠 Flexible Code Formats  
- **QR Codes**: Black foreground with a transparent background for seamless integration into any design.  
- **Code 128 Barcodes**: Industry-standard barcodes for robust and reliable use.  

### ⚡ Batch Generation  
Generate codes in bulk by providing a start and end range. The app automatically organizes your files into corresponding folders:  
- `ProductName_qr` for QR Codes  
- `ProductName_128` for Code 128 Barcodes  

### ‼️ Important Note  
After opening the project in Xcode, follow these steps to build and use the app:  
1. Go to **Product** → **Archive** → **Distribute App**.  
2. Choose **Custom** → **Copy App** → **Export**.  
3. Move the exported `.app` file into your Mac's Applications folder. 

### For example, if you enter:
- **Product Name**: MyProduct
- **Start Number**: 1
- **End Number**: 5
- **Delimiter**: -
  
The application will generate the following files in the Downloads folder:
1. MyProduct-0001_qr.png
2. MyProduct-0002_qr.png
3. MyProduct-0003_qr.png
4. MyProduct-0004_qr.png
5. MyProduct-0005_qr.png

### 📂 Smart File Management  
All codes are saved in the `Downloads` folder under format-specific directories for easy access and organization.  

### 🧑‍💻 User-Friendly Interface  
- Modern SwiftUI design for smooth navigation.  
- Real-time progress indicator during generation.  
- Clear error messages for invalid input or generation issues.  

## Tech Stack  
- **SwiftUI**: Provides a sleek, native macOS interface.  
- **Core Image Filters**: Used for QR Code and barcode generation with customizable styles.  
- **macOS Native APIs**: `FileManager` for file handling, `NSWorkspace` for opening directories.  

 

This application is compatible with **macOS 15 (Sequoia)** and later.(maybe you can change it from settings I didn't try it) 

## Screenshots  
![App Screenshot](app_photo.png)  
