# ATMOS — Weather App

## Overview
ATMOS is a native iOS weather application developed with Swift and SwiftUI. It lets users search for locations, view weather forecasts, inspect daily details, manage favourites and configure preferences.

## Project structure
```text
WeatherLabB2/
  Models/WeatherModels.swift
  Repositories/WeatherRepository.swift
  Services/GeocodingService.swift, NetworkMonitor.swift, SMHIService.swift
  ViewModels/FavoritesViewModel.swift, ForecastViewModel.swift, SearchViewModel.swift
  Views/ForecastDetailView.swift, ForecastView.swift, SearchView.swift, SettingsView.swift
  Assets/
  ContentView.swift
  WeatherLabB2App.swift
WeatherLabB2Tests/WeatherLabB2Tests.swift
WeatherLabB2UITests/WeatherLabB2UITests.swift
```

## File responsibilities
- WeatherLabB2App.swift: App entry point and main SwiftUI scene.
- ContentView.swift: Root content and navigation composition.
- WeatherModels.swift: Location and forecast data structures.
- WeatherRepository.swift: Coordinates service calls, data access and forecast cache.
- SMHIService.swift: Requests and decodes weather forecast data from SMHI.
- GeocodingService.swift: Resolves place names to geographic coordinates.
- NetworkMonitor.swift: Monitors network connectivity.
- SearchViewModel.swift: Manages search input, results and search state.
- ForecastViewModel.swift: Manages forecast, loading, errors and refresh state.
- FavoritesViewModel.swift: Manages saved favourite locations.
- SearchView.swift: Presents location search and navigation.
- ForecastView.swift: Presents hourly and daily forecast information.
- ForecastDetailView.swift: Presents details for a selected day.
- SettingsView.swift: Presents user preferences.
- WeatherLabB2Tests.swift: Unit tests for JSON/models and selected validation/error cases.
- WeatherLabB2UITests.swift: UI automation and launch/performance tests.

## Architecture and communication
ATMOS uses an MVVM-style presentation structure with separate repository, service and model layers.

**View → ViewModel → Repository → Service/API → Model → ViewModel state → View**

Views display information and collect input. ViewModels manage screen state and coordinate user actions. The repository coordinates data access, service calls and local persistence. Services communicate with external APIs. Responses are decoded into models, and the ViewModel publishes updated state so SwiftUI refreshes the interface.

A search starts in SearchView and is handled by SearchViewModel. The repository and GeocodingService resolve the place name to coordinates. ForecastViewModel then requests weather data through WeatherRepository and SMHIService. The decoded forecast models are published to the view.

This separation keeps network code out of the views, makes responsibilities clearer and supports testing. Codable models handle structured JSON, asynchronous requests help keep the interface responsive, and cached forecast data can remain available offline.

## Testing
The recorded Xcode run on 15 November 2026 showed 7 unit tests and 2 UI tests passing, with 0 failures. See TEST_REPORT.md for details.
