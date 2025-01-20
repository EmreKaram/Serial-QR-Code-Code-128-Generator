//
//  ContentView.swift
//  QRCodeGenerator
//
//  Created by Emre Karamahmut on 16.01.2025.
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
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var selectedFormat = "QR Kod" // Varsayılan format

    let formats = ["QR Kod", "Code 128"] // Format seçenekleri

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                HStack {
                    TextField("Ürün Adı", text: $productName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Spacer()
                }

                HStack {
                    TextField("Başlangıç", text: $startNumber)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Spacer()
                    TextField("Bitiş", text: $endNumber)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }

                Picker("Format Seçin", selection: $selectedFormat) {
                    ForEach(formats, id: \.self) { format in
                        Text(format)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())

                Button(isLoading ? "Kodlar Oluşturuluyor..." : "Oluştur") {
                    if let start = Int(startNumber), let end = Int(endNumber) {
                        isLoading = true
                        DispatchQueue.global(qos: .userInitiated).async {
                            generateCodes(productName: productName, start: start, end: end, format: selectedFormat)
                            DispatchQueue.main.async {
                                isLoading = false
                            }
                        }
                    } else {
                        resultMessage = "Lütfen geçerli bir ürün adı ve sayısal aralık girin."
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
            .navigationTitle("Kod Oluşturucu")
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Kod Oluşturma"),
                    message: Text(resultMessage),
                    dismissButton: .cancel(Text("OK"), action: {
                        resultMessage = "" // Mesaj sıfırlanıyor
                    })
                )
            }
        }
    }

    func generateCodes(productName: String, start: Int, end: Int, format: String) {
        guard start <= end else {
            resultMessage = "Başlangıç değeri bitiş değerinden büyük olamaz!"
            showAlert = true
            return
        }

        guard let downloadsFolder = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
            resultMessage = "İndirilenler klasörüne erişilemedi."
            showAlert = true
            return
        }

        // Klasör adını formatına göre ayarla
        let productFolderName: String
        if format == "QR Kod" {
            productFolderName = "\(productName)_QR_CODE"
        } else {
            productFolderName = "\(productName)_CODE_128"
        }

        let productFolderURL = downloadsFolder.appendingPathComponent(productFolderName)

        do {
            try FileManager.default.createDirectory(at: productFolderURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            resultMessage = "Dizin oluşturulamadı: \(error.localizedDescription)"
            showAlert = true
            return
        }

        let context = CIContext()

        for i in start...end {
            let formattedNumber = String(format: "%04d", i)
            let codeText = "\(productName)-\(formattedNumber)"
            let fileName: String

            // Dosya adını formatına göre ayarla
            if format == "QR Kod" {
                fileName = "\(productName)_QR_\(formattedNumber).png"
                generateQRCode(context: context, text: codeText, fileURL: productFolderURL.appendingPathComponent(fileName))
            } else if format == "Code 128" {
                fileName = "\(productName)_BARCODE_\(formattedNumber).png"
                generateCode128(context: context, text: codeText, fileURL: productFolderURL.appendingPathComponent(fileName))
            }
        }

        NSWorkspace.shared.open(productFolderURL)
        resultMessage = "\(format) başarıyla \(productFolderURL.path) konumuna oluşturuldu!"
        showAlert = true
    }

    func generateQRCode(context: CIContext, text: String, fileURL: URL) {
            let filter = CIFilter.qrCodeGenerator()
            filter.message = Data(text.utf8)

            if let qrImage = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 10, y: 10)) {
                // Arka planı kaldırmak için maskeler
                let transparentImage = qrImage.applyingFilter("CIFalseColor", parameters: [
                    "inputColor0": CIColor.black, // QR kodu siyah yap
                    "inputColor1": CIColor.clear // Arka planı şeffaf yap
                ])

                saveImage(context: context, image: transparentImage, fileURL: fileURL)
            }
        }

    func generateCode128(context: CIContext, text: String, fileURL: URL) {
        let filter = CIFilter(name: "CICode128BarcodeGenerator")
        filter?.setValue(Data(text.utf8), forKey: "inputMessage")

        if let barcodeImage = filter?.outputImage?.transformed(by: CGAffineTransform(scaleX: 3, y: 3)) {
            saveImage(context: context, image: barcodeImage, fileURL: fileURL)
        }
    }

    func saveImage(context: CIContext, image: CIImage, fileURL: URL) {
        if let cgImage = context.createCGImage(image, from: image.extent) {
            let rep = NSBitmapImageRep(cgImage: cgImage)
            guard let data = rep.representation(using: .png, properties: [:]) else {
                resultMessage = "PNG verisi oluşturulamadı."
                showAlert = true
                return
            }
            do {
                try data.write(to: fileURL)
                print("\(fileURL) oluşturuldu.")
            } catch {
                resultMessage = "Dosya kaydedilemedi \(fileURL.lastPathComponent): \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
}
