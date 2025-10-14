import SwiftUI

extension FocusedValues {
    struct SelectedEntryKey: FocusedValueKey {
        typealias Value = Entry
    }

    var selectedEntry: Entry? {
        get { self[SelectedEntryKey.self] }
        set { self[SelectedEntryKey.self] = newValue }
    }
}