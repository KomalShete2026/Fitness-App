import CoreLocation
import Foundation
import WeatherKit

protocol WeatherDataService {
    func fetchCurrentWeather(at location: CLLocation) async throws -> (temperatureCelsius: Double, precipitationProbability: Double?)
    func fetchDailyPrecipitationForecast(at location: CLLocation, days: Int) async throws -> [(date: Date, precipitationProbability: Double)]
}

final class AppleWeatherService: WeatherDataService {
    private let service = WeatherKit.WeatherService.shared

    func fetchCurrentWeather(at location: CLLocation) async throws -> (temperatureCelsius: Double, precipitationProbability: Double?) {
        let weather = try await service.weather(for: location)
        let tempC = weather.currentWeather.temperature.converted(to: .celsius).value
        let precipitation = weather.hourlyForecast.forecast.first?.precipitationChance
        return (tempC, precipitation)
    }

    func fetchDailyPrecipitationForecast(at location: CLLocation, days: Int = 7) async throws -> [(date: Date, precipitationProbability: Double)] {
        let weather = try await service.weather(for: location)
        return weather.dailyForecast.forecast
            .prefix(max(days, 1))
            .map { day in
                (date: day.date, precipitationProbability: day.precipitationChance)
            }
    }
}
