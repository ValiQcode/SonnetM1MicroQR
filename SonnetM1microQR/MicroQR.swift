import Foundation

struct GF256 {
    // GF(256) exponential table - α^i
    static let expTable: [Int] = {
        var exp = [Int](repeating: 0, count: 256)
        var x = 1
        for i in 0..<256 {
            exp[i] = x
            x = x << 1
            if x > 255 {
                x = x ^ 0b100011101 // XOR with primitive polynomial
            }
        }
        return exp
    }()
    
    // GF(256) log table - log_α(i)
    static let logTable: [Int] = {
        var log = [Int](repeating: 0, count: 256)
        for i in 0..<255 {
            log[expTable[i]] = i
        }
        return log
    }()
    
    // Multiply two elements in GF(256)
    static func multiply(_ a: Int, _ b: Int) -> Int {
        if a == 0 || b == 0 { return 0 }
        let sum = logTable[a] + logTable[b]
        return expTable[sum % 255]
    }
}

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
        var dataBits: [Bool] = []
        
        // Character count (3 bits)
        dataBits.append(contentsOf: [false, false, true]) // 001 for length 1
        
        // Data (4 bits for single digit)
        let value = Int(data)!
        let binaryString = String(value, radix: 2).padLeft(toLength: 4, withPad: "0")
        dataBits.append(contentsOf: binaryString.map { $0 == "1" })
        
        // Terminator (3 bits)
        dataBits.append(contentsOf: [false, false, false])
        
        // Pad to 8 bits for first two codewords
        while dataBits.count < 16 {
            dataBits.append(false)
        }
        
        // Add 4 bits for final data codeword
        while dataBits.count < 20 {
            dataBits.append(false)
        }
        
        // Convert bit array to codewords
        var messagePolynomial = bitsToCodewords(dataBits)
        
        // Generate error detection codewords
        let errorCodewords = generateErrorDetection(messagePolynomial)
        
        // Convert everything back to bits for placement
        var allBits = dataBits
        allBits.append(contentsOf: codewordsToBits(errorCodewords))
        
        
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
        
        // 6. Apply mask pattern 00: (i + j) mod 2 = 0
        for i in 0...10 {
            for j in 0...10 {
                if isDataRegion(row: i, col: j) {
                    // XOR the module if sum of row and column is even
                    if (i + j) % 2 == 0 {
                        matrix[i][j].toggle()
                    }
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
    
    private static func bitsToCodewords(_ bits: [Bool]) -> [Int] {
        var codewords: [Int] = []
        var currentByte = 0
        
        for (index, bit) in bits.enumerated() {
            if index > 0 && index % 8 == 0 {
                codewords.append(currentByte)
                currentByte = 0
            }
            currentByte = (currentByte << 1) | (bit ? 1 : 0)
        }
        if bits.count % 8 != 0 {
            codewords.append(currentByte << (8 - (bits.count % 8)))
        }
        
        return codewords
    }
    
    private static func codewordsToBits(_ codewords: [Int]) -> [Bool] {
        var bits: [Bool] = []
        for codeword in codewords {
            for i in (0..<8).reversed() {
                bits.append((codeword & (1 << i)) != 0)
            }
        }
        return bits
    }
    
    private static func generateErrorDetection(_ message: [Int]) -> [Int] {
        // Generator polynomial coefficients for n=2:
        // x^2 + α^25x + α^5
        let generatorDegree = 2
        let generator = [1, GF256.expTable[25], GF256.expTable[5]]
        
        // Initialize remainder buffer
        var remainder = message + [Int](repeating: 0, count: generatorDegree)
        
        // Polynomial division
        for i in 0..<message.count {
            let lead = remainder[i]
            if lead != 0 {
                for j in 0..<generator.count {
                    let term = GF256.multiply(generator[j], lead)
                    remainder[i + j] ^= term
                }
            }
        }
        
        // Return the error detection codewords (last 2 bytes)
        return Array(remainder.suffix(generatorDegree))
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
