import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Text("M1 Micro QR Code for '123456'")
                .font(.title)
                .padding()
            
            QRCodeView(matrix: MicroQR.generateM1WithData())
                .frame(width: 220, height: 220)
                .border(Color.gray, width: 1)
        }
    }
}

struct QRCodeView: View {
    let matrix: [[Bool]]
    
    var body: some View {
        GeometryReader { geometry in
            let moduleSize = min(geometry.size.width, geometry.size.height) / CGFloat(matrix.count)
            
            Path { path in
                for row in 0..<matrix.count {
                    for col in 0..<matrix[row].count {
                        if matrix[row][col] {
                            let rect = CGRect(x: CGFloat(col) * moduleSize,
                                           y: CGFloat(row) * moduleSize,
                                           width: moduleSize,
                                           height: moduleSize)
                            path.addRect(rect)
                        }
                    }
                }
            }
            .fill(Color.black)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

#Preview {
    ContentView()
}
