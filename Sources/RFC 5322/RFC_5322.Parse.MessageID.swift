//
//  RFC_5322.Parse.MessageID.swift
//  swift-rfc-5322
//
//  RFC 5322 msg-id: "<" id-left "@" id-right ">"
//

public import Parser_Primitives

extension RFC_5322.Parse {
    /// Parses an RFC 5322 message-id per Section 3.6.4.
    ///
    /// `msg-id = "<" id-left "@" id-right ">"`
    ///
    /// Returns the left and right parts of the message ID.
    public struct MessageID<Input: Collection.Slice.`Protocol`>: Sendable
    where Input: Sendable, Input.Element == UInt8 {
        @inlinable
        public init() {}
    }
}

extension RFC_5322.Parse.MessageID {
    public struct Output: Sendable {
        public let left: Input
        public let right: Input

        @inlinable
        public init(left: Input, right: Input) {
            self.left = left
            self.right = right
        }
    }

    public enum Error: Swift.Error, Sendable, Equatable {
        case expectedOpenAngle
        case expectedAtSign
        case expectedCloseAngle
    }
}

extension RFC_5322.Parse.MessageID: Parser.`Protocol` {
    public typealias ParseOutput = Output
    public typealias Failure = RFC_5322.Parse.MessageID<Input>.Error

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Output {
        // Expect '<'
        guard input.startIndex < input.endIndex,
            input[input.startIndex] == 0x3C
        else {
            throw .expectedOpenAngle
        }
        input = input[input.index(after: input.startIndex)...]

        // Consume id-left (until '@')
        let leftStart = input.startIndex
        while input.startIndex < input.endIndex && input[input.startIndex] != 0x40 {
            input = input[input.index(after: input.startIndex)...]
        }
        guard input.startIndex < input.endIndex else { throw .expectedAtSign }
        let left = input[leftStart..<input.startIndex]

        // Skip '@'
        input = input[input.index(after: input.startIndex)...]

        // Consume id-right (until '>')
        let rightStart = input.startIndex
        while input.startIndex < input.endIndex && input[input.startIndex] != 0x3E {
            input = input[input.index(after: input.startIndex)...]
        }
        guard input.startIndex < input.endIndex else { throw .expectedCloseAngle }
        let right = input[rightStart..<input.startIndex]

        // Skip '>'
        input = input[input.index(after: input.startIndex)...]

        return Output(left: left, right: right)
    }
}
