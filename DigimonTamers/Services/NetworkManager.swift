//
//  NetworkManager.swift
//  DigimonTamers
//
//  Created by Gabriel Bruno Meira on 28/07/25.
//

import Foundation
import UIKit

class NetworkManager {
    static let shared = NetworkManager()
    private let baseURL = "https://digi-api.com/api/v1"
    private let cache = NSCache<NSString, UIImage>()
    private let urlSession: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30 // Reduzir timeout para detectar problemas mais rápido
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        config.allowsCellularAccess = true
        config.allowsExpensiveNetworkAccess = true
        config.allowsConstrainedNetworkAccess = true
        
        // Melhorar cache e performance
        config.requestCachePolicy = .useProtocolCachePolicy
        config.urlCache = URLCache(memoryCapacity: 10 * 1024 * 1024, diskCapacity: 50 * 1024 * 1024, diskPath: nil)
        
        self.urlSession = URLSession(configuration: config)
    }
    
    // MARK: - Fetch Digimon List
    func fetchDigimonList(page: Int = 0, pageSize: Int = 20, completion: @escaping (Result<DigimonListResponse, Error>) -> Void) {
        let urlString = "\(baseURL)/digimon?page=\(page)&pageSize=\(pageSize)"
        print("🌐 Fetching URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL: \(urlString)")
            DispatchQueue.main.async {
                completion(.failure(NetworkError.invalidURL))
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 30 // Reduzir timeout
        request.cachePolicy = .useProtocolCachePolicy
        
        print("📡 Starting URLSession task...")
        
        urlSession.dataTask(with: request) { data, response, error in
            print("📡 URLSession task completed")
            
            if let error = error {
                print("❌ Network error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 HTTP Status: \(httpResponse.statusCode)")
                
                guard 200...299 ~= httpResponse.statusCode else {
                    print("❌ HTTP Error: \(httpResponse.statusCode)")
                    DispatchQueue.main.async {
                        completion(.failure(NetworkError.invalidResponse(httpResponse.statusCode)))
                    }
                    return
                }
            }
            
            guard let data = data else {
                print("❌ No data received")
                DispatchQueue.main.async {
                    completion(.failure(NetworkError.noData))
                }
                return
            }
            
            print("✅ Data received: \(data.count) bytes")
            
            // Log da resposta como string para debug
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 Response: \(jsonString.prefix(200))...")
            }
            
            do {
                let digimonList = try JSONDecoder().decode(DigimonListResponse.self, from: data)
                print("✅ Successfully decoded \(digimonList.content.count) digimons")
                DispatchQueue.main.async {
                    completion(.success(digimonList))
                }
            } catch {
                print("❌ Decoding error: \(error)")
                if let decodingError = error as? DecodingError {
                    print("❌ Detailed decoding error: \(decodingError)")
                }
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
        
        print("📡 URLSession task started")
    }
    
    // MARK: - Fetch Digimon Detail
    func fetchDigimonDetail(id: Int, completion: @escaping (Result<DigimonDetail, Error>) -> Void) {
        let urlString = "\(baseURL)/digimon/\(id)"
        
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                completion(.failure(NetworkError.invalidURL))
            }
            return
        }
        
        urlSession.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NetworkError.noData))
                }
                return
            }
            
            do {
                let digimonDetail = try JSONDecoder().decode(DigimonDetail.self, from: data)
                DispatchQueue.main.async {
                    completion(.success(digimonDetail))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    // MARK: - Search Digimon by Name
    func searchDigimonByName(_ name: String, completion: @escaping (Result<DigimonListResponse, Error>) -> Void) {
        let urlString = "\(baseURL)/digimon?name=\(name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        print("🔍 Searching URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ Invalid search URL: \(urlString)")
            DispatchQueue.main.async {
                completion(.failure(NetworkError.invalidURL))
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 30
        
        print("🔍 Starting search URLSession task...")
        
        urlSession.dataTask(with: request) { data, response, error in
            print("🔍 Search URLSession task completed")
            
            if let error = error {
                print("❌ Search network error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("🔍 Search HTTP Status: \(httpResponse.statusCode)")
                
                guard 200...299 ~= httpResponse.statusCode else {
                    print("❌ Search HTTP Error: \(httpResponse.statusCode)")
                    DispatchQueue.main.async {
                        completion(.failure(NetworkError.invalidResponse(httpResponse.statusCode)))
                    }
                    return
                }
            }
            
            guard let data = data else {
                print("❌ No search data received")
                DispatchQueue.main.async {
                    completion(.failure(NetworkError.noData))
                }
                return
            }
            
            print("✅ Search data received: \(data.count) bytes")
            
            do {
                let searchResults = try JSONDecoder().decode(DigimonListResponse.self, from: data)
                print("✅ Successfully decoded \(searchResults.content.count) search results")
                DispatchQueue.main.async {
                    completion(.success(searchResults))
                }
            } catch {
                print("❌ Search decoding error: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
        
        print("🔍 Search URLSession task started")
    }
    // MARK: - Download Image
    func downloadImage(from urlString: String, completion: @escaping (UIImage?) -> Void) {
        let cacheKey = NSString(string: urlString)
        
        // Check cache first
        if let cachedImage = cache.object(forKey: cacheKey) {
            DispatchQueue.main.async {
                completion(cachedImage)
            }
            return
        }
        
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                completion(nil)
            }
            return
        }
        
        urlSession.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                print("❌ Image download error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
                print("❌ Image download invalid response")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            guard let data = data, let image = UIImage(data: data) else {
                print("❌ Image data could not be processed")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            // Cache the image
            self?.cache.setObject(image, forKey: cacheKey)
            
            DispatchQueue.main.async {
                completion(image)
            }
        }.resume()
    }
}

// MARK: - Network Errors
enum NetworkError: Error {
    case invalidURL
    case noData
    case invalidResponse(Int)
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "URL inválida"
        case .noData:
            return "Nenhum dado recebido"
        case .invalidResponse(let statusCode):
            return "Resposta inválida do servidor (código: \(statusCode))"
        }
    }
}
