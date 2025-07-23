import Charts
import SwiftUI
import Uncertain

struct ContentView: View {
    @State private var selection: Distribution = .normal
    @State private var sampleCount: Int = 1000

    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(Distribution.allCases, id: \.self, selection: $selection) {
                distribution in
                HStack {
                    Image(systemName: distribution.icon)
                        .foregroundColor(selection == distribution ? .white : distribution.color)
                        .frame(width: 16, alignment: .center)
                    Text(distribution.displayName)
                        .foregroundColor(selection == distribution ? .white : .primary)
                }
                .animation(.none, value: selection)
            }
            .navigationTitle("Distributions")
        } detail: {
            // Main content area
            DetailView(
                distribution: selection,
                sampleCount: sampleCount
            )
            .toolbar {
                ToolbarItem {
                    Picker("Sample Count", selection: $sampleCount) {
                        Text("100").tag(100)
                        Text("1K").tag(1000)
                        Text("10K").tag(10_000)
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

// MARK: -

struct DetailView: View {
    let distribution: Distribution
    let sampleCount: Int

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: distribution.icon)
                            .foregroundColor(distribution.color)
                            .font(.title2)
                        Text(distribution.displayName)
                            .font(.title)
                            .fontWeight(.bold)
                            .textSelection(.enabled)
                        Spacer()
                    }

                    Text(description(for: distribution))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)

                // Distribution-specific view
                Group {
                    switch distribution {
                    case .normal:
                        NormalDistributionView(sampleCount: sampleCount)
                    case .uniform:
                        UniformDistributionView(sampleCount: sampleCount)
                    case .exponential:
                        ExponentialDistributionView(sampleCount: sampleCount)
                    case .kumaraswamy:
                        KumaraswamyDistributionView(sampleCount: sampleCount)
                    case .bernoulli:
                        BernoulliDistributionView(sampleCount: sampleCount)
                    case .binomial:
                        BinomialDistributionView(sampleCount: sampleCount)
                    case .poisson:
                        PoissonDistributionView(sampleCount: sampleCount)
                    case .mixture:
                        MixtureDistributionView(sampleCount: sampleCount)
                    case .categorical:
                        CategoricalDistributionView(sampleCount: sampleCount)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(distribution.displayName)
    }

    private func description(for distribution: Distribution) -> String {
        switch distribution {
        case .normal:
            return
                "A bell-shaped continuous distribution defined by mean and standard deviation. Common in natural phenomena due to the Central Limit Theorem."
        case .uniform:
            return
                "All values in a given range are equally likely. Useful for modeling random choices within bounds."
        case .exponential:
            return
                "Models the time between events in a Poisson process. Commonly used for wait times and failure rates."
        case .kumaraswamy:
            return
                "A flexible distribution on [0,1] with two shape parameters. Alternative to Beta distribution with simpler sampling."
        case .bernoulli:
            return
                "Models a single yes/no trial with a given probability of success. Foundation for other discrete distributions."
        case .binomial:
            return
                "Models the number of successes in a fixed number of independent Bernoulli trials."
        case .poisson:
            return
                "Models the number of events occurring in a fixed interval, given a known average rate."
        case .mixture:
            return
                "Combines multiple distributions with specified weights. Useful for modeling multi-modal data."
        case .categorical:
            return
                "Models discrete outcomes with different probabilities. Like a weighted die with arbitrary labels."
        }
    }
}

// MARK: - Normal Distribution

struct NormalDistributionView: View {
    let sampleCount: Int
    @State private var mean: Double = 0.0
    @State private var stdDev: Double = 1.0
    @State private var samples: [Double] = []
    @State private var histogram: [HistogramBin] = []

    var body: some View {
        VStack(spacing: 16) {
            // Parameters
            ParameterControls {
                SliderControl(
                    label: "Mean (μ)",
                    value: $mean,
                    range: -5...5,
                    format: "%.1f"
                )
                SliderControl(
                    label: "Standard Deviation (σ)",
                    value: $stdDev,
                    range: 0.1...3.0,
                    format: "%.1f"
                )
            }

            // Chart
            Chart(histogram, id: \.midpoint) { bin in
                BarMark(
                    x: .value("Value", bin.midpoint),
                    y: .value("Frequency", bin.frequency)
                )
                .foregroundStyle(.blue.opacity(0.7))
            }
            .frame(height: 300)
            .chartXAxisLabel("Value")
            .chartYAxisLabel("Frequency")
            .chartXScale(domain: -10...10)
            .chartYScale(domain: 0...(sampleCount / 4))

            // Statistics
            StatisticsView(samples: samples)
        }
        .onAppear { updateSamples() }
        .onChange(of: mean) { updateSamples() }
        .onChange(of: stdDev) { updateSamples() }
        .onChange(of: sampleCount) { updateSamples() }
    }

    private func updateSamples() {
        let distribution = Uncertain.normal(mean: mean, standardDeviation: stdDev)
        samples = Array(distribution.prefix(sampleCount))
        histogram = createHistogram(from: samples, binCount: 30)
    }
}

// MARK: - Uniform Distribution

struct UniformDistributionView: View {
    let sampleCount: Int
    @State private var minValue: Double = 0.0
    @State private var maxValue: Double = 1.0
    @State private var samples: [Double] = []
    @State private var histogram: [HistogramBin] = []

    var body: some View {
        VStack(spacing: 16) {
            ParameterControls {
                SliderControl(
                    label: "Minimum",
                    value: Binding(
                        get: { minValue },
                        set: { newValue in
                            minValue = min(newValue, maxValue - 0.1)
                        }
                    ),
                    range: -5...5,
                    format: "%.1f"
                )
                SliderControl(
                    label: "Maximum",
                    value: Binding(
                        get: { maxValue },
                        set: { newValue in
                            maxValue = max(newValue, minValue + 0.1)
                        }
                    ),
                    range: -5...5,
                    format: "%.1f"
                )
            }

            Chart(histogram, id: \.midpoint) { bin in
                BarMark(
                    x: .value("Value", bin.midpoint),
                    y: .value("Frequency", bin.frequency)
                )
                .foregroundStyle(.green.opacity(0.7))
            }
            .frame(height: 300)
            .chartXAxisLabel("Value")
            .chartYAxisLabel("Frequency")
            .chartXScale(domain: minValue...maxValue)
            .chartYScale(domain: 0...(sampleCount / 10))

            StatisticsView(samples: samples)
        }
        .onAppear { updateSamples() }
        .onChange(of: minValue) { updateSamples() }
        .onChange(of: maxValue) { updateSamples() }
        .onChange(of: sampleCount) { updateSamples() }
    }

    private func updateSamples() {
        guard minValue < maxValue else { return }
        let distribution = Uncertain.uniform(min: minValue, max: maxValue)
        samples = Array(distribution.prefix(sampleCount))
        histogram = createHistogram(from: samples, binCount: 30)
    }
}

// MARK: - Exponential Distribution

struct ExponentialDistributionView: View {
    let sampleCount: Int
    @State private var rate: Double = 1.0
    @State private var samples: [Double] = []
    @State private var histogram: [HistogramBin] = []

    var body: some View {
        VStack(spacing: 16) {
            ParameterControls {
                SliderControl(
                    label: "Rate (λ)",
                    value: $rate,
                    range: 0.1...5.0,
                    format: "%.1f"
                )
                VStack(alignment: .leading, spacing: 4) {
                    Text("Mean: \(1.0/rate, specifier: "%.2f")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Chart(histogram, id: \.midpoint) { bin in
                BarMark(
                    x: .value("Value", bin.midpoint),
                    y: .value("Frequency", bin.frequency)
                )
                .foregroundStyle(.orange.opacity(0.7))
            }
            .frame(height: 300)
            .chartXAxisLabel("Value")
            .chartYAxisLabel("Frequency")
            .chartXScale(domain: 0...100)
            .chartYScale(domain: 0...(sampleCount / 4))

            StatisticsView(samples: samples)
        }
        .onAppear { updateSamples() }
        .onChange(of: rate) { updateSamples() }
        .onChange(of: sampleCount) { updateSamples() }
    }

    private func updateSamples() {
        let distribution = Uncertain.exponential(rate: rate)
        samples = Array(distribution.prefix(sampleCount))
        histogram = createHistogram(from: samples, binCount: 30)
    }
}

// MARK: - Kumaraswamy Distribution

struct KumaraswamyDistributionView: View {
    let sampleCount: Int
    @State private var alpha: Double = 2.0
    @State private var beta: Double = 5.0
    @State private var samples: [Double] = []
    @State private var histogram: [HistogramBin] = []

    var body: some View {
        VStack(spacing: 16) {
            ParameterControls {
                SliderControl(
                    label: "Shape α",
                    value: $alpha,
                    range: 0.5...5.0,
                    format: "%.1f"
                )
                SliderControl(
                    label: "Shape β",
                    value: $beta,
                    range: 0.5...10.0,
                    format: "%.1f"
                )
            }

            Chart(histogram, id: \.midpoint) { bin in
                BarMark(
                    x: .value("Value", bin.midpoint),
                    y: .value("Frequency", bin.frequency)
                )
                .foregroundStyle(.purple.opacity(0.7))
            }
            .frame(height: 300)
            .chartXAxisLabel("Value (0-1)")
            .chartYAxisLabel("Frequency")
            .chartXScale(domain: 0...1)
            .chartYScale(domain: 0...(sampleCount / 4))

            StatisticsView(samples: samples)
        }
        .onAppear { updateSamples() }
        .onChange(of: alpha) { updateSamples() }
        .onChange(of: beta) { updateSamples() }
        .onChange(of: sampleCount) { updateSamples() }
    }

    private func updateSamples() {
        let distribution = Uncertain.kumaraswamy(a: alpha, b: beta)
        samples = Array(distribution.prefix(sampleCount))
        histogram = createHistogram(from: samples, binCount: 30)
    }
}

// MARK: - Bernoulli Distribution

struct BernoulliDistributionView: View {
    let sampleCount: Int
    @State private var probability: Double = 0.5
    @State private var samples: [Bool] = []
    @State private var trueCount: Int = 0
    @State private var falseCount: Int = 0

    var body: some View {
        VStack(spacing: 16) {
            ParameterControls {
                SliderControl(
                    label: "Probability of Success",
                    value: $probability,
                    range: 0.0...1.0,
                    format: "%.2f"
                )
            }

            Chart {
                BarMark(
                    x: .value("Outcome", "False"),
                    y: .value("Count", falseCount)
                )
                .foregroundStyle(.red.opacity(0.7))

                BarMark(
                    x: .value("Outcome", "True"),
                    y: .value("Count", trueCount)
                )
                .foregroundStyle(.green.opacity(0.7))
            }
            .frame(height: 300)
            .chartXAxisLabel("Outcome")
            .chartYAxisLabel("Count")
            .chartYScale(domain: 0...sampleCount)

            VStack(alignment: .leading, spacing: 8) {
                Text("Statistics")
                    .font(.headline)

                HStack {
                    StatCard(title: "True Count", value: "\(trueCount)")
                    StatCard(title: "False Count", value: "\(falseCount)")
                    StatCard(
                        title: "Success Rate",
                        value: String(
                            format: "%.1f%%", Double(trueCount) / Double(samples.count) * 100))
                }
            }
        }
        .onAppear { updateSamples() }
        .onChange(of: probability) { updateSamples() }
        .onChange(of: sampleCount) { updateSamples() }
    }

    private func updateSamples() {
        let distribution = Uncertain.bernoulli(probability: probability)
        samples = Array(distribution.prefix(sampleCount))
        trueCount = samples.filter { $0 }.count
        falseCount = samples.count - trueCount
    }
}

// MARK: - Binomial Distribution

struct BinomialDistributionView: View {
    let sampleCount: Int
    @State private var trials: Int = 10
    @State private var probability: Double = 0.5
    @State private var samples: [Int] = []
    @State private var histogram: [DiscreteHistogramBin] = []

    var body: some View {
        VStack(spacing: 16) {
            ParameterControls {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Number of Trials: \(trials)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Slider(
                        value: Binding(
                            get: { Double(trials) },
                            set: { trials = Int($0) }
                        ), in: 1...50, step: 1)
                }

                SliderControl(
                    label: "Probability of Success",
                    value: $probability,
                    range: 0.0...1.0,
                    format: "%.2f"
                )
            }

            Chart(histogram, id: \.value) { bin in
                BarMark(
                    x: .value("Successes", bin.value),
                    y: .value("Frequency", bin.frequency)
                )
                .foregroundStyle(.cyan.opacity(0.7))
            }
            .frame(height: 300)
            .chartXAxisLabel("Number of Successes")
            .chartYAxisLabel("Frequency")
            .chartXScale(domain: 0...trials)
            .chartYScale(domain: 0...sampleCount)

            VStack(alignment: .leading, spacing: 8) {
                Text("Statistics")
                    .font(.headline)

                HStack {
                    StatCard(
                        title: "Mean", value: String(format: "%.1f", Double(trials) * probability))
                    StatCard(
                        title: "Std Dev",
                        value: String(
                            format: "%.1f", sqrt(Double(trials) * probability * (1 - probability))))
                    StatCard(
                        title: "Observed Mean",
                        value: String(
                            format: "%.1f",
                            samples.map(Double.init).reduce(0, +) / Double(samples.count)))
                }
            }
        }
        .onAppear { updateSamples() }
        .onChange(of: trials) { updateSamples() }
        .onChange(of: probability) { updateSamples() }
        .onChange(of: sampleCount) { updateSamples() }
    }

    private func updateSamples() {
        let distribution = Uncertain.binomial(trials: trials, probability: probability)
        samples = Array(distribution.prefix(sampleCount))
        histogram = createDiscreteHistogram(from: samples)
    }
}

// MARK: - Poisson Distribution

struct PoissonDistributionView: View {
    let sampleCount: Int
    @State private var lambda: Double = 3.0
    @State private var samples: [Int] = []
    @State private var histogram: [DiscreteHistogramBin] = []

    var body: some View {
        VStack(spacing: 16) {
            ParameterControls {
                SliderControl(
                    label: "Rate (λ)",
                    value: $lambda,
                    range: 0.5...10.0,
                    format: "%.1f"
                )
            }

            Chart(histogram, id: \.value) { bin in
                BarMark(
                    x: .value("Events", bin.value),
                    y: .value("Frequency", bin.frequency)
                )
                .foregroundStyle(.mint.opacity(0.7))
            }
            .frame(height: 300)
            .chartXAxisLabel("Number of Events")
            .chartYAxisLabel("Frequency")
            .chartXScale(domain: 0...Int(lambda + 4 * sqrt(lambda)))
            .chartYScale(domain: 0...sampleCount)
        }
        .onAppear { updateSamples() }
        .onChange(of: lambda) { updateSamples() }
        .onChange(of: sampleCount) { updateSamples() }
    }

    private func updateSamples() {
        let distribution = Uncertain<Int>.poisson(lambda: lambda)
        samples = Array(distribution.prefix(sampleCount))
        histogram = createDiscreteHistogram(from: samples)
    }
}

// MARK: - Mixture Distribution

struct MixtureDistributionView: View {
    let sampleCount: Int
    @State private var weight1: Double = 0.5
    @State private var mean1: Double = -1.0
    @State private var std1: Double = 0.5
    @State private var mean2: Double = 2.0
    @State private var std2: Double = 1.0
    @State private var samples: [Double] = []
    @State private var histogram: [HistogramBin] = []

    var body: some View {
        VStack(spacing: 16) {
            ParameterControls {
                Text("Mixture of Two Normal Distributions")
                    .font(.subheadline)
                    .fontWeight(.medium)

                SliderControl(
                    label: "Weight of First Component",
                    value: $weight1,
                    range: 0.0...1.0,
                    format: "%.2f"
                )

                Divider()

                HStack(spacing: 24) {
                    VStack {
                        Text("First Component")
                            .font(.caption)
                            .fontWeight(.medium)
                        SliderControl(
                            label: "Mean",
                            value: $mean1,
                            range: -3...3,
                            format: "%.1f"
                        )
                        SliderControl(
                            label: "Std Dev",
                            value: $std1,
                            range: 0.1...2.0,
                            format: "%.1f"
                        )
                    }

                    VStack {
                        Text("Second Component")
                            .font(.caption)
                            .fontWeight(.medium)
                        SliderControl(
                            label: "Mean",
                            value: $mean2,
                            range: -3...3,
                            format: "%.1f"
                        )
                        SliderControl(
                            label: "Std Dev",
                            value: $std2,
                            range: 0.1...2.0,
                            format: "%.1f"
                        )
                    }
                }
            }

            Chart(histogram, id: \.midpoint) { bin in
                BarMark(
                    x: .value("Value", bin.midpoint),
                    y: .value("Frequency", bin.frequency)
                )
                .foregroundStyle(.indigo.opacity(0.7))
            }
            .frame(height: 300)
            .chartXAxisLabel("Value")
            .chartYAxisLabel("Frequency")
            .chartXScale(domain: -10...10)
            .chartYScale(domain: 0...(sampleCount / 4))

            StatisticsView(samples: samples)
        }
        .onAppear { updateSamples() }
        .onChange(of: weight1) { updateSamples() }
        .onChange(of: mean1) { updateSamples() }
        .onChange(of: std1) { updateSamples() }
        .onChange(of: mean2) { updateSamples() }
        .onChange(of: std2) { updateSamples() }
        .onChange(of: sampleCount) { updateSamples() }
    }

    private func updateSamples() {
        let component1 = Uncertain.normal(mean: mean1, standardDeviation: std1)
        let component2 = Uncertain.normal(mean: mean2, standardDeviation: std2)

        let mixture = Uncertain.mixture(
            of: [component1, component2], weights: [weight1, 1.0 - weight1])

        samples = Array(mixture.prefix(sampleCount))
        histogram = createHistogram(from: samples, binCount: 30)
    }
}

// MARK: - Categorical Distribution

struct CategoricalDistributionView: View {
    let sampleCount: Int
    @State private var probA: Double = 0.3
    @State private var probB: Double = 0.4
    @State private var probC: Double = 0.3
    @State private var samples: [String] = []
    @State private var counts: [String: Int] = [:]

    var body: some View {
        VStack(spacing: 16) {
            ParameterControls {
                Text("Three Category Distribution")
                    .font(.subheadline)
                    .fontWeight(.medium)

                VStack(alignment: .leading, spacing: 4) {
                    Text("P(A): \(probA, specifier: "%.2f")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Slider(
                        value: Binding(
                            get: { probA },
                            set: { newValue in
                                let remaining = 1.0 - newValue
                                let currentOthers = probB + probC
                                if currentOthers > 0 {
                                    let scale = remaining / currentOthers
                                    probB *= scale
                                    probC *= scale
                                } else {
                                    probB = remaining / 2
                                    probC = remaining / 2
                                }
                                probA = newValue
                            }
                        ), in: 0.0...1.0)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("P(B): \(probB, specifier: "%.2f")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Slider(
                        value: Binding(
                            get: { probB },
                            set: { newValue in
                                let remaining = 1.0 - newValue
                                let currentOthers = probA + probC
                                if currentOthers > 0 {
                                    let scale = remaining / currentOthers
                                    probA *= scale
                                    probC *= scale
                                } else {
                                    probA = remaining / 2
                                    probC = remaining / 2
                                }
                                probB = newValue
                            }
                        ), in: 0.0...1.0)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("P(C): \(probC, specifier: "%.2f")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Slider(
                        value: Binding(
                            get: { probC },
                            set: { newValue in
                                let remaining = 1.0 - newValue
                                let currentOthers = probA + probB
                                if currentOthers > 0 {
                                    let scale = remaining / currentOthers
                                    probA *= scale
                                    probB *= scale
                                } else {
                                    probA = remaining / 2
                                    probB = remaining / 2
                                }
                                probC = newValue
                            }
                        ), in: 0.0...1.0)
                }
            }

            Chart {
                ForEach(["A", "B", "C"], id: \.self) { category in
                    BarMark(
                        x: .value("Category", category),
                        y: .value("Count", counts[category] ?? 0)
                    )
                    .foregroundStyle(colorForCategory(category))
                }
            }
            .frame(height: 300)
            .chartXAxisLabel("Category")
            .chartYAxisLabel("Count")
            .chartYScale(domain: 0...sampleCount)

            VStack(alignment: .leading, spacing: 8) {
                Text("Statistics")
                    .font(.headline)

                HStack {
                    ForEach(["A", "B", "C"], id: \.self) { category in
                        StatCard(
                            title: "Category \(category)",
                            value: "\(counts[category] ?? 0)"
                        )
                    }
                }
            }
        }
        .onAppear { updateSamples() }
        .onChange(of: probA) { updateSamples() }
        .onChange(of: probB) { updateSamples() }
        .onChange(of: probC) { updateSamples() }
        .onChange(of: sampleCount) { updateSamples() }
    }

    private func updateSamples() {
        let probs = [
            "A": probA,
            "B": probB,
            "C": probC,
        ]

        if let distribution = Uncertain.categorical(probs) {
            samples = Array(distribution.prefix(sampleCount))
            counts = Dictionary(grouping: samples, by: { $0 }).mapValues { $0.count }
        }
    }

    private func colorForCategory(_ category: String) -> Color {
        switch category {
        case "A": return .red.opacity(0.7)
        case "B": return .blue.opacity(0.7)
        case "C": return .green.opacity(0.7)
        default: return .gray.opacity(0.7)
        }
    }
}

// MARK: - Shared

struct ParameterControls<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Parameters")
                .font(.headline)

            content
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct SliderControl: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let format: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(label): \(value, specifier: format)")
                .font(.caption)
                .foregroundColor(.secondary)

            Slider(value: $value, in: range)
        }
    }
}

struct StatisticsView: View {
    let samples: [Double]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Statistics")
                .font(.headline)

            HStack {
                StatCard(title: "Mean", value: String(format: "%.3f", mean))
                StatCard(title: "Std Dev", value: String(format: "%.3f", standardDeviation))
                StatCard(title: "Min", value: String(format: "%.3f", samples.min() ?? 0))
                StatCard(title: "Max", value: String(format: "%.3f", samples.max() ?? 0))
            }
        }
    }

    private var mean: Double {
        samples.isEmpty ? 0 : samples.reduce(0, +) / Double(samples.count)
    }

    private var standardDeviation: Double {
        guard !samples.isEmpty else { return 0 }
        let m = mean
        let variance = samples.map { pow($0 - m, 2) }.reduce(0, +) / Double(samples.count)
        return sqrt(variance)
    }
}

struct StatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title3.monospacedDigit())
                .fontWeight(.medium)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(Color(NSColor.textBackgroundColor))
        .cornerRadius(8)
    }
}
