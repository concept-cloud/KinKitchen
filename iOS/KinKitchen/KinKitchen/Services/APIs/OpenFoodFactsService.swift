//
//  OpenFoodFactsService.swift
//  KinKitchen
//
//  Created by Greg Hudler on 9/9/26.
//

import Foundation

// MARK: - Open Food Facts Service

enum OpenFoodFactsService {

    private static let baseURL =
        "https://world.openfoodfacts.org"

    private static let userAgent =
        "KinKitchen/1.0"

    // MARK: - Barcode Lookup

    static func lookupBarcode(
        _ barcode: String
    ) async throws -> OpenFoodFactsResult {

        let cleanBarcode =
            barcode.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !cleanBarcode.isEmpty else {
            throw OpenFoodFactsError.invalidQuery
        }

        guard let encodedBarcode =
            cleanBarcode.addingPercentEncoding(
                withAllowedCharacters: .urlPathAllowed
            )
        else {
            throw OpenFoodFactsError.invalidQuery
        }

        let fields = [
            "code",
            "product_name",
            "generic_name",
            "brands",
            "allergens",
            "allergens_tags",
            "traces",
            "traces_tags",
            "ingredients_text"
        ]
        .joined(separator: ",")

        guard let url = URL(
            string:
                "\(baseURL)/api/v2/product/\(encodedBarcode).json?fields=\(fields)"
        ) else {
            throw OpenFoodFactsError.invalidURL
        }

        let response: OpenFoodFactsProductResponse =
            try await performRequest(
                url: url,
                responseType:
                    OpenFoodFactsProductResponse.self
            )

        guard response.status == 1,
              let product = response.product
        else {
            return OpenFoodFactsResult(
                productName: nil,
                barcode: cleanBarcode,
                brand: nil,
                allergens: [],
                traces: [],
                ingredientsText: nil,
                dataState: .unknown
            )
        }

        return makeResult(
            from: product
        )
    }

    // MARK: - Product Search

    static func searchProduct(
        _ query: String,
        limit: Int = 10
    ) async throws -> [OpenFoodFactsResult] {

        let cleanQuery =
            query.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !cleanQuery.isEmpty else {
            throw OpenFoodFactsError.invalidQuery
        }

        var components =
            URLComponents(
                string:
                    "\(baseURL)/cgi/search.pl"
            )

        components?.queryItems = [
            URLQueryItem(
                name: "action",
                value: "process"
            ),
            URLQueryItem(
                name: "search_terms",
                value: cleanQuery
            ),
            URLQueryItem(
                name: "search_simple",
                value: "1"
            ),
            URLQueryItem(
                name: "json",
                value: "1"
            ),
            URLQueryItem(
                name: "page_size",
                value: "\(max(1, min(limit, 20)))"
            ),
            URLQueryItem(
                name: "fields",
                value: [
                    "code",
                    "product_name",
                    "generic_name",
                    "brands",
                    "allergens",
                    "allergens_tags",
                    "traces",
                    "traces_tags",
                    "ingredients_text"
                ]
                .joined(separator: ",")
            )
        ]

        guard let url = components?.url else {
            throw OpenFoodFactsError.invalidURL
        }

        let response: OpenFoodFactsSearchResponse =
            try await performRequest(
                url: url,
                responseType:
                    OpenFoodFactsSearchResponse.self
            )

        return response.products.map {
            makeResult(
                from: $0
            )
        }
    }

    // MARK: - Request

    private static func performRequest<T: Decodable>(
        url: URL,
        responseType: T.Type
    ) async throws -> T {

        var request =
            URLRequest(
                url: url
            )

        request.httpMethod = "GET"

        request.setValue(
            userAgent,
            forHTTPHeaderField: "User-Agent"
        )

        request.setValue(
            "application/json",
            forHTTPHeaderField: "Accept"
        )

        let data: Data
        let response: URLResponse

        do {
            (data, response) =
                try await URLSession.shared.data(
                    for: request
                )
        } catch {
            throw OpenFoodFactsError.networkFailure(
                error
            )
        }

        guard let httpResponse =
            response as? HTTPURLResponse
        else {
            throw OpenFoodFactsError.invalidResponse
        }

        guard (200...299).contains(
            httpResponse.statusCode
        ) else {
            throw OpenFoodFactsError.httpError(
                statusCode:
                    httpResponse.statusCode
            )
        }

        do {
            return try JSONDecoder().decode(
                responseType,
                from: data
            )
        } catch {
            throw OpenFoodFactsError.decodingFailure(
                error
            )
        }
    }

    // MARK: - Normalize Product

