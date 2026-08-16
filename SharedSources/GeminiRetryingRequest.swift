import Foundation

/// Retries a Gemini API request on HTTP 503 ("high demand"), which the API
/// returns regularly and independently of which model is called. Other
/// statuses and network errors pass through unchanged after the first try.
enum GeminiRetryingRequest {
    static func send(
        _ request: URLRequest,
        retriesRemaining: Int = 2,
        retryDelay: TimeInterval = 1.0,
        session: URLSession = .shared,
        completion: @escaping (Data?, URLResponse?, Error?) -> Void
    ) {
        session.dataTask(with: request) { data, response, error in
            if retriesRemaining > 0,
               let http = response as? HTTPURLResponse,
               http.statusCode == 503 {
                DispatchQueue.global().asyncAfter(deadline: .now() + retryDelay) {
                    send(
                        request,
                        retriesRemaining: retriesRemaining - 1,
                        retryDelay: retryDelay,
                        session: session,
                        completion: completion
                    )
                }
                return
            }
            completion(data, response, error)
        }.resume()
    }
}
