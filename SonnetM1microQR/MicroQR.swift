import Foundation
struct MicroQR {
    static func generateM1WithData() -> [[Bool]] {
        // Create the QR matrix (11x11 for M1)
        var matrix = Array(repeating: Array(repeating: false, count: 11), count: 11)
        
        // 1. Add finder pattern (top-left 7x7)
        for i in 0...6 {
            for j in 0...6 {
                // Outer border
                if i == 0 || i == 6 || j == 0 || j == 6 {
                    matrix[i][j] = true
                }
                // Inner square
                else if i >= 2 && i <= 4 && j >= 2 && j <= 4 {
                    matrix[i][j] = true
                }
            }
        }
        
        // 2. Add timing patterns
        // Horizontal timing pattern (row 0, positions 7-10)
        for j in 7...10 {
            matrix[0][j] = j % 2 == 0
        }
        
        // Vertical timing pattern (column 0, positions 7-10)
        for i in 7...10 {
            matrix[i][0] = i % 2 == 0
        }
        
        // 3. Add format information for mask pattern 0
        let formatBits = [true, false, false, false, false, false, true, true, false, false, false, false, false, true, true]
        
        // Place format bits in row 8 (positions 1-8)
        for j in 1...8 {
            matrix[8][j] = formatBits[j-1]
        }
        
        // Place remaining format bits in column 8 (positions 1-7)
        for i in 1...7 {
            matrix[i][8] = formatBits[i+7]
        }
        
        // 4. Encode data "23"
        // Mode indicator (0 for numeric) = 0
        // Character count (2) in 3 bits = 010
        // Two digits (23) = (2×10 + 3 = 23) in 7 bits = 0010111
        let dataBits = [
            // Mode indicator (1 bit)
            false,
            // Character count (3 bits)
            false, true, false,
            // Value 23 (7 bits)
            false, false, true, false, true, true, true
        ]
        
        print("\nData bits to be placed:")
        print("Mode indicator (1 bit):     \(dataBits[0])")
        print("Character count (3 bits):   \(dataBits[1..<4].map { $0 })")
        print("Value 1 (4 bits):          \(dataBits[4..<8].map { $0 })")
        
        // 5. Place data bits
        var bitIndex = 0
        print("\nBit placement positions (row, col):")
        // Data placement starts from bottom-right, going up in columns
        for col in stride(from: 10, through: 0, by: -2) {
            for row in (0...10).reversed() {
                // Skip functional patterns
                if isDataRegion(row: row, col: col) && bitIndex < dataBits.count {
                    matrix[row][col] = dataBits[bitIndex]
                    print("Bit \(bitIndex) (\(dataBits[bitIndex])) placed at: (\(row), \(col))")
                    bitIndex += 1
                }
                if isDataRegion(row: row, col: col-1) && bitIndex < dataBits.count {
                    matrix[row][col-1] = dataBits[bitIndex]
                    print("Bit \(bitIndex) (\(dataBits[bitIndex])) placed at: (\(row), \(col-1))")
                    bitIndex += 1
                }
            }
        }
        
        return matrix
    }
    
    // Helper to check if a position is in the data region
    private static func isDataRegion(row: Int, col: Int) -> Bool {
        // Return false for finder pattern (including row 7 and column 7 until intersection)
        if (row <= 6 && col <= 6) || // 7x7 square
           (row == 7 && col <= 7) || // Row 7 until intersection
           (col == 7 && row <= 7) {  // Column 7 until intersection
            return false
        }
        // Return false for timing patterns
        if row == 0 || col == 0 {
            return false
        }
        // Return false for format information (excluding timing pattern positions)
        if (row == 8 && col >= 1 && col <= 8) || // Row 8 positions 1-8
           (col == 8 && row >= 1 && row <= 7) {  // Column 8 positions 1-7
            return false
        }
        return true
    }
}

// Generate the QR code and print debug info
let matrix = MicroQR.generateM1WithData()
