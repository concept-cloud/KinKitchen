//
//  KinMeasureKeyboard.swift
//  KinKitchen
//
//  Created by Greg Hudler on 10/14/26.
//

import SwiftUI
import UIKit

// MARK: - Measure Fields

/// Quantity and unit for one ingredient, each with its own keyboard:
/// a number pad with kitchen fractions for the amount, and a pad of
/// common units (cup, Tbsp, tsp, lb…) for the unit.
///
/// Next on the amount moves to the unit; picking a unit calls
/// `onFinished` so the screen can move on to the ingredient name.
struct KinMeasureFields: View {

    @Binding var quantity: String
    @Binding var unit: String
    var quantityWidth: CGFloat = 65
    var unitWidth: CGFloat = 75
    var onFinished: () -> Void = {}

    @State private var isQuantityActive = false
    @State private var isUnitActive = false

    var body: some View {

        HStack(spacing: KinSpacing.small) {

            KinKeyboardTextField(
                placeholder: "Qty",
                text: $quantity,
                keyboard: .quantity,
                isActive: $isQuantityActive,
                onNext: {
                    isUnitActive = true
                }
            )
            .frame(width: quantityWidth, height: 44)
            .accessibilityLabel("Quantity")

            KinKeyboardTextField(
                placeholder: "Unit",
                text: $unit,
                keyboard: .unit,
                isActive: $isUnitActive,
                onNext: onFinished
            )
            .frame(width: unitWidth, height: 44)
            .accessibilityLabel("Unit")
        }
    }
}


// MARK: - Text Field

/// A text field that shows one of the Kin Kitchen measure keyboards
/// instead of the system keyboard.
struct KinKeyboardTextField: UIViewRepresentable {

    enum Keyboard {
        case quantity
        case unit
    }

