import SwiftUI

struct StopFastConfirmationView: View {
    let onEditTimes: () -> Void
    let onStop: () -> Void
    let onDelete: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
                .frame(height: 30)

            Text("Stop Fast?")
                .font(.title2)
                .fontWeight(.bold)

            Text("Do you want to edit the start/end times\nbefore stopping?")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            Spacer()
                .frame(height: 10)

            VStack(spacing: 12) {
                // Edit Times Button
                Button(action: onEditTimes) {
                    Text("Edit Times")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }

                // Stop Button - GREEN, BOLD, LARGER
                Button(action: onStop) {
                    Text("Stop")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(8)
                }

                // Delete Button
                Button(action: onDelete) {
                    Text("Delete")
                        .font(.headline)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }

                // Cancel Button
                Button(action: onCancel) {
                    Text("Cancel")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 30)

            Spacer()
        }
    }
}