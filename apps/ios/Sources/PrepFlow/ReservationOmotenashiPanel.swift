// 正本: design/p2-wireframe-special-prep.png
// 正本: design/p3-wireframe-allergy-message.png
// 正本: design/p3-wireframe-allergen-labels.png
import DesignTokens
import Engine
import SwiftUI

// 正本: design/p2-wireframe-special-prep.png
// 正本: design/p3-wireframe-allergy-message.png
// 正本: design/p3-wireframe-allergen-labels.png
struct ReservationOmotenashiPanel: View {
    let specialPrepTasks: [SpecialPrepTask]
    let allergenLabels: [AllergenLabel]
    let guestMessages: [GuestMessage]
    let specialPrepLastAction: String
    let guestMessageLastAction: String
    let allergenLabelPrintCount: Int
    let guestReplyRecheckCount: Int
    let guestReplyRecheckLastAction: String
    let guestReplyRequiresLabelReprint: Bool
    let completeSpecialPrep: (String) -> Void
    let skipSpecialPrep: (String) -> Void
    let sendGuestMessages: () -> Void
    let printAllergenLabels: () -> Void
    let recordGuestReplyChange: () -> Void
    let completeGuestReplyRecheck: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.xs) {
            HStack {
                VStack(alignment: .leading, spacing: PrepFlowSpacing.xxs) {
                    Text("おもてなし連携")
                        .font(PrepFlowFont.bodyBold)
                    Text(specialPrepLastAction)
                        .font(PrepFlowFont.railMeta)
                        .foregroundStyle(PrepFlowColor.g2)
                }
                Spacer()
                Text("\(specialPrepTasks.count + allergenLabels.count)")
                    .font(PrepFlowFont.railTitle)
                    .monospacedDigit()
            }

            if let task = specialPrepTasks.first {
                ReservationSpecialPrepRow(task: task, complete: completeSpecialPrep, skip: skipSpecialPrep)
            } else {
                Text("TableCheckのおもてなし情報を承認すると、特別仕込みがここに出ます。")
                    .font(PrepFlowFont.railMeta)
                    .foregroundStyle(PrepFlowColor.g2)
                    .padding(PrepFlowSpacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(PrepFlowColor.white)
                    .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
            }

            if let label = allergenLabels.first {
                ReservationAllergenPreview(label: label)
            }

            HStack(spacing: PrepFlowSpacing.xs) {
                Button(messageButtonTitle, action: sendGuestMessages)
                    .buttonStyle(ReservationOmotenashiButtonStyle(isPrimary: false))
                    .disabled(guestMessages.isEmpty)
                Button(labelButtonTitle, action: printAllergenLabels)
                    .buttonStyle(ReservationOmotenashiButtonStyle(isPrimary: true))
                    .disabled(allergenLabels.isEmpty)
            }

            ReservationGuestReplyRecheckRow(
                recheckCount: guestReplyRecheckCount,
                status: guestReplyRecheckLastAction,
                requiresLabelReprint: guestReplyRequiresLabelReprint,
                recordChange: recordGuestReplyChange,
                completeRecheck: completeGuestReplyRecheck
            )

            Text(guestMessageLastAction)
                .font(PrepFlowFont.railMeta)
                .foregroundStyle(PrepFlowColor.g2)
        }
        .padding(PrepFlowSpacing.sm)
        .background(PrepFlowColor.g5)
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous)
                .stroke(PrepFlowColor.g4, lineWidth: PrepFlowMetric.lineWidth)
        }
    }

    private var messageButtonTitle: String {
        guestMessages.isEmpty ? "確認文なし" : "確認文を送信"
    }

    private var labelButtonTitle: String {
        allergenLabels.isEmpty ? "ラベルなし" : "ラベル印刷 \(allergenLabelPrintCount)"
    }
}

