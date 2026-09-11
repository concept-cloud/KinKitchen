//
//  AddGatheringView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 9/10/26.
//

import SwiftUI


struct AddGatheringView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var theme = ""
    @State private var date = Date()
    @State private var time = Date()
    @State private var location = ""
    @State private var description = ""

    @State private var isSaving = false
    @State private var errorMessage: String?
    
    @State private var isDatePickerExpanded = false
    @State private var isTimePickerExpanded = false


    var body: some View {

        ZStack {

            KinColors.background
                .ignoresSafeArea()

            ScrollView {

                VStack(
                    alignment: .leading,
                    spacing: KinSpacing.xLarge
                ) {

                    header

                    gatheringForm

                    if let errorMessage {

                        Text(
                            errorMessage
                        )
                        .font(
                            KinTypography.body
                        )
                        .foregroundStyle(
                            KinColors.error
                        )
                    }

                    createButton
                }
                .padding(
                    KinSpacing.large
                )
            }
        }
        .navigationBarHidden(true)
    }
}


// MARK: - Header

private extension AddGatheringView {

    var header: some View {

        HStack {

            Button(
                "Cancel"
            ) {

                dismiss()
            }
            .font(
                KinTypography.button
            )
            .foregroundStyle(
                KinColors.secondaryText
            )


            Spacer()


            Text(
                "Add Gathering"
            )
            .font(
                KinTypography.title
            )
            .foregroundStyle(
                KinColors.primaryText
            )


            Spacer()


            Text(
                "Cancel"
            )
            .font(
                KinTypography.button
            )
            .foregroundStyle(
                .clear
            )
        }
    }
}


// MARK: - Form

private extension AddGatheringView {

    var gatheringForm: some View {

        VStack(
            alignment: .leading,
            spacing: KinSpacing.large
        ) {

            fieldLabel(
                "Gathering Name"
            )

            KinTextField(
                title: "Gathering Name",
                text: $name
            )


            fieldLabel(
                "Theme"
            )

            KinTextField(
                title: "Theme (Optional)",
                text: $theme
            )


            // MARK: Date

            fieldLabel(
                "Date"
            )

            VStack(
                spacing: KinSpacing.small
            ) {

                Button {

                    withAnimation {
                        isDatePickerExpanded.toggle()
                        isTimePickerExpanded = false
                    }

                } label: {

                    HStack {

                        Text(
                            date.formatted(
                                date: .long,
                                time: .omitted
                            )
                        )
                        .font(
                            KinTypography.body
                        )
                        .foregroundStyle(
                            KinColors.primaryText
                        )

                        Spacer()

                        Image(
                            systemName:
                                isDatePickerExpanded
                                    ? "chevron.up"
                                    : "calendar"
                        )
                        .foregroundStyle(
                            KinColors.primary
                        )
                    }
                    .padding(
                        KinSpacing.medium
                    )
                    .background(
                        KinColors.surface
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius:
                                KinRadius.medium
                        )
                    )
                }
                .buttonStyle(
                    .plain
                )


                if isDatePickerExpanded {

                    VStack(
                        spacing: KinSpacing.medium
                    ) {

                        DatePicker(
                            "",
                            selection: $date,
                            displayedComponents: .date
                        )
                        .datePickerStyle(
                            .graphical
                        )
                        .labelsHidden()
                        .tint(
                            KinColors.primary
                        )


                        HStack {

                            Spacer()

                            Button {

                                withAnimation {
                                    isDatePickerExpanded = false
                                }

                            } label: {

                                Image(
                                    systemName:
                                        "checkmark.circle.fill"
                                )
                                .font(
                                    .system(
                                        size: 30
                                    )
                                )
                                .foregroundStyle(
                                    KinColors.primary
                                )
                            }
                            .buttonStyle(
                                .plain
                            )
                            .accessibilityLabel(
                                "Set Date"
                            )
                        }
                    }
                    .padding(
                        KinSpacing.medium
                    )
                    .background(
                        KinColors.surface
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius:
                                KinRadius.medium
                        )
                    )
                }
            }


            // MARK: Time

            fieldLabel(
                "Time"
            )