    let placeholder: String
    @Binding var text: String
    let keyboard: Keyboard
    @Binding var isActive: Bool
    var onNext: () -> Void = {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(
        context: Context
    ) -> UITextField {

        let field = UITextField()
        field.placeholder = placeholder
        field.text = text
        field.font =
            UIFontMetrics(forTextStyle: .body)
                .scaledFont(
                    for: UIFont(name: "Lora-Regular", size: 17)
                        ?? .preferredFont(forTextStyle: .body)
                )
        field.adjustsFontForContentSizeCategory = true
        field.textColor = UIColor(KinColors.primaryText)
        field.tintColor = UIColor(KinColors.primary)
        field.autocorrectionType = .no
        field.spellCheckingType = .no
        field.autocapitalizationType = .none
        field.delegate = context.coordinator
        field.addTarget(
            context.coordinator,
            action: #selector(Coordinator.textChanged(_:)),
            for: .editingChanged
        )

        // Let SwiftUI's frame decide the width.
        field.setContentHuggingPriority(.defaultLow, for: .horizontal)
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        context.coordinator.field = field
        context.coordinator.installCustomKeyboard()

        return field
    }

    func updateUIView(
        _ field: UITextField,
        context: Context
    ) {
        context.coordinator.parent = self

        if field.text != text {
            field.text = text
        }

        if isActive, !field.isFirstResponder {
            DispatchQueue.main.async {
                field.becomeFirstResponder()
            }
        }
    }


    // MARK: Coordinator

    final class Coordinator: NSObject, UITextFieldDelegate {

        var parent: KinKeyboardTextField
        weak var field: UITextField?

        /// Rows × 42 pt keys, 6 pt gaps, 22 pt padding. Quantity has
        /// 6 rows; units have tabs, 3 rows of units and the actions.
        static func keyboardHeight(
            for keyboard: Keyboard
        ) -> CGFloat {
            let rows: CGFloat = keyboard == .quantity ? 6 : 5
            return rows * 42 + (rows - 1) * 6 + 22
        }

        init(parent: KinKeyboardTextField) {
            self.parent = parent
        }

        func installCustomKeyboard() {

            guard let field else {
                return
            }

            let pad: AnyView

            switch parent.keyboard {

            case .quantity:
                pad = AnyView(
                    QuantityKeypad(
                        onKey: { [weak self] key in self?.apply(key) },
                        onNext: { [weak self] in self?.parent.onNext() }
                    )
                )

            case .unit:
                pad = AnyView(
                    UnitKeypad(
                        startingGroup: MeasureKeyboardText.group(
                            for: parent.text
                        ),
                        onUnit: { [weak self] unit in
                            self?.setText(unit)
                            self?.parent.onNext()
                        },
                        onClear: { [weak self] in self?.setText("") },
                        onTypeOwn: { [weak self] in self?.useSystemKeyboard() },
                        onDone: { [weak self] in self?.parent.onNext() }
                    )
                )
            }

            let host = UIHostingController(rootView: pad)
            host.view.backgroundColor = .clear
            // The keyboard already sits above the home indicator; don't
            // let SwiftUI push the keys up for it again.
            host.safeAreaRegions = []

            // Six rows of keys; iOS adds the home-indicator space below.
            let input =
                UIInputView(
                    frame: CGRect(x: 0, y: 0, width: 0, height: Self.keyboardHeight(for: parent.keyboard)),
                    inputViewStyle: .keyboard
                )
            host.view.translatesAutoresizingMaskIntoConstraints = false
            input.addSubview(host.view)
            NSLayoutConstraint.activate([
                host.view.leadingAnchor.constraint(equalTo: input.leadingAnchor),
                host.view.trailingAnchor.constraint(equalTo: input.trailingAnchor),
                host.view.topAnchor.constraint(equalTo: input.topAnchor),
                host.view.bottomAnchor.constraint(equalTo: input.safeAreaLayoutGuide.bottomAnchor)
            ])

            field.inputView = input
            field.keyboardType = .default
        }

        /// "Type your own": the normal keyboard, until the field closes.
        func useSystemKeyboard() {
            guard let field else {
                return
            }
            field.inputView = nil
            field.keyboardType = .default
            field.reloadInputViews()
        }

        func apply(_ key: MeasureKey) {
            setText(
                MeasureKeyboardText.applying(
                    key,
                    to: field?.text ?? ""
                )
            )
        }

        func setText(_ value: String) {
            field?.text = value
            parent.text = value
            UIDevice.current.playInputClick()
        }

        @objc func textChanged(_ field: UITextField) {
            parent.text = field.text ?? ""
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            if !parent.isActive {
                parent.isActive = true
            }
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            if parent.isActive {
                parent.isActive = false
            }
            // Back to the custom pad next time.
            if textField.inputView == nil {
                installCustomKeyboard()
            }
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            parent.onNext()
            return false
        }
    }
}

extension UIInputView: @retroactive UIInputViewAudioFeedback {
    public var enableInputClicksWhenVisible: Bool { true }
}


// MARK: - Keys and Text Rules

/// A key on the quantity pad.
nonisolated enum MeasureKey: Equatable {
    case digit(Int)
    /// Typed as "1/2" so it saves like any other amount.
    case fraction(String)
    case decimal
    case delete
}

/// How the quantity pad edits the amount. Keys add to the end, and
/// keep it something the recipe can read: "2", "1 1/2", "0.5", "3/4".
nonisolated enum MeasureKeyboardText {

    static func applying(
        _ key: MeasureKey,
        to text: String
    ) -> String {

        let lastToken =
            text.split(separator: " ", omittingEmptySubsequences: false)
                .last
                .map(String.init) ?? ""

        let endsInFraction = lastToken.contains("/")

        switch key {

        case .digit(let digit):
            // Nothing after a fraction: "1/23" isn't an amount.
            return endsInFraction ? text : text + String(digit)

        case .fraction(let fraction):
            if text.isEmpty {
                return fraction
            }
            if endsInFraction || lastToken.contains(".") {
                return text
            }
            // "1" + ½ → "1 1/2"
            return text.last?.isNumber == true
                ? text + " " + fraction
                : text + fraction

        case .decimal:
            if endsInFraction || lastToken.contains(".") {
                return text
            }
            return text.isEmpty ? "0." : text + "."

        case .delete:
            // A fraction comes off whole: "1 1/2" → "1".
            if let range =
                text.range(
                    of: #"\s?\d+/\d+$"#,
                    options: .regularExpression
                ) {
                return String(text[..<range.lowerBound])
            }
            return String(text.dropLast())
        }
    }

    /// The unit pad's tabs.
    enum UnitGroup: String, CaseIterable, Identifiable {
        case volume = "Volume"
        case weight = "Weight"
        case other = "Other"

        var id: String { rawValue }

        /// Most used first.
        var units: [String] {
            switch self {
            case .volume:
                return [
                    "tsp", "Tbsp", "cup", "fl oz",
                    "pint", "quart", "gallon", "ml",
                    "L"
                ]
            case .weight:
                return ["oz", "lb", "g", "kg"]
            case .other:
                return [
                    "pinch", "dash", "clove", "can",
                    "slice", "piece", "pkg", "stick",
                    "bunch", "sprig"
                ]
            }
        }
    }

    static var units: [String] {
        UnitGroup.allCases.flatMap(\.units)
    }

    /// The tab a unit lives on, so the pad opens where the current
    /// unit is. Volume when empty or typed in by hand.
    static func group(
        for unit: String
    ) -> UnitGroup {
        UnitGroup.allCases.first {
            $0.units.contains(unit)
        } ?? .volume
    }

    /// Spoken names, so VoiceOver says "tablespoon", not "T B S P".
    static func spokenName(
        for unit: String
    ) -> String {
        switch unit {
        case "tsp": return "teaspoon"
        case "Tbsp": return "tablespoon"
        case "fl oz": return "fluid ounce"
        case "oz": return "ounce"
        case "lb": return "pound"
        case "g": return "gram"
        case "kg": return "kilogram"
        case "ml": return "milliliter"
        case "L": return "liter"
        case "pkg": return "package"
        default: return unit
        }
    }
}


// MARK: - Quantity Keypad

/// Numbers with the fractions recipes actually use.
private struct QuantityKeypad: View {

