//
//  LogicValue.swift
//  Logic
//
//  Created by Devin Abbott on 6/2/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

public struct LogicValue: CustomDebugStringConvertible {

    // MARK: Types

    public enum Function {
        case colorSaturate
        case colorSetHue
        case colorSetSaturation
        case colorSetLightness
        case colorFromHSL
        case numberRange
        case arrayAt
        case stringConcat
        case enumInit(caseName: String)
        case recordInit(members: [String: (Unification.T, LogicValue?)])
        case impl(declarationID: UUID)
        case value(LogicValue)

        init?(qualifiedName: [String]) {
            switch qualifiedName {
            case ["Color", "saturate"]:
                self = .colorSaturate
            case ["Color", "setHue"]:
                self = .colorSetHue
            case ["Color", "setSaturation"]:
                self = .colorSetSaturation
            case ["Color", "setLightness"]:
                self = .colorSetLightness
            case ["Color", "fromHSL"]:
                self = .colorFromHSL
            case ["Number", "range"]:
                self = .numberRange
            case ["Array", "at"]:
                self = .arrayAt
            case ["String", "concat"]:
                self = .stringConcat
            default:
                return nil
            }
        }

        init(declarationID: UUID) {
            self = .impl(declarationID: declarationID)
        }

        init(value: LogicValue) {
            self = .value(value)
        }
    }

    public indirect enum Memory: CustomDebugStringConvertible {
        case unit
        case bool(Bool)
        case number(CGFloat)
        case string(String)
        case array([LogicValue])
        case `enum`(caseName: String, associatedValues: [LogicValue])
        case record(values: [String: LogicValue?])
        case function(Function)

        public var debugDescription: String {
            switch self {
            case .unit:
                return "unit"
            case .bool(let value):
                return "\(value)"
            case .number(let value):
                return "\(value)"
            case .string(let value):
                return "\"\(value)\""
            case .array(let values):
                return "[\(values.map { $0.debugDescription }.joined(separator: ", "))]"
            case .enum(let caseName, let values):
                return ".\(caseName)(\(values.map { "\($0)" }.joined(separator: ", ")))"
            case .record(let values):
                return "\(values)"
            case .function(let function):
                return "\(function)"
            }
        }
    }

    // MARK: Lifecycle

    public init(_ type: Unification.T, _ memory: Memory) {
        self.type = type
        self.memory = memory
    }

    // MARK: Public

    public let type: Unification.T
    public let memory: Memory

    public var debugDescription: String {
        return "\(memory)"
    }
}