    private static func makeResult(
        from product: OpenFoodFactsProduct
    ) -> OpenFoodFactsResult {

        let allergens =
            normalizedTags(
                product.allergensTags
            )

        let traces =
            normalizedTags(
                product.tracesTags
            )

        let hasAllergenField =
            product.allergens != nil ||
            product.allergensTags != nil

        let hasTraceField =
            product.traces != nil ||
            product.tracesTags != nil

        let dataState: OpenFoodFactsDataState

        if hasAllergenField ||
            hasTraceField {

            if !allergens.isEmpty ||
                !traces.isEmpty {

                dataState = .available

            } else {

                dataState = .incomplete
            }

        } else {

            dataState = .unknown
        }

        return OpenFoodFactsResult(
            productName:
                cleaned(
                    product.productName
                )
                ?? cleaned(
                    product.genericName
                ),
            barcode:
                cleaned(
                    product.code
                ),
            brand:
                cleaned(
                    product.brands
                ),
            allergens:
                allergens,
            traces:
                traces,
            ingredientsText:
                cleaned(
                    product.ingredientsText
                ),
            dataState:
                dataState
        )
    }

    // MARK: - Normalize Tags

    private static func normalizedTags(
        _ tags: [String]?
    ) -> [String] {

        guard let tags else {
            return []
        }

        return Array(
            Set(
                tags.compactMap {
                    normalizedTag(
                        $0
                    )
                }
            )
        )
        .sorted()
    }

    private static func normalizedTag(
        _ value: String
    ) -> String? {

        var cleanedValue =
            value.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !cleanedValue.isEmpty else {
            return nil
        }

        if let colonIndex =
            cleanedValue.firstIndex(
                of: ":"
            ) {

            cleanedValue =
                String(
                    cleanedValue[
                        cleanedValue.index(
                            after: colonIndex
                        )...
                    ]
                )
        }

        cleanedValue =
            cleanedValue
                .replacingOccurrences(
                    of: "-",
                    with: " "
                )
                .replacingOccurrences(
                    of: "_",
                    with: " "
                )
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        guard !cleanedValue.isEmpty else {
            return nil
        }

        return cleanedValue
    }

    // MARK: - String Cleanup

    private static func cleaned(
        _ value: String?
    ) -> String? {

        guard let value else {
            return nil
        }

        let cleanValue =
            value.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return cleanValue.isEmpty
            ? nil
            : cleanValue
    }
}


// MARK: - Public Result

struct OpenFoodFactsResult:
    Identifiable,
    Hashable {

    let id = UUID()

    let productName: String?
    let barcode: String?
    let brand: String?

    let allergens: [String]
    let traces: [String]

    let ingredientsText: String?

    let dataState:
        OpenFoodFactsDataState

    var hasAllergenInformation: Bool {
        dataState == .available
    }

    var hasIncompleteInformation: Bool {
        dataState == .incomplete
    }

    var isUnknown: Bool {
        dataState == .unknown
    }
}


// MARK: - Data State

enum OpenFoodFactsDataState:
    String,
    Codable,
    Hashable {

    case available
    case incomplete
    case unknown
}


// MARK: - Service Errors

enum OpenFoodFactsError:
    LocalizedError {

    case invalidQuery
    case invalidURL
    case invalidResponse

    case networkFailure(
        Error
    )

    case httpError(
        statusCode: Int
    )

    case decodingFailure(
        Error
    )

    var errorDescription: String? {

        switch self {

        case .invalidQuery:

            return
                "The Open Food Facts search request was empty or invalid."

        case .invalidURL:

            return
                "Kin Kitchen could not create the Open Food Facts request."

        case .invalidResponse:

            return
                "Open Food Facts returned an invalid response."

        case .networkFailure:

            return
                "Kin Kitchen could not connect to Open Food Facts."

        case .httpError(
            let statusCode
        ):

            return
                "Open Food Facts returned HTTP status \(statusCode)."

        case .decodingFailure:

            return
                "Kin Kitchen could not understand the Open Food Facts response."
        }
    }
}


// MARK: - API Product Response

private struct OpenFoodFactsProductResponse:
    Decodable {

    let status: Int?
    let statusVerbose: String?
    let product: OpenFoodFactsProduct?

    enum CodingKeys:
        String,
        CodingKey {

        case status

        case statusVerbose =
            "status_verbose"

        case product
    }
}


// MARK: - API Search Response

private struct OpenFoodFactsSearchResponse:
    Decodable {

    let count: Int?
    let page: Int?
    let pageSize: Int?
    let products:
        [OpenFoodFactsProduct]

    enum CodingKeys:
        String,
        CodingKey {

        case count
        case page

        case pageSize =
            "page_size"

        case products
    }
}


// MARK: - API Product

private struct OpenFoodFactsProduct:
    Decodable {

    let code: String?

    let productName: String?
    let genericName: String?
    let brands: String?

    let allergens: String?
    let allergensTags: [String]?

    let traces: String?
    let tracesTags: [String]?

    let ingredientsText: String?

    enum CodingKeys:
        String,
        CodingKey {

        case code

        case productName =
            "product_name"

        case genericName =
            "generic_name"

        case brands

        case allergens

        case allergensTags =
            "allergens_tags"

        case traces

        case tracesTags =
            "traces_tags"

        case ingredientsText =
            "ingredients_text"
    }
}