    let onKey: (MeasureKey) -> Void
    let onNext: () -> Void

    private let fractions: [(label: String, value: String, spoken: String)] = [
        ("½", "1/2", "one half"),
        ("¼", "1/4", "one quarter"),
        ("¾", "3/4", "three quarters"),
        ("⅓", "1/3", "one third"),
        ("⅔", "2/3", "two thirds"),
        ("⅛", "1/8", "one eighth")
    ]

    var body: some View {

        VStack(spacing: 6) {

            // Fractions across the top.
            HStack(spacing: 6) {
                ForEach(fractions, id: \.value) { fraction in
                    KeypadKey(
                        label: fraction.label,
                        style: .accent
                    ) {
                        onKey(.fraction(fraction.value))
                    }
                    .accessibilityLabel(fraction.spoken)
                }
            }

            ForEach([[1, 2, 3], [4, 5, 6], [7, 8, 9]], id: \.self) { row in
                HStack(spacing: 6) {
                    ForEach(row, id: \.self) { digit in
                        KeypadKey(label: "\(digit)") {
                            onKey(.digit(digit))
                        }
                    }
                }
            }

            HStack(spacing: 6) {
                KeypadKey(label: ".") {
                    onKey(.decimal)
                }
                .accessibilityLabel("Decimal point")

                KeypadKey(label: "0") {
                    onKey(.digit(0))
                }

                KeypadKey(
                    systemImage: "delete.left",
                    style: .action
                ) {
                    onKey(.delete)
                }
                .accessibilityLabel("Delete")
            }

            KeypadKey(
                label: "Next: Unit",
                style: .primary
            ) {
                onNext()
            }
        }
        .padding(.horizontal, 6)
        // The system keyboard background starts a little below the
        // top of the view.
        .padding(.top, 18)
        .padding(.bottom, 4)
    }
}


// MARK: - Unit Keypad

/// Kitchen units in Volume, Weight and Other tabs, plus a way to type
/// anything else. Other also has No Unit, for things like "2 eggs".
private struct UnitKeypad: View {

