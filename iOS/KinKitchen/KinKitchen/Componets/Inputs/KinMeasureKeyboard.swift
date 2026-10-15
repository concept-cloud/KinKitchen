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

        /// Rows × 44 pt keys with 8 pt gaps, plus the grabber and
        /// padding. Quantity has 6 rows; units have tabs, 3 rows of
        /// units and the actions.
        static func keyboardHeight(
            for keyboard: Keyboard
        ) -> CGFloat {
            let rows: CGFloat = keyboard == .quantity ? 6 : 5
            return rows * KeypadMetrics.keyHeight
                + (rows - 1) * KeypadMetrics.spacing
                + KeypadMetrics.chromeHeight
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

            let host = UIHostingController(rootView: KeyboardSheet { pad })
            host.view.backgroundColor = .clear
            // The keyboard already sits above the home indicator; don't
            // let SwiftUI push the keys up for it again.
            host.safeAreaRegions = []

            // Our own sheet instead of the system keyboard background,
            // so the rounded top shows the page behind it.
            let input =
                KeyboardContainer(
                    frame: CGRect(
                        x: 0,
                        y: 0,
                        width: 0,
                        height: Self.keyboardHeight(for: parent.keyboard)
                    )
                )
            input.backgroundColor = .clear

            // The sheet color continues under the home indicator.
            let filler = UIView()
            filler.backgroundColor = UIColor(KinColors.paper)
            filler.translatesAutoresizingMaskIntoConstraints = false
            input.addSubview(filler)

            host.view.translatesAutoresizingMaskIntoConstraints = false
            input.addSubview(host.view)
            NSLayoutConstraint.activate([
                host.view.leadingAnchor.constraint(equalTo: input.leadingAnchor),
                host.view.trailingAnchor.constraint(equalTo: input.trailingAnchor),
                host.view.topAnchor.constraint(equalTo: input.topAnchor),
                host.view.bottomAnchor.constraint(equalTo: input.safeAreaLayoutGuide.bottomAnchor),
                filler.leadingAnchor.constraint(equalTo: input.leadingAnchor),
                filler.trailingAnchor.constraint(equalTo: input.trailingAnchor),
                filler.topAnchor.constraint(equalTo: host.view.bottomAnchor, constant: -1),
                filler.bottomAnchor.constraint(equalTo: input.bottomAnchor)
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

/// Holds a measure keyboard. Lets the keys play the keyboard click.
private final class KeyboardContainer: UIView, UIInputViewAudioFeedback {
    var enableInputClicksWhenVisible: Bool { true }
}


// MARK: - Sheet

private enum KeypadMetrics {
    static let keyHeight: CGFloat = 44
    static let spacing: CGFloat = 8
    static let cornerRadius: CGFloat = 12
    /// Grabber (8 + 5 + 10) and bottom padding (8).
    static let chromeHeight: CGFloat = 31
}

/// The cream sheet the keys sit on: rounded top, grabber, soft shadow.
private struct KeyboardSheet<Content: View>: View {

    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(KinColors.secondaryText.opacity(0.35))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 10)
                .accessibilityHidden(true)

            content
                .padding(.horizontal, KinSpacing.medium)
                .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: KinRadius.xLarge,
                topTrailingRadius: KinRadius.xLarge
            )
            .fill(KinColors.paper)
            .shadow(color: .black.opacity(0.1), radius: 10, y: -2)
        )
    }
}


// MARK: - Keys and Text Rules

