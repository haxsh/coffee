import Foundation

public struct BrewMethod: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let blurb: String
    public let symbolName: String
    /// The variables this method actually has.
    public let paramSchema: [ParamDef]
    /// Total brew time we expect. Outside this band is itself a diagnostic signal.
    public let expectedTotalSeconds: ClosedRange<Int>
    public let conceptIDs: [String]
    public let isLocked: Bool

    public init(
        id: String,
        name: String,
        blurb: String,
        symbolName: String,
        paramSchema: [ParamDef],
        expectedTotalSeconds: ClosedRange<Int>,
        conceptIDs: [String] = [],
        isLocked: Bool = false
    ) {
        self.id = id
        self.name = name
        self.blurb = blurb
        self.symbolName = symbolName
        self.paramSchema = paramSchema
        self.expectedTotalSeconds = expectedTotalSeconds
        self.conceptIDs = conceptIDs
        self.isLocked = isLocked
    }

    public func param(_ key: BrewParamKey) -> ParamDef? {
        paramSchema.first { $0.key == key }
    }

    public var defaultParameters: BrewParameters {
        var params = BrewParameters()
        for def in paramSchema { params[def.key] = def.defaultValue }
        return params
    }
}
