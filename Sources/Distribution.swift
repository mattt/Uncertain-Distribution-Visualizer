import SwiftUI

enum Distribution: String, CaseIterable {
    case normal
    case uniform
    case exponential
    case kumaraswamy
    case rayleigh
    case bernoulli
    case binomial
    case poisson
    case mixture
    case categorical

    var displayName: String {
        switch self {
        case .normal: return "Normal (Gaussian)"
        case .uniform: return "Uniform"
        case .exponential: return "Exponential"
        case .kumaraswamy: return "Kumaraswamy"
        case .rayleigh: return "Rayleigh"
        case .bernoulli: return "Bernoulli"
        case .binomial: return "Binomial"
        case .poisson: return "Poisson"
        case .mixture: return "Mixture"
        case .categorical: return "Categorical"
        }
    }

    var icon: String {
        switch self {
        case .normal: return "bell"
        case .uniform: return "square.bottomhalf.filled"
        case .exponential: return "function"
        case .kumaraswamy: return "waveform.path"
        case .rayleigh: return "scope"
        case .bernoulli: return "flag.filled.and.flag.crossed"
        case .binomial: return "chart.bar"
        case .poisson: return "burst"
        case .mixture: return "square.2.layers.3d"
        case .categorical: return "list.bullet"
        }
    }

    var color: Color {
        switch self {
        case .normal: return .blue
        case .uniform: return .green
        case .exponential: return .orange
        case .kumaraswamy: return .purple
        case .rayleigh: return .red
        case .bernoulli: return .brown
        case .binomial: return .cyan
        case .poisson: return .mint
        case .mixture: return .indigo
        case .categorical: return .blue
        }
    }
}
