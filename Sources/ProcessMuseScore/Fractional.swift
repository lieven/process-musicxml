// Now availbile as a Swift package on GitHub!
// https://github.com/jadengeller/fractional


private func gcd(_ first: Int, _ second: Int) -> Int {
	var lhs = first
	var rhs = second
	while rhs != 0 { (lhs, rhs) = (rhs, lhs % rhs) }
	return lhs
}
	
private func lcm(_ lhs: Int, _ rhs: Int) -> Int {
	return lhs * rhs / gcd(lhs, rhs)
}

private func reduce(numerator: Int, denominator: Int) -> (numerator: Int, denominator: Int) {
	var divisor = gcd(numerator, denominator)
	if divisor < 0 { divisor *= -1 }
	guard divisor != 0 else { return (numerator: numerator, denominator: 0) }
	return (numerator: numerator / divisor, denominator: denominator / divisor)
}

public struct Fractional: Hashable {
	/// The numerator of the fraction.
	public let numerator: Int
	
	/// The (always non-negative) denominator of the fraction.
	public let denominator: Int
	
	public init(numerator: Int, denominator: Int) {
		var (numerator, denominator) = reduce(numerator: numerator, denominator: denominator)
		if denominator < 0 { numerator *= -1; denominator *= -1 }
								
		self.numerator = numerator
		self.denominator = denominator
	}
    
    /// Create an instance initialized to `value`.
    public init(_ value: Int) {
        self.init(numerator: value, denominator: 1)
    }
}	

extension Fractional: Equatable {}
public func ==(lhs: Fractional, rhs: Fractional) -> Bool {
	return lhs.numerator == rhs.numerator && lhs.denominator == rhs.denominator
}

extension Fractional: Comparable {}
public func <(lhs: Fractional, rhs: Fractional) -> Bool {
    guard !lhs.isNaN && !rhs.isNaN else { return false }
    guard lhs.isFinite && rhs.isFinite else { return lhs.numerator < rhs.numerator }
	let (lhsNumerator, rhsNumerator, _) = Fractional.commonDenominator(lhs, rhs)
	return lhsNumerator < rhsNumerator
}

extension Fractional: Strideable {
	public typealias Stride = Fractional
	
	fileprivate static func commonDenominator(_ lhs: Fractional, _ rhs: Fractional) -> (lhsNumerator: Int, rhsNumberator: Int, denominator: Int) {
		let denominator = lcm(lhs.denominator, rhs.denominator)
		let lhsNumerator = lhs.numerator * (denominator / lhs.denominator)
		let rhsNumerator = rhs.numerator * (denominator / rhs.denominator)
		
		return (lhsNumerator, rhsNumerator, denominator)
	}
	
	public func advanced(by n: Fractional) -> Fractional {
		let (selfNumerator, nNumerator, commonDenominator) = Fractional.commonDenominator(self, n)
		return Fractional(numerator: selfNumerator + nNumerator, denominator: commonDenominator)
	}
	
	public func distance(to other: Fractional) -> Fractional {
		return other.advanced(by: -self)
	}
}

extension Fractional: ExpressibleByIntegerLiteral {
	public init(integerLiteral value: Int) {
		self.init(value)
	}
}

extension Fractional: SignedNumeric {
	public init?<T>(exactly source: T) where T : BinaryInteger {
		self = .init(Int(source))
	}
	
	public var magnitude: Fractional {
		return Fractional(numerator: abs(numerator), denominator: abs(denominator))
	}
	
	public typealias Magnitude = Fractional
}

public prefix func -(value: Fractional) -> Fractional {
	return Fractional(numerator: -1 * value.numerator, denominator: value.denominator)
}

extension Fractional {
	/// The reciprocal of the fraction.
	public var reciprocal: Fractional {
		get {
			return Fractional(numerator: denominator, denominator: numerator)
		}
	}
	
	/// `true` iff `self` is neither infinite nor NaN
	public var isFinite: Bool {
		return denominator != 0 
	}
	
	/// `true` iff the numerator is zero and the denominator is nonzero 
	public var isInfinite: Bool {
		return denominator == 0 && numerator != 0
	}
	
	/// `true` iff both the numerator and the denominator are zero
	public var isNaN: Bool {
		return denominator == 0 && numerator == 0
	}
	
	/// The positive infinity.
	public static var infinity: Fractional {
		return 1 / 0
	}
	
	/// Not a number.
	public static var NaN: Fractional {
		return 0 / 0
	}
}

extension Fractional: CustomStringConvertible {
	public var description: String {
		guard !isNaN else { return "NaN" }
		guard !isInfinite else { return (self >= 0 ? "+" : "-") + "Inf" }
		
		switch denominator {
		case 1: return "\(numerator)"
		default: return "\(numerator)/\(denominator)"
		}
	}
}
	
/// Add `lhs` and `rhs`, returning a reduced result.
public func +(lhs: Fractional, rhs: Fractional) -> Fractional {
	guard !lhs.isNaN && !rhs.isNaN else { return .NaN }
	guard lhs.isFinite && rhs.isFinite else {
		switch (lhs >= 0, rhs >= 0) {
		case (false, false): return -.infinity
		case (true, true):   return .infinity
		default:			 return .NaN
		}
	}
	return lhs.advanced(by: rhs)
}
public func +=(lhs: inout Fractional, rhs: Fractional) {
    lhs = lhs + rhs
}

/// Subtract `lhs` and `rhs`, returning a reduced result.
public func -(lhs: Fractional, rhs: Fractional) -> Fractional {
	return lhs + -rhs
}
public func -=(lhs: inout Fractional, rhs: Fractional) {
    lhs = lhs - rhs
}

/// Multiply `lhs` and `rhs`, returning a reduced result.
public func *(lhs: Fractional, rhs: Fractional) -> Fractional {
	let swapped = (Fractional(numerator: lhs.numerator, denominator: rhs.denominator), Fractional(numerator: rhs.numerator, denominator: lhs.denominator))
	return Fractional(numerator: swapped.0.numerator * swapped.1.numerator, denominator: swapped.0.denominator * swapped.1.denominator)
}
public func *=(lhs: inout Fractional, rhs: Fractional) {
    lhs = lhs * rhs
}

/// Divide `lhs` and `rhs`, returning a reduced result.
public func /(lhs: Fractional, rhs: Fractional) -> Fractional {
	return lhs * rhs.reciprocal
}
public func /=(lhs: inout Fractional, rhs: Fractional) {
    lhs = lhs / rhs
}

extension Double {
	/// Create an instance initialized to `value`.
	init(_ value: Fractional) {
		self = (Double(value.numerator) / Double(value.denominator))
	}
}

extension Float {
	/// Create an instance initialized to `value`.
	init(_ value: Fractional) {
		self = (Float(value.numerator) / Float(value.denominator))
	}
}
