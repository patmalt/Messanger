import Foundation

protocol GenericPasswordConvertible: CustomStringConvertible {
    init<D>(rawRepresentation data: D) throws where D: ContiguousBytes
}
