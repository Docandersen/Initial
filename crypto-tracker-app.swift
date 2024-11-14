// MARK: - Models
import Foundation
import SwiftUI
import Combine

// Data Models
struct CryptoData: Identifiable, Codable {
    let id: String
    let currentPrice: Double
    let priceChange24h: Double
    let tradingVolume: Double
    let marketCap: Double
    let historicalData: HistoricalData
    let marketSentiment: Double
    let trendAnalysis: TrendAnalysis
}

struct HistoricalData: Codable {
    let dailyClosingPrices: [Double]
    let volatility: [Double]
    let movingAverages: MovingAverages
}

struct MovingAverages: Codable {
    let ma50: Double
    let ma100: Double
    let ma200: Double
}

struct TrendAnalysis: Codable {
    let direction: TrendDirection
    let strength: Double
}

enum TrendDirection: String, Codable {
    case bullish, bearish, neutral
}

// MARK: - View Models
class CryptoTrackingViewModel: ObservableObject {
    @Published var cryptoData: CryptoData?
    @Published var isLoading = false
    @Published var error: Error?
    
    private var cancellables = Set<AnyCancellable>()
    private let dataService: CryptoDataService
    
    init(dataService: CryptoDataService = CryptoDataService()) {
        self.dataService = dataService
    }
    
    func fetchData() {
        isLoading = true
        
        dataService.fetchCryptoData()
            .receive(on: DispatchQueue.main)
            .sink { completion in
                self.isLoading = false
                if case .failure(let error) = completion {
                    self.error = error
                }
            } receiveValue: { data in
                self.cryptoData = data
            }
            .store(in: &cancellables)
    }
    
    func calculatePriceChangePercentage() -> Double {
        guard let data = cryptoData else { return 0 }
        let previousPrice = data.historicalData.dailyClosingPrices.first ?? data.currentPrice
        return (data.currentPrice - previousPrice) / previousPrice * 100
    }
    
    func calculateVolatilityIndex() -> Double {
        guard let data = cryptoData else { return 0 }
        let volatility = data.historicalData.volatility.first ?? 0
        return volatility / (data.currentPrice * data.tradingVolume)
    }
    
    func calculateOverallScore() -> Double {
        let pcp = calculatePriceChangePercentage() * 0.3
        let vi = calculateVolatilityIndex() * 0.2
        let ta = analyzeTrend() * 0.2
        let ms = (cryptoData?.marketSentiment ?? 0) * 0.15
        let pp = predictPrice() * 0.15
        
        return pcp + vi + ta + ms + pp
    }
    
    private func analyzeTrend() -> Double {
        guard let data = cryptoData else { return 0 }
        switch data.trendAnalysis.direction {
        case .bullish: return data.trendAnalysis.strength
        case .bearish: return -data.trendAnalysis.strength
        case .neutral: return 0
        }
    }
    
    private func predictPrice() -> Double {
        // Simplified prediction logic
        guard let data = cryptoData else { return 0 }
        let trend = analyzeTrend()
        let sentiment = data.marketSentiment
        return (trend + sentiment) / 2
    }
}

// MARK: - Views
struct ContentView: View {
    @StateObject private var viewModel = CryptoTrackingViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.opacity(0.05).edgesIgnoringSafeArea(.all)
                
                if viewModel.isLoading {
                    ProgressView()
                } else if let error = viewModel.error {
                    ErrorView(error: error)
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            PriceHeaderView(data: viewModel.cryptoData)
                            MetricsGridView(viewModel: viewModel)
                            ChartView(data: viewModel.cryptoData)
                            PredictionView(viewModel: viewModel)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("CryptoPriceTracker")
            .onAppear {
                viewModel.fetchData()
            }
            .refreshable {
                viewModel.fetchData()
            }
        }
    }
}

struct PriceHeaderView: View {
    let data: CryptoData?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Current Price")
                .font(.headline)
            
            if let data = data {
                HStack {
                    Text("$\(data.currentPrice, specifier: "%.2f")")
                        .font(.system(size: 32, weight: .bold))
                    
                    PriceChangeView(change: data.priceChange24h)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct MetricsGridView: View {
    @ObservedObject var viewModel: CryptoTrackingViewModel
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            MetricCard(title: "Price Change %", value: viewModel.calculatePriceChangePercentage(), format: "%.2f%%")
            MetricCard(title: "Volatility Index", value: viewModel.calculateVolatilityIndex(), format: "%.4f")
            MetricCard(title: "Market Cap", value: viewModel.cryptoData?.marketCap ?? 0, format: "$%.2fB")
            MetricCard(title: "Volume", value: viewModel.cryptoData?.tradingVolume ?? 0, format: "$%.2fM")
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: Double
    let format: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(String(format: format, value))
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct ChartView: View {
    let data: CryptoData?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Price History")
                .font(.headline)
            
            if let data = data {
                // Implement chart using Swift Charts or other charting library
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 200)
                    .overlay(
                        Text("Chart Placeholder")
                            .foregroundColor(.secondary)
                    )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct PredictionView: View {
    @ObservedObject var viewModel: CryptoTrackingViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Prediction & Analysis")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Overall Score")
                    Spacer()
                    Text(String(format: "%.2f", viewModel.calculateOverallScore()))
                        .font(.headline)
                }
                
                if let data = viewModel.cryptoData {
                    HStack {
                        Text("Trend")
                        Spacer()
                        Text(data.trendAnalysis.direction.rawValue.capitalized)
                            .foregroundColor(trendColor(for: data.trendAnalysis.direction))
                    }
                    
                    HStack {
                        Text("Market Sentiment")
                        Spacer()
                        Text(String(format: "%.2f", data.marketSentiment))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func trendColor(for direction: TrendDirection) -> Color {
        switch direction {
        case .bullish: return .green
        case .bearish: return .red
        case .neutral: return .orange
        }
    }
}

// MARK: - Services
class CryptoDataService {
    func fetchCryptoData() -> AnyPublisher<CryptoData, Error> {
        // Implement API calls to fetch data from various sources
        // This is a placeholder that returns sample data
        let sampleData = CryptoData(
            id: "bitcoin",
            currentPrice: 50000,
            priceChange24h: 1500,
            tradingVolume: 30000000000,
            marketCap: 950000000000,
            historicalData: HistoricalData(
                dailyClosingPrices: [49000, 48000, 47500],
                volatility: [0.02, 0.025, 0.03],
                movingAverages: MovingAverages(ma50: 45000, ma100: 42000, ma200: 40000)
            ),
            marketSentiment: 0.75,
            trendAnalysis: TrendAnalysis(direction: .bullish, strength: 0.8)
        )
        
        return Just(sampleData)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}

struct ErrorView: View {
    let error: Error
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            Text("Error")
                .font(.headline)
            
            Text(error.localizedDescription)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}
