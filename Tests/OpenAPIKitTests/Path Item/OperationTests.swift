//
//  OperationTests.swift
//  
//
//  Created by Mathew Polzin on 12/29/19.
//

import XCTest
import OpenAPIKit
import Yams
import FineJSON

final class OperationTests: XCTestCase {
    func test_init() {
        // minimum
        let _ = OpenAPI.PathItem.Operation(
            responses: [:]
        )

        // all things
        let _ = OpenAPI.PathItem.Operation(
            tags: ["hello"],
            summary: "summary",
            description: "description",
            externalDocs: .init(url: URL(string: "https://google.com")!),
            operationId: "123",
            parameters: [.parameter(name: "hi", parameterLocation: .query, schema: .string)],
            requestBody: .init(content: [:]),
            responses: [:],
            deprecated: false,
            security: [],
            servers: []
        )

        // variadic tags
        let _ = OpenAPI.PathItem.Operation(
            tags: "hi", "hello",
            parameters: [],
            responses: [:]
        )
    }
}

// MARK: - Codable Tests
extension OperationTests {

    func test_minimal_encode() throws {
        let operation = OpenAPI.PathItem.Operation(
            responses: [:]
        )

        let encodedOperation = try testStringFromEncoding(of: operation)

        assertJSONEquivalent(
            encodedOperation,
"""
{
  "responses" : {

  }
}
"""
        )
    }

    func test_minimal_decode() throws {
        let operationData =
"""
{
  "responses" : {}
}
""".data(using: .utf8)!

        let operation = try testDecoder.decode(OpenAPI.PathItem.Operation.self, from: operationData)

        XCTAssertEqual(
            operation,
            OpenAPI.PathItem.Operation(responses: [:])
        )
    }

    func test_maximal_encode() throws {
        let operation = OpenAPI.PathItem.Operation(
            tags: ["hi", "hello"],
            summary: "summary",
            description: "description",
            externalDocs: .init(url: URL(string: "https://google.com")!),
            operationId: "123",
            parameters: [
                .parameter(reference: .internal(\.parameters, named: "hello"))
            ],
            requestBody: .init(content: [.json: .init(schema: .init(.string))]),
            responses: [200: .response(reference: .internal(\.responses, named: "test"))],
            deprecated: true,
            security: [[.internal(\.securitySchemes, named: "security"): []]],
            servers: [.init(url: URL(string: "https://google.com")!)]
        )

        let encodedOperation = try testStringFromEncoding(of: operation)

        assertJSONEquivalent(
            encodedOperation,
"""
{
  "deprecated" : true,
  "description" : "description",
  "externalDocs" : {
    "url" : "https:\\/\\/google.com"
  },
  "operationId" : "123",
  "parameters" : [
    {
      "$ref" : "#\\/components\\/parameters\\/hello"
    }
  ],
  "requestBody" : {
    "content" : {
      "application\\/json" : {
        "schema" : {
          "type" : "string"
        }
      }
    }
  },
  "responses" : {
    "200" : {
      "$ref" : "#\\/components\\/responses\\/test"
    }
  },
  "security" : [
    {
      "security" : [

      ]
    }
  ],
  "servers" : [
    {
      "url" : "https:\\/\\/google.com"
    }
  ],
  "summary" : "summary",
  "tags" : [
    "hi",
    "hello"
  ]
}
"""
        )
    }

    func test_maximal_decode() throws {
        let operationData =
"""
{
  "deprecated" : true,
  "description" : "description",
  "externalDocs" : {
    "url" : "https://google.com"
  },
  "operationId" : "123",
  "parameters" : [
    {
      "$ref" : "#/components/parameters/hello"
    }
  ],
  "requestBody" : {
    "content" : {
      "application\\/json" : {
        "schema" : {
          "type" : "string"
        }
      }
    }
  },
  "responses" : {
    "200" : {
      "$ref" : "#/components/responses/test"
    }
  },
  "security" : [
    {
      "security" : [

      ]
    }
  ],
  "servers" : [
    {
      "url" : "https://google.com"
    }
  ],
  "summary" : "summary",
  "tags" : [
    "hi",
    "hello"
  ]
}
""".data(using: .utf8)!

        let operation = try testDecoder.decode(OpenAPI.PathItem.Operation.self, from: operationData)

        XCTAssertEqual(
            operation,
            OpenAPI.PathItem.Operation(
                tags: ["hi", "hello"],
                summary: "summary",
                description: "description",
                externalDocs: .init(url: URL(string: "https://google.com")!),
                operationId: "123",
                parameters: [
                    .parameter(reference: .internal(.unsafe("#/components/parameters/hello")))
                ],
                requestBody: .init(content: [.json: .init(schema: .init(.string(required:false)))]),
                responses: [200: .response(reference: .internal(.unsafe("#/components/responses/test")))],
                deprecated: true,
                security: [[.internal(\.securitySchemes, named: "security"): []]],
                servers: [.init(url: URL(string: "https://google.com")!)]
            )
        )
    }

    // Note that JSONEncoder for Linux Foundation does not respect order
    func test_responseOrder_encode() throws {
        let operation = OpenAPI.PathItem.Operation(
            responses: [
                404: .response(reference: .internal(\.responses, named: "404")),
                200: .response(reference: .internal(\.responses, named: "200"))
            ]
        )

        let encodedOperation = String(
            data: try FineJSONEncoder().encode(operation),
            encoding: .utf8
        )!

        XCTAssertEqual(
            encodedOperation,
"""
{
  "responses": {
    "404": {
      "$ref": "#/components/responses/404"
    },
    "200": {
      "$ref": "#/components/responses/200"
    }
  }
}
"""
        )

        let operation2 = OpenAPI.PathItem.Operation(
            responses: [
                200: .response(reference: .internal(\.responses, named: "200")),
                404: .response(reference: .internal(\.responses, named: "404"))
            ]
        )

        let encodedOperation2 = String(
            data: try FineJSONEncoder().encode(operation2),
            encoding: .utf8
            )!

        XCTAssertEqual(
            encodedOperation2,
            """
{
  "responses": {
    "200": {
      "$ref": "#/components/responses/200"
    },
    "404": {
      "$ref": "#/components/responses/404"
    }
  }
}
"""
        )
    }

    // Note that JSONDecoder does not respect order
    func test_responseOrder_decode() throws {
        let operationString =
"""
responses:
  404:
    $ref: '#/components/responses/404'
  200:
    $ref: '#/components/responses/200'
"""

        let operation = try YAMLDecoder().decode(OpenAPI.PathItem.Operation.self, from: operationString)

        XCTAssertEqual(
            operation,
            OpenAPI.PathItem.Operation(
                responses: [
                    404: .response(reference: .internal(.unsafe("#/components/responses/404"))),
                    200: .response(reference: .internal(.unsafe("#/components/responses/200")))
                ]
            )
        )

        let operationString2 =
"""
responses:
  200:
    $ref: '#/components/responses/200'
  404:
    $ref: '#/components/responses/404'
"""

        let operation2 = try YAMLDecoder().decode(OpenAPI.PathItem.Operation.self, from: operationString2)

        XCTAssertEqual(
            operation2,
            OpenAPI.PathItem.Operation(
                responses: [
                    200: .response(reference: .internal(.unsafe("#/components/responses/200"))),
                    404: .response(reference: .internal(.unsafe("#/components/responses/404")))
                ]
            )
        )
    }
}
