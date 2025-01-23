//
//  ContentView.swift
//  QR & Barcode Generator
//
//  Created by Emre Karamahmut on 23.01.2025.
//

import SwiftUI
import CoreImage.CIFilterBuiltins
import AppKit
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var resultMessage = ""
    @State private var productName: String = ""
    @State private var startNumber: String = ""
    @State private var endNumber: String = ""
    @State private var delimiter: String = "-" // Default delimiter
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var selectedFormat = "QR Code" // Default format
    @State private var useWhiteQR = false // Toggle for white QR code

    let formats = ["QR Code", "Code 128"] // Format options

    var body: some View {
        NavigationView {
            VStack(spacing: 10) {
                HStack {
                    TextField("Product Name", text: $productName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Spacer()
                }

                HStack {
                    TextField("Start Number", text: $startNumber)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Spacer()
                    TextField("End Number", text: $endNumber)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }

                HStack {
                    TextField("Delimiter (e.g., -, _, /)", text: $delimiter)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Spacer()
                }

                Picker("Select Format", selection: $selectedFormat) {
                    ForEach(formats, id: \.self) { format in
                        Text(format)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())

                // Toggle for white QR codes
                if selectedFormat == "QR Code" {
                    Toggle("Use White QR Code", isOn: $useWhiteQR)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                }

                Button(isLoading ? "Generating Codes..." : "Generate") {
                    if let start = Int(startNumber), let end = Int(endNumber) {
                        isLoading = true
                        DispatchQueue.global(qos: .userInitiated).async {
                            generateCodes(productName: productName, start: start, end: end, delimiter: delimiter, format: selectedFormat)
                            DispatchQueue.main.async {
                                isLoading = false
                            }
                        }
                    } else {
                        resultMessage = "Please enter a valid product name, numeric range, and delimiter."
                        showAlert = true
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading)

                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .accentColor(.blue)
                }

                Text(resultMessage)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .navigationTitle("Code Generator")
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Code Generation"),
                    message: Text(resultMessage),
                    dismissButton: .cancel(Text("OK"), action: {
                        resultMessage = "" // Clear message
                    })
                )
            }
        }
    }

    func generateCodes(productName: String, start: Int, end: Int, delimiter: String, format: String) {
        guard start <= end else {
            resultMessage = "Start value cannot be greater than end value!"
            showAlert = true
            return
        }

        guard let downloadsFolder = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
            resultMessage = "Unable to access Downloads folder."
            showAlert = true
            return
        }

        let productFolderName: String
        if format == "QR Code" {
            productFolderName = "\(productName)_QR_CODE"
        } else {
            productFolderName = "\(productName)_CODE_128"
        }

        let productFolderURL = downloadsFolder.appendingPathComponent(productFolderName)

        do {
            try FileManager.default.createDirectory(at: productFolderURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            resultMessage = "Failed to create directory: \(error.localizedDescription)"
            showAlert = true
            return
        }

        let context = CIContext()

        for i in start...end {
            let formattedNumber = String(format: "%04d", i)
            let codeText = "\(productName)\(delimiter)\(formattedNumber)"
            let fileName: String

            if format == "QR Code" {
                fileName = "\(productName)\(delimiter)\(formattedNumber)_qr.png"
                generateQRCode(context: context, text: codeText, fileURL: productFolderURL.appendingPathComponent(fileName))
            } else if format == "Code 128" {
                fileName = "\(productName)\(delimiter)\(formattedNumber)_barcode.png"
                generateCode128(context: context, text: codeText, fileURL: productFolderURL.appendingPathComponent(fileName))
            }
        }

        NSWorkspace.shared.open(productFolderURL)
        resultMessage = "\(format)s have been successfully generated at \(productFolderURL.path)!"
        showAlert = true
    }

    func generateQRCode(context: CIContext, text: String, fileURL: URL) {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)

        if let qrImage = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 10, y: 10)) {
            let color0 = useWhiteQR ? CIColor.white : CIColor.black
            let color1 = useWhiteQR ? CIColor.clear : CIColor.clear

            let coloredImage = qrImage.applyingFilter("CIFalseColor", parameters: [
                "inputColor0": color0, // Adjust based on toggle
                "inputColor1": color1
            ])

            saveImage(context: context, image: coloredImage, fileURL: fileURL)
        }
    }

    func generateCode128(context: CIContext, text: String, fileURL: URL) {
        let filter = CIFilter(name: "CICode128BarcodeGenerator")
        filter?.setValue(Data(text.utf8), forKey: "inputMessage")

        // Safely unwrap the outputImage
        guard let barcodeImage = filter?.outputImage?.transformed(by: CGAffineTransform(scaleX: 3, y: 3)) else {
            print("Error: Failed to generate Code 128 barcode for text \(text).")
            return
        }

        // Add text below the barcode
        let labeledBarcode = addTextOnBarcode(image: barcodeImage, text: text)

        // Save the resulting image
        if let labeledImage = labeledBarcode {
            saveImage(context: context, image: labeledImage, fileURL: fileURL)
        } else {
            print("Error: Failed to add text to barcode for \(text).")
        }
    }

    func addTextOnBarcode(image: CIImage?, text: String) -> CIImage? {
        // Safely unwrap the optional image
        guard let image = image else {
            print("Error: No image provided to add text.")
            return nil
        }

        // Convert the barcode to CGImage
        let context = CIContext()
        guard let cgImage = context.createCGImage(image, from: image.extent) else {
            print("Error: Failed to convert CIImage to CGImage.")
            return nil
        }

        let barcodeSize = image.extent.size
        let textFontSize: CGFloat = 20

        // Create a new NSImage of the same size as the barcode image
        let combinedImage = NSImage(size: CGSize(width: barcodeSize.width, height: barcodeSize.height))

        combinedImage.lockFocus()

        // Draw the barcode
        let barcodeRect = CGRect(x: 0, y: 0, width: barcodeSize.width, height: barcodeSize.height)
        NSGraphicsContext.current?.cgContext.draw(cgImage, in: barcodeRect)

        // Set up text attributes
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: textFontSize),
            .paragraphStyle: paragraphStyle,
            .foregroundColor: NSColor.black
        ]

        // Adjust the text position slightly down within the PNG
        let yOffset: CGFloat = 65 // Move the text slightly downward (tweak this value as needed)
        let textYPosition = (barcodeSize.height / 2) - textFontSize / 2 - yOffset // Lower than center
        let textRect = CGRect(x: 0, y: textYPosition, width: barcodeSize.width, height: textFontSize)

        // Draw the text in the new position
        text.draw(in: textRect, withAttributes: attributes)

        combinedImage.unlockFocus()

        // Convert NSImage back to CIImage
        guard let tiffData = combinedImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            print("Error: Failed to convert NSImage to CIImage.")
            return nil
        }

        return CIImage(bitmapImageRep: bitmap)
    }
    
    func saveImage(context: CIContext, image: CIImage, fileURL: URL) {
        if let cgImage = context.createCGImage(image, from: image.extent) {
            let rep = NSBitmapImageRep(cgImage: cgImage)
            guard let data = rep.representation(using: .png, properties: [:]) else {
                resultMessage = "Failed to create PNG data."
                showAlert = true
                return
            }
            do {
                try data.write(to: fileURL)
                print("\(fileURL) has been created.")
            } catch {
                resultMessage = "Failed to save file \(fileURL.lastPathComponent): \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
}