    let onUnit: (String) -> Void
    let onClear: () -> Void
    let onTypeOwn: () -> Void
    let onDone: () -> Void

    @State private var group: MeasureKeyboardText.UnitGroup

    init(
        startingGroup: MeasureKeyboardText.UnitGroup,
        onUnit: @escaping (String) -> Void,
        onClear: @escaping () -> Void,
        onTypeOwn: @escaping () -> Void,
        onDone: @escaping () -> Void
    ) {
        _group = State(initialValue: startingGroup)
        self.onUnit = onUnit
        self.onClear = onClear
        self.onTypeOwn = onTypeOwn
        self.onDone = onDone
    }

    private let columns =
        Array(
            repeating: GridItem(.flexible(), spacing: 6),
            count: 4
        )

    var body: some View {

        VStack(spacing: 6) {

            // Tabs
            HStack(spacing: 6) {
                ForEach(MeasureKeyboardText.UnitGroup.allCases) { option in
                    KeypadKey(
                        label: option.rawValue,
                        style: group == option ? .primary : .action
                    ) {
                        group = option
                    }
                    .accessibilityAddTraits(group == option ? .isSelected : [])
                }
            }

            // Always three rows tall, so the keys below don't jump
            // when switching tabs.
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(group.units, id: \.self) { unit in
                    KeypadKey(label: unit) {
                        onUnit(unit)
                    }
                    .accessibilityLabel(MeasureKeyboardText.spokenName(for: unit))
                }

                if group == .other {
                    KeypadKey(label: "No Unit", style: .accent) {
                        onUnit("")
                    }
                    .accessibilityLabel("No unit")
                }
            }
            .frame(height: 3 * 42 + 2 * 6, alignment: .top)

            HStack(spacing: 6) {
                KeypadKey(label: "Clear", style: .action) {
                    onClear()
                }

                KeypadKey(
                    label: "Type",
                    systemImage: "keyboard",
                    style: .action
                ) {
                    onTypeOwn()
                }
                .accessibilityLabel("Type your own unit")

                KeypadKey(label: "Done", style: .primary) {
                    onDone()
                }
            }
        }
        .padding(.horizontal, 6)
        // The system keyboard background starts a little below the
        // top of the view.
        .padding(.top, 18)
        .padding(.bottom, 4)
        .sensoryFeedback(.selection, trigger: group)
    }
}


// MARK: - Key

private struct KeypadKey: View {

    enum Style {
        case plain
        case accent
        case action
        case primary
    }

    var label: String? = nil
    var systemImage: String? = nil
    var style: Style = .plain
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {

        Button(action: action) {
            HStack(spacing: 4) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                if let label {
                    Text(label)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .font(font)
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black.opacity(0.25), radius: 0, y: 1)
        }
        .buttonStyle(KeyPressStyle())
    }

    private var font: Font {
        switch style {
        case .accent:
            return .system(size: 22, weight: .medium)
        case .primary:
            return KinTypography.headline
        default:
            return .system(size: 20, weight: .regular)
        }
    }

    private var foreground: Color {
        switch style {
        case .primary:
            return .white
        case .accent:
            return KinColors.primary
        default:
            return Color(.label)
        }
    }

    private var background: Color {
        switch style {
        case .primary:
            return KinColors.primary
        case .action:
            // The darker keys on the system keyboard.
            return colorScheme == .dark
                ? Color(white: 0.27)
                : Color(red: 0.67, green: 0.70, blue: 0.74)
        default:
            return colorScheme == .dark
                ? Color(white: 0.42)
                : .white
        }
    }
}

private struct KeyPressStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}
