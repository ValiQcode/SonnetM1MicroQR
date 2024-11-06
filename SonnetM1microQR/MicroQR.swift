import Foundation

struct MicroQR {
    static func generateM1WithData(data: String) -> [[Bool]] {
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
        
        // 3. Add format information for M1 with mask pattern 0
        let formatBits = [true, false, false, false, true, false, false, false, true, false, false, false, true, false, true]
        
        // Place format bits
        for i in 1...8 {
            matrix[i][8] = formatBits[i-1]
        }
        for j in (1...7).reversed() {
            matrix[8][j] = formatBits[15-j]
        }
        
        // 4. Encode data
        // For M1: Character count is 3 bits, numeric only
        let characterCount = data.count
        let characterCountBits = String(characterCount, radix: 2).padLeft(toLength: 3, withPad: "0")
            .map { $0 == "1" }
            
        // Encode numeric data
        var dataBits: [Bool] = []
        var digits = data
        while !digits.isEmpty {
            let groupSize = min(3, digits.count)
            let group = String(digits.prefix(groupSize))
            digits = String(digits.dropFirst(groupSize))
            
            // Convert group to binary
            let value = Int(group)!
            let binaryLength = groupSize == 3 ? 10 : (groupSize == 2 ? 7 : 4)
            let binaryString = String(value, radix: 2).padLeft(toLength: binaryLength, withPad: "0")
            dataBits.append(contentsOf: binaryString.map { $0 == "1" })
        }
        
        // Add Terminator (3 bits for M1)
        dataBits.append(contentsOf: [false, false, false])
        
        // Convert to 4-bit codewords and pad if needed
        while dataBits.count % 4 != 0 {
            dataBits.append(false)
        }
        
        // 5. Place data bits in matrix
        var bitIndex = 0
        for col in stride(from: 10, through: 0, by: -2) {
            for row in (0...10).reversed() {
                if isDataRegion(row: row, col: col) && bitIndex < dataBits.count {
                    matrix[row][col] = dataBits[bitIndex]
                    bitIndex += 1
                }
                if isDataRegion(row: row, col: col-1) && bitIndex < dataBits.count {
                    matrix[row][col-1] = dataBits[bitIndex]
                    bitIndex += 1
                }
            }
        }
        
        return matrix
    }
    
    private static func isDataRegion(row: Int, col: Int) -> Bool {
        if (row <= 6 && col <= 6) ||
           (row == 7 && col <= 7) ||
           (col == 7 && row <= 7) {
            return false
        }
        if row == 0 || col == 0 {
            return false
        }
        if (row == 8 && col >= 1 && col <= 8) ||
           (col == 8 && row >= 1 && row <= 7) {
            return false
        }
        return true
    }
}

// Helper extension
extension String {
    func padLeft(toLength: Int, withPad character: Character) -> String {
        let length = self.count
        if length < toLength {
            return String(repeating: character, count: toLength - length) + self
        }
        return self
    }
}