// 正本: design/p3-wireframe-allergy-message.png
private struct ReservationGuestReplyRecheckRow: View {
    let recheckCount: Int
    let status: String
    let requiresLabelReprint: Bool
    let recordChange: () -> Void
    let completeRecheck: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.xs) {
            HStack(spacing: PrepFlowSpacing.xs) {
                VStack(alignment: .leading, spacing: PrepFlowSpacing.xxs) {
                    Text("返信変更")
                        .font(PrepFlowFont.smallBold)
                        .foregroundStyle(recheckCount > 0 ? PrepFlowColor.time : PrepFlowColor.ink) // time-use: guest reply changed before service
                    Text(statusText)
                        .font(PrepFlowFont.railMeta)
                        .foregroundStyle(recheckCount > 0 ? PrepFlowColor.time : PrepFlowColor.g2) // time-use: reply recheck deadline detail
                }

                Spacer()

                Text("\(recheckCount)")
                    .font(PrepFlowFont.railTitle)
                    .monospacedDigit()
                    .foregroundStyle(recheckCount > 0 ? PrepFlowColor.time : PrepFlowColor.ink) // time-use: active reply recheck count
            }

            HStack(spacing: PrepFlowSpacing.xs) {
                Button("変更返信を取り込む", action: recordChange)
                    .buttonStyle(ReservationOmotenashiButtonStyle(isPrimary: false))
                Button("再確認完了", action: completeRecheck)
                    .buttonStyle(ReservationOmotenashiButtonStyle(isPrimary: true))
                    .disabled(recheckCount == 0)
            }
        }
        .padding(PrepFlowSpacing.xs)
        .background(recheckCount > 0 ? PrepFlowColor.time.opacity(PrepFlowOpacity.timeSoft) : PrepFlowColor.white) // time-use: reply recheck row background
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous)
                .stroke(rowBorder, lineWidth: PrepFlowMetric.lineWidth)
        }
    }

    private var statusText: String {
        if requiresLabelReprint {
            return "\(status) / 席札再印刷"
        }
        return status
    }

    private var rowBorder: Color {
        recheckCount > 0 ? PrepFlowColor.time.opacity(PrepFlowOpacity.timeStroke) : PrepFlowColor.g4 // time-use: reply recheck row border
    }
}

// 正本: design/p2-wireframe-special-prep.png
private struct ReservationSpecialPrepRow: View {
    let task: SpecialPrepTask
    let complete: (String) -> Void
    let skip: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.xs) {
            Text(task.title)
                .font(PrepFlowFont.smallBold)
            Text(task.note)
                .font(PrepFlowFont.railMeta)
                .foregroundStyle(PrepFlowColor.g2)
                .lineLimit(2)
            HStack(spacing: PrepFlowSpacing.xs) {
                Button("スキップ") {
                    skip(task.id)
                }
                .buttonStyle(ReservationOmotenashiButtonStyle(isPrimary: false))
                Button("完了") {
                    complete(task.id)
                }
                .buttonStyle(ReservationOmotenashiButtonStyle(isPrimary: true))
            }
        }
        .padding(PrepFlowSpacing.xs)
        .background(PrepFlowColor.white)
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
    }
}

// 正本: design/p3-wireframe-allergen-labels.png
private struct ReservationAllergenPreview: View {
    let label: AllergenLabel

    var body: some View {
        HStack(spacing: PrepFlowSpacing.sm) {
            Text(label.seatRef)
                .font(PrepFlowFont.railTitle)
                .frame(width: PrepFlowMetric.actionButtonHeight, alignment: .leading)
            VStack(alignment: .leading, spacing: PrepFlowSpacing.xxs) {
                Text("席番アレルゲン")
                    .font(PrepFlowFont.smallBold)
                    .foregroundStyle(PrepFlowColor.time) // time-use: allergen warning before service
                Text(label.displayText)
                    .font(PrepFlowFont.railMeta)
                    .foregroundStyle(PrepFlowColor.g2)
                    .lineLimit(1)
            }
        }
        .padding(PrepFlowSpacing.xs)
        .background(PrepFlowColor.white)
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous)
                .stroke(PrepFlowColor.time.opacity(PrepFlowOpacity.timeStroke), lineWidth: PrepFlowMetric.lineWidth) // time-use: allergen warning border
        }
    }
}

private struct ReservationOmotenashiButtonStyle: ButtonStyle {
    let isPrimary: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PrepFlowFont.smallBold)
            .foregroundStyle(isPrimary ? PrepFlowColor.white : PrepFlowColor.ink)
            .frame(maxWidth: .infinity)
            .frame(height: PrepFlowMetric.catalogFieldHeight)
            .background(isPrimary ? PrepFlowColor.ink : PrepFlowColor.white)
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
            .opacity(configuration.isPressed ? PrepFlowOpacity.pressed : PrepFlowOpacity.solid)
    }
}
