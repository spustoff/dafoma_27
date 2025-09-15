//
//  Aks.swift
//  dafoma_27
//
//  Created by Вячеслав on 9/15/25.
//


import SwiftUI

class InstallReporter {
    
    static func send() {
        
        // ПОМЕНЯТЬ!!!!!! // ПОМЕНЯТЬ!!!!!!// ПОМЕНЯТЬ!!!!!!// ПОМЕНЯТЬ!!!!!!
        
        let APP_ID: String = "6751489622"
        
        // ПОМЕНЯТЬ!!!!!! // ПОМЕНЯТЬ!!!!!!// ПОМЕНЯТЬ!!!!!!// ПОМЕНЯТЬ!!!!!!
        
        guard let url = URL(string: "https://appstoreautomation.site/install") else { return }
        
        // Данные устройства
        let idfv = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        let model = UIDevice.current.model
        let osName = UIDevice.current.systemName
        let osVersion = UIDevice.current.systemVersion
        
        // JSON тело
        let body: [String: Any] = [
            "app_id": APP_ID,
            "device": [
                "idfv": idfv,
                "model": model,
                "os_name": osName,
                "os_version": osVersion
            ]
        ]
        
        // Преобразуем в JSON
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        // Запуск запроса
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Ошибка запроса: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP статус: \(httpResponse.statusCode)")
            }
            
            if let data = data,
               let responseString = String(data: data, encoding: .utf8) {
                print("Ответ сервера: \(responseString)")
            }
        }.resume()
    }
}
