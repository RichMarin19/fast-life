import SwiftUI

struct AddWeightView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var weightManager: WeightManager

    @State private var weight: String = ""
    @State private var bmi: String = ""
    @State private var bodyFat: String = ""
    @State private var selectedDate = Date()
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Weight Information")) {
                    DatePicker("Date & Time", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])

                    HStack {
                        Text("Weight")
                        TextField("Enter weight", text: $weight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("lbs")
                            .foregroundColor(.secondary)
                    }
                }

                Section(header: Text("Optional Metrics")) {
                    HStack {
                        Text("BMI")
                        TextField("Enter BMI", text: $bmi)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text("Body Fat")
                        TextField("Enter body fat %", text: $bodyFat)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("%")
                            .foregroundColor(.secondary)
                    }
                }

                Section {
                    Button(action: saveWeight) {
                        HStack {
                            Spacer()
                            Text("Save Weight Entry")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(weight.isEmpty)
                }
            }
            .navigationTitle("Add Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func saveWeight() {
        // Validate weight
        guard let weightValue = Double(weight.trimmingCharacters(in: .whitespaces)),
              weightValue > 0 && weightValue < 1000 else {
            errorMessage = "Please enter a valid weight between 0 and 1000 lbs"
            showingError = true
            return
        }

        // Validate BMI if provided
        var bmiValue: Double? = nil
        if !bmi.isEmpty {
            guard let parsedBMI = Double(bmi.trimmingCharacters(in: .whitespaces)),
                  parsedBMI > 0 && parsedBMI < 100 else {
                errorMessage = "Please enter a valid BMI between 0 and 100"
                showingError = true
                return
            }
            bmiValue = parsedBMI
        }

        // Validate body fat if provided
        var bodyFatValue: Double? = nil
        if !bodyFat.isEmpty {
            guard let parsedBodyFat = Double(bodyFat.trimmingCharacters(in: .whitespaces)),
                  parsedBodyFat > 0 && parsedBodyFat < 100 else {
                errorMessage = "Please enter a valid body fat percentage between 0 and 100"
                showingError = true
                return
            }
            bodyFatValue = parsedBodyFat
        }

        // Create and save weight entry
        let entry = WeightEntry(
            date: selectedDate,
            weight: weightValue,
            bmi: bmiValue,
            bodyFat: bodyFatValue,
            source: .manual
        )

        weightManager.addWeightEntry(entry)
        dismiss()
    }
}

#Preview {
    AddWeightView(weightManager: WeightManager())
}
