import SwiftUI
import UIKit
import CoffeeKit

/// One tap, five states. Not a slider — precision targets and wet hands don't mix.
struct RatingControl: View {
    @Binding var rating: Int

    var body: some View {
        HStack(spacing: 10) {
            ForEach(1...5, id: \.self) { value in
                Button {
                    rating = value
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Image(systemName: value <= rating ? "star.fill" : "star")
                        .font(.system(size: 30))
                        .foregroundStyle(value <= rating ? Theme.water : Theme.faint)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(value) star\(value == 1 ? "" : "s")")
                .accessibilityAddTraits(value == rating ? [.isSelected] : [])
            }
        }
    }
}

/// A five-position axis picker.
///
/// Segments rather than a slider, deliberately: a slider demands precision the
/// user doesn't have at a counter and implies a granularity the diagnosis engine
/// doesn't use. Each position is one tap, and the centre is pre-selected so the
/// fast path through the log screen is rate-and-done.
struct AxisPicker: View {
    let title: String
    let lowLabel: String
    let centreLabel: String
    let highLabel: String
    /// Tints the ends with the extraction palette so the colour teaches the scale.
    var tinted: Bool = true
    @Binding var value: Int

    private let positions = [-2, -1, 0, 1, 2]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).sectionLabel()

            HStack(spacing: 6) {
                ForEach(positions, id: \.self) { position in
                    Button {
                        value = position
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Capsule()
                            .fill(fill(for: position))
                            .frame(height: 44)
                            .overlay(
                                Capsule().strokeBorder(
                                    position == value ? tint(for: position) : Theme.line,
                                    lineWidth: position == value ? 2 : 1
                                )
                            )
                            .overlay(alignment: .center) {
                                if position == 0 {
                                    Circle()
                                        .fill(position == value ? tint(for: 0) : Theme.faint)
                                        .frame(width: 6, height: 6)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(accessibilityLabel(for: position))
                    .accessibilityAddTraits(position == value ? [.isSelected] : [])
                }
            }

            HStack {
                Text(lowLabel)
                Spacer()
                Text(centreLabel)
                Spacer()
                Text(highLabel)
            }
            .font(.caption)
            .foregroundStyle(Theme.muted)
        }
    }

    private func tint(for position: Int) -> Color {
        guard tinted else { return Theme.water }
        return Theme.extractionColor(position)
    }

    private func fill(for position: Int) -> Color {
        position == value ? tint(for: position).opacity(0.22) : Theme.surfaceAlt
    }

    private func accessibilityLabel(for position: Int) -> String {
        switch position {
        case -2: return "Very \(lowLabel)"
        case -1: return "Slightly \(lowLabel)"
        case 0: return centreLabel
        case 1: return "Slightly \(highLabel)"
        default: return "Very \(highLabel)"
        }
    }
}

struct FreshnessBadge: View {
    let freshness: Freshness?
    let restDays: Int?

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(Theme.freshnessColor(freshness))
                .frame(width: 7, height: 7)
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.muted)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
    }

    private var label: String {
        guard let freshness else { return "No roast date" }
        guard let restDays else { return freshness.label }
        return "\(freshness.label) · day \(restDays)"
    }
}

/// Every empty state does exactly one job and offers exactly one action.
/// Written before the populated designs, because it's the first thing every user
/// sees and the last thing anyone designs.
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(Theme.faint)
            Text(title)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
            Text(message)
                .font(.callout)
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.water)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 44)
    }
}

/// The app's one primary button shape. Full width, thumb height, bottom of screen.
struct PrimaryButtonStyle: ButtonStyle {
    var tint: Color = Theme.water

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(tint.opacity(configuration.isPressed ? 0.8 : 1),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