/// A key on the quantity pad.
nonisolated enum MeasureKey: Equatable {
    case digit(Int)
    /// A fraction character like "½"; it reads back as 1/2.
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

        let endsInFraction =
            lastToken.contains("/")
                || text.last.map {
                    IngredientQuantityFormatter.fractionGlyphs
                        .values.contains(String($0))
                } == true

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
            // "1" + ½ → "1½"
            return text + fraction

        case .decimal:
            if endsInFraction || lastToken.contains(".") {
                return text
            }
            return text.isEmpty ? "0." : text + "."

        case .delete:
            // A fraction comes off whole: "1½" → "1", "1 1/2" → "1".
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
        ("½", "½", "one half"),
        ("¼", "¼", "one quarter"),
        ("¾", "¾", "three quarters"),
        ("⅓", "⅓", "one third"),
        ("⅔", "⅔", "two thirds"),
        ("⅛", "⅛", "one eighth")
    ]

    var body: some View {

        VStack(spacing: KeypadMetrics.spacing) {

            // Fractions across the top.
            HStack(spacing: KeypadMetrics.spacing) {
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
                HStack(spacing: KeypadMetrics.spacing) {
                    ForEach(row, id: \.self) { digit in
                        KeypadKey(label: "\(digit)") {
                            onKey(.digit(digit))
                        }
                    }
                }
            }

            HStack(spacing: KeypadMetrics.spacing) {
                KeypadKey(label: ".") {
                    onKey(.decimal)
                }
                .accessibilityLabel("Decimal point")

                KeypadKey(label: "0") {
                    onKey(.digit(0))
                }

                KeypadKey(
                    systemImage: "delete.left",
                    style: .accent
                ) {
                    onKey(.delete)
                }
                .accessibilityLabel("Delete")
            }

            KeypadKey(
                label: "Next: Unit",
                trailingImage: KinIcons.forward,
                style: .primary
            ) {
                onNext()
            }
        }

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
            repeating: GridItem(.flexible(), spacing: KeypadMetrics.spacing),
            count: 4
        )

    var body: some View {

        VStack(spacing: KeypadMetrics.spacing) {

            // Tabs
            HStack(spacing: KeypadMetrics.spacing) {
                ForEach(MeasureKeyboardText.UnitGroup.allCases) { option in
                    KeypadKey(
                        label: option.rawValue,
                        style: group == option ? .primary : .tab
                    ) {
                        group = option
                    }
                    .accessibilityAddTraits(group == option ? .isSelected : [])
                }
            }

            // Always three rows tall, so the keys below don't jump
            // when switching tabs.
            LazyVGrid(columns: columns, spacing: KeypadMetrics.spacing) {
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
            .frame(
                height: 3 * KeypadMetrics.keyHeight + 2 * KeypadMetrics.spacing,
                alignment: .top
            )

            HStack(spacing: KeypadMetrics.spacing) {
                KeypadKey(label: "Clear", style: .accent) {
                    onClear()
                }

                KeypadKey(
                    label: "Type",
                    systemImage: "keyboard",
                    style: .accent
                ) {
                    onTypeOwn()
                }
                .accessibilityLabel("Type your own unit")

                KeypadKey(label: "Done", style: .primary) {
                    onDone()
                }
            }
        }

        .sensoryFeedback(.selection, trigger: group)
    }
}


// MARK: - Key

private struct KeypadKey: View {

    enum Style {
        /// Cream keys: numbers and units.
        case plain
        /// Soft pink with red text: fractions, delete, Clear, Type.
        case accent
        /// Soft pink with dark text: tabs that aren't selected.
        case tab
        /// Red: Next, Done, the selected tab.
        case primary
    }

    var label: String? = nil
    var systemImage: String? = nil
    var trailingImage: String? = nil
    var style: Style = .plain
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {

        Button(action: action) {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                if let label {
                    Text(label)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                if let trailingImage {
                    Image(systemName: trailingImage)
                        .font(.system(size: 14, weight: .bold))
                }
            }
            .font(font)
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .frame(height: KeypadMetrics.keyHeight)
            .background(
                background,
                in: RoundedRectangle(cornerRadius: KeypadMetrics.cornerRadius)
            )
            .shadow(
                color: .black.opacity(style == .plain ? 0.07 : 0),
                radius: 2,
                y: 1
            )
        }
        .buttonStyle(KeyPressStyle())
    }

    private var font: Font {
        switch style {
        case .accent where label == nil:
            return .system(size: 20, weight: .semibold)
        case .accent:
            return .system(size: 20, weight: .medium)
        case .primary:
            return KinTypography.headline
        case .plain, .tab:
            return .system(size: 21, weight: .regular)
        }
    }

    private var foreground: Color {
        switch style {
        case .primary:
            return .white
        case .accent:
            return KinColors.primary
        case .plain, .tab:
            return KinColors.primaryText
        }
    }

    private var background: Color {
        switch style {
        case .primary:
            return KinColors.primary
        case .accent, .tab:
            return KinColors.primary.opacity(colorScheme == .dark ? 0.22 : 0.1)
        case .plain:
            return colorScheme == .dark
                ? Color.white.opacity(0.08)
                : Color(red: 1.0, green: 0.995, blue: 0.98)
        }
    }
}

private struct KeyPressStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .opacity(configuration.isPressed ? 0.75 : 1)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}
