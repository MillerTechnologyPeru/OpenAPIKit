//
//  SchemaProtocols.swift
//  OpenAPI
//
//  Created by Mathew Polzin on 6/22/19.
//
//  "Schema" protocols allow different Swift types to
//  declare themselves able to represent themselves
//  as an Open API Schema Object.

import Foundation
import AnyCodable

/// Anything conforming to `OpenAPINodeType` can provide an
/// OpenAPI schema representing itself.
public protocol OpenAPISchemaType {
    static func openAPISchema() throws -> JSONSchema
}
