import Accelerate

struct HistogramBin {
    let midpoint: Double
    let frequency: Int
}

struct DiscreteHistogramBin {
    let value: Int
    let frequency: Int
}

func createHistogram(from samples: [Double], binCount: Int) -> [HistogramBin] {
    guard !samples.isEmpty else { return [] }

    let minValue = vDSP.minimum(samples)
    let maxValue = vDSP.maximum(samples)
    let range = maxValue - minValue

    guard range > 0 else {
        return [HistogramBin(midpoint: minValue, frequency: samples.count)]
    }

    let binWidth = range / Double(binCount)

    // Use Accelerate for vectorized bin calculation
    var normalizedSamples = [Double](repeating: 0, count: samples.count)
    var scaledSamples = [Double](repeating: 0, count: samples.count)

    // Normalize samples: (sample - minValue) / binWidth
    vDSP.add(-minValue, samples, result: &normalizedSamples)
    vDSP.multiply(1.0 / binWidth, normalizedSamples, result: &scaledSamples)

    // Count frequencies
    var bins = Array(repeating: 0, count: binCount)
    for value in scaledSamples {
        let binIndex = min(max(Int(value), 0), binCount - 1)
        bins[binIndex] += 1
    }

    return bins.enumerated().map { index, frequency in
        let midpoint = minValue + (Double(index) + 0.5) * binWidth
        return HistogramBin(midpoint: midpoint, frequency: frequency)
    }
}

func createDiscreteHistogram(from samples: [Int]) -> [DiscreteHistogramBin] {
    let counts = Dictionary(grouping: samples, by: { $0 }).mapValues { $0.count }
    return counts.map { DiscreteHistogramBin(value: $0.key, frequency: $0.value) }
        .sorted { $0.value < $1.value }
}
