//
//  SwiftNativeTypes.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 2/18/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit

protocol LogicTextEditable {
//    var uuid: SwiftUUID { get }
//    var textElements: [LogicEditorText] { get }
//    func find(id: SwiftUUID) -> SwiftSyntaxNode?
//    func replace(id: SwiftUUID, with syntaxNode: SwiftSyntaxNode) -> Self
//    static var suggestionCategories: [LogicSuggestionCategory] { get }
}

extension SwiftIdentifier: LogicTextEditable {
    func replace(id: SwiftUUID, with syntaxNode: SwiftSyntaxNode) -> SwiftIdentifier {
        switch syntaxNode {
        case .identifier(let newNode) where id == uuid:
            return SwiftIdentifier(id: NSUUID().uuidString, string: newNode.string)
        default:
            return self
        }
    }

    func find(id: SwiftUUID) -> SwiftSyntaxNode? {
        return id == uuid ? SwiftSyntaxNode.identifier(self) : nil
    }

    var uuid: SwiftUUID { return id }
}

extension SwiftStatement: LogicTextEditable {
    func replace(id: SwiftUUID, with syntaxNode: SwiftSyntaxNode) -> SwiftStatement {
        switch syntaxNode {
        case .statement(let newNode) where id == uuid:
            return newNode
        default:
            switch self {
            case .branch(let branch):
                return .branch(SwiftBranch(
                    id: NSUUID().uuidString,
                    condition: branch.condition.replace(id: id, with: syntaxNode),
                    block: SwiftList<SwiftStatement>.empty))
            case .decl(let decl):
                return self
            case .loop(let loop):
                return SwiftStatement.loop(
                    SwiftLoop(
                        pattern: loop.pattern.replace(id: id, with: syntaxNode),
                        expression: loop.expression.replace(id: id, with: syntaxNode),
                        block: SwiftList<SwiftStatement>.empty,
                        id: NSUUID().uuidString))
            case .expressionStatement(_):
                return self
            }
        }
    }

    func find(id: SwiftUUID) -> SwiftSyntaxNode? {
        if id == uuid {
            return SwiftSyntaxNode.statement(self)
        }

        switch self {
        case .branch(let branch):
            return branch.condition.find(id: id)
        case .decl(let decl):
            return nil
        case .loop(let loop):
            return loop.expression.find(id: id) ?? loop.pattern.find(id: id)
        case .expressionStatement(let expr):
            return nil
        }
    }

    var uuid: SwiftUUID {
        switch self {
        case .branch(let branch):
            return branch.id
        case .decl(let decl):
            return decl.id
        case .loop(let loop):
            return loop.id
        case .expressionStatement(let expr):
            return expr.id
        }
    }
}

extension SwiftSyntaxNode {
    func replace(id: SwiftUUID, with syntaxNode: SwiftSyntaxNode) -> SwiftSyntaxNode {
        switch self {
        case .statement(let statement):
            return .statement(statement.replace(id: id, with: syntaxNode))
        case .declaration(let declaration):
            return self
        case .identifier(let identifier):
            return .identifier(identifier.replace(id: id, with: syntaxNode))
        }
    }

    func find(id: SwiftUUID) -> SwiftSyntaxNode? {
        switch self {
        case .statement(let statement):
            return statement.find(id: id)
        case .declaration(let declaration):
            return nil
        case .identifier(let identifier):
            return identifier.find(id: id)
        }
    }
}