            VStack(
                spacing: KinSpacing.small
            ) {

                Button {

                    withAnimation {
                        isTimePickerExpanded.toggle()
                        isDatePickerExpanded = false
                    }

                } label: {

                    HStack {

                        Text(
                            time.formatted(
                                date: .omitted,
                                time: .shortened
                            )
                        )
                        .font(
                            KinTypography.body
                        )
                        .foregroundStyle(
                            KinColors.primaryText
                        )

                        Spacer()

                        Image(
                            systemName:
                                isTimePickerExpanded
                                    ? "chevron.up"
                                    : "clock"
                        )
                        .foregroundStyle(
                            KinColors.primary
                        )
                    }
                    .padding(
                        KinSpacing.medium
                    )
                    .background(
                        KinColors.surface
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius:
                                KinRadius.medium
                        )
                    )
                }
                .buttonStyle(
                    .plain
                )


                if isTimePickerExpanded {

                    VStack(
                        spacing: KinSpacing.medium
                    ) {

                        DatePicker(
                            "",
                            selection: $time,
                            displayedComponents:
                                .hourAndMinute
                        )
                        .datePickerStyle(
                            .wheel
                        )
                        .labelsHidden()
                        .tint(
                            KinColors.primary
                        )


                        HStack {

                            Spacer()

                            Button {

                                withAnimation {
                                    isTimePickerExpanded = false
                                }

                            } label: {

                                Image(
                                    systemName:
                                        "checkmark.circle.fill"
                                )
                                .font(
                                    .system(
                                        size: 30
                                    )
                                )
                                .foregroundStyle(
                                    KinColors.primary
                                )
                            }
                            .buttonStyle(
                                .plain
                            )
                            .accessibilityLabel(
                                "Set Time"
                            )
                        }
                    }
                    .padding(
                        KinSpacing.medium
                    )
                    .background(
                        KinColors.surface
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius:
                                KinRadius.medium
                        )
                    )
                }
            }

            fieldLabel(
                "Location"
            )

            KinTextField(
                title: "Location",
                text: $location
            )


            fieldLabel(
                "Description"
            )

            KinTextEditor(
                text: $description
            )
        }
    }


    func fieldLabel(
        _ title: String
    ) -> some View {

        Text(
            title
        )
        .font(
            KinTypography.headline
        )
        .foregroundStyle(
            KinColors.primaryText
        )
    }
}


// MARK: - Create Button

private extension AddGatheringView {

    var createButton: some View {

        KinPrimaryButton(
            title:
                isSaving
                    ? "Creating..."
                    : "Create Gathering"
        ) {

            Task {

                await createGathering()
            }
        }
        .disabled(
            isSaving
        )
        .opacity(
            isSaving
                ? 0.6
                : 1
        )
    }
}


// MARK: - Create Gathering

private extension AddGatheringView {

    @MainActor
    func createGathering() async {

        errorMessage = nil


        let cleanName =
            name.trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )

        guard !cleanName.isEmpty else {

            errorMessage =
                "Please enter a gathering name."

            return
        }


        let startsAt =
            combinedDateAndTime()


        guard startsAt > Date() else {

            errorMessage =
                "Please select a future date and time."

            return
        }


        isSaving = true

        defer {

            isSaving = false
        }


        do {

            _ =
                try await GatheringService
                    .createGathering(
                        name: cleanName,
                        theme:
                            cleaned(
                                theme
                            ),
                        description:
                            cleaned(
                                description
                            ),
                        location:
                            cleaned(
                                location
                            ),
                        startsAt:
                            startsAt,
                        guestLimit:
                            nil
                    )

            dismiss()

        } catch {

            errorMessage =
                "Unable to create gathering. Please try again."

            print(
                "CREATE GATHERING ERROR:",
                error.localizedDescription
            )
        }
    }
}


// MARK: - Helpers

private extension AddGatheringView {

    func combinedDateAndTime() -> Date {

        let calendar =
            Calendar.current

        let dateComponents =
            calendar.dateComponents(
                [
                    .year,
                    .month,
                    .day
                ],
                from: date
            )

        let timeComponents =
            calendar.dateComponents(
                [
                    .hour,
                    .minute
                ],
                from: time
            )


        var components =
            DateComponents()

        components.year =
            dateComponents.year

        components.month =
            dateComponents.month

        components.day =
            dateComponents.day

        components.hour =
            timeComponents.hour

        components.minute =
            timeComponents.minute


        return calendar.date(
            from: components
        )
        ?? Date()
    }


    func cleaned(
        _ value: String
    ) -> String? {

        let cleanedValue =
            value.trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )

        return cleanedValue.isEmpty
            ? nil
            : cleanedValue
    }
}


#Preview {

    NavigationStack {

        AddGatheringView()
    }
}
