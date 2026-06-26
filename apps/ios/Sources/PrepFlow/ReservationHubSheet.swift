// 正本: design/p2-wireframe-reservation-hub-liquidglass.png
import DesignTokens
import Engine
import SwiftUI

// 正本: design/p2-wireframe-reservation-hub-liquidglass.png
struct ReservationHubSheet: View {
    @ObservedObject var store: BoardStore
    let done: () -> Void
    @State private var isDirectBookingPresented = false
    @State private var isServicePassPresented = false

    var body: some View {
        ZStack {
            PrepFlowColor.g5.ignoresSafeArea()

            VStack(spacing: PrepFlowSpacing.md) {
                ReservationHubTopBar(
                    close: done,
                    resync: {
                        store.queueConnectorReservationDiffs()
                    }
                )

                HStack(spacing: PrepFlowSpacing.sm) {
                    ReservationSourceChip(title: "PrepFlow Direct", value: sourceCovers(.direct), marker: "D", isDirect: true)
                    ReservationSourceChip(title: "TableCheck", value: sourceCovers(.tablecheck), marker: "T", isDirect: false)
                    ReservationSourceChip(title: "手入力・電話", value: sourceCovers(.manual), marker: "手", isDirect: false)
                    ReservationSourceChip(title: "差分", value: diffCovers, marker: "Δ", isDirect: false)
                }

                HStack(alignment: .top, spacing: PrepFlowSpacing.none) {
                    ReservationHubList(
                        reservations: store.service.reservations.sorted { $0.visitTime < $1.visitTime },
                        hasDuplicate: hasDuplicateCandidate,
                        duplicateDecision: store.reservationHubDuplicateDecision,
                        assignedCourses: store.reservationHubAssignedCourses,
                        keepSeparate: {
                            store.keepReservationHubDuplicateSeparate()
                        },
                        mergeDuplicate: {
                            store.mergeReservationHubDuplicate()
                        },
                        assignCourse: { reservationID in
                            store.assignReservationHubCourse(reservationID)
                        }
                    )
                    ReservationHubApplyPanel(
                        covers: store.service.omakaseCovers,
                        diff: store.reservationDiffSummary,
                        plan: store.reservationPlanDiff,
                        unassignedCovers: store.reservationHubUnassignedCovers,
                        needsDuplicateReview: store.reservationHubNeedsDuplicateReview,
                        canApply: store.reservationHubCanApplyToPrep,
                        applyCount: store.reservationHubApplyCount,
                        appliedAt: store.reservationHubAppliedAt,
                        connectorItems: store.connectorDiffReviewItems,
                        connectorSummary: store.connectorLastSyncSummary,
                        specialPrepTasks: store.specialPrepTasks,
                        allergenLabels: store.allergenLabels,
                        guestMessages: store.guestMessages,
                        specialPrepLastAction: store.specialPrepLastAction,
                        guestMessageLastAction: store.guestMessageLastAction,
                        allergenLabelPrintCount: store.allergenLabelPrintCount,
                        guestReplyRecheckCount: store.guestReplyRecheckCount,
                        guestReplyRecheckLastAction: store.guestReplyRecheckLastAction,
                        guestReplyRequiresLabelReprint: store.guestReplyRequiresLabelReprint,
                        acceptConnectorDiff: { sourceEventID in
                            store.acceptConnectorDiff(sourceEventID)
                        },
                        rejectConnectorDiff: { sourceEventID in
                            store.rejectConnectorDiff(sourceEventID)
                        },
                        completeSpecialPrep: { id in
                            store.completeSpecialPrepTask(id)
                        },
                        skipSpecialPrep: { id in
                            store.skipSpecialPrepTask(id)
                        },
                        sendGuestMessages: {
                            store.sendGuestConfirmationMessages()
                        },
                        printAllergenLabels: {
                            store.printAllergenLabels()
                        },
                        recordGuestReplyChange: {
                            store.recordLatestGuestReplyChange()
                        },
                        completeGuestReplyRecheck: {
                            store.completeGuestReplyRecheck()
                        },
                        openDirectBooking: {
                            isDirectBookingPresented = true
                        },
                        openServicePass: {
                            isServicePassPresented = true
                        },
                        apply: {
                            if store.reservationHubApplyCount > 0 {
                                done()
                            } else {
                                store.applyReservationHubToPrep()
                            }
                        }
                    )
                    .frame(width: PrepFlowMetric.railWidth)
                }
            }
            .padding(PrepFlowSpacing.md)
        }
        .foregroundStyle(PrepFlowColor.ink)
        .presentationDetents([.large])
        .sheet(isPresented: $isDirectBookingPresented) {
            DirectBookingOpsSheet(store: store) {
                isDirectBookingPresented = false
            }
        }
        .sheet(isPresented: $isServicePassPresented) {
            ServicePassOpsSheet(store: store) {
                isServicePassPresented = false
            }
        }
    }

    private var hasDuplicateCandidate: Bool {
        store.service.reservations.contains { $0.partyName.contains("鈴木") && $0.id.contains("tablecheck") }
    }

    private var diffCovers: Int {
        (store.reservationDiffSummary?.addedCovers ?? 0) - (store.reservationDiffSummary?.cancelledCovers ?? 0)
    }

    private func sourceCovers(_ source: ReservationSourceKind) -> Int {
        store.service.reservations
            .filter { source.matches($0) }
            .reduce(0) { $0 + $1.covers }
    }
}

private enum ReservationSourceKind {
    case direct
    case tablecheck
    case manual

    func matches(_ reservation: ManualReservation) -> Bool {
        switch self {
        case .direct:
            reservation.id.contains("direct")
        case .tablecheck:
            reservation.id.contains("tablecheck")
        case .manual:
            !reservation.id.contains("direct") && !reservation.id.contains("tablecheck")
        }
    }
}

// 正本: design/p2-wireframe-reservation-hub-liquidglass.png
private struct ReservationHubTopBar: View {
    let close: () -> Void
    let resync: () -> Void

    var body: some View {
        GlassEffectContainer {
            HStack(spacing: PrepFlowSpacing.md) {
                VStack(alignment: .leading, spacing: PrepFlowSpacing.xxs) {
                    Text("予約ハブ")
                        .font(PrepFlowFont.topTitle)
                    Text("鮨 はやし ・ 6/11(木) 夜 ・ 全ソース合算")
                        .font(PrepFlowFont.topSubtitle)
                        .foregroundStyle(PrepFlowColor.g2)
                }

                Spacer()

                Button("閉じる", action: close)
                    .buttonStyle(ReservationGlassButtonStyle())
                Button("再同期", action: resync)
                    .buttonStyle(ReservationGlassButtonStyle())

                VStack(alignment: .leading, spacing: PrepFlowSpacing.xxs) {
                    Text("SERVICE 18:00")
                        .font(PrepFlowFont.countdownLabel)
                    Text("T-2:48")
                        .font(PrepFlowFont.countdownValue)
                        .monospacedDigit()
                }
                .foregroundStyle(PrepFlowColor.time) // time-use: reservation hub countdown
                .padding(.horizontal, PrepFlowSpacing.md)
                .padding(.vertical, PrepFlowSpacing.xs)
                .background(PrepFlowColor.time.opacity(PrepFlowOpacity.timeGlass)) // time-use: reservation hub countdown tint
                .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous)
                        .stroke(PrepFlowColor.time.opacity(PrepFlowOpacity.timeStroke), lineWidth: PrepFlowMetric.lineWidth) // time-use: countdown island stroke
                }
                .glassEffect()
            }
            .padding(.horizontal, PrepFlowSpacing.lg)
            .frame(height: PrepFlowMetric.topBarHeight)
            .background(PrepFlowColor.white.opacity(PrepFlowOpacity.glass))
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.xxl, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: PrepFlowRadius.xxl, style: .continuous)
                    .stroke(PrepFlowColor.white.opacity(PrepFlowOpacity.glassStroke), lineWidth: PrepFlowMetric.lineWidth)
            }
            .shadow(color: PrepFlowColor.ink.opacity(PrepFlowOpacity.glassShadow), radius: PrepFlowSpacing.lg, y: PrepFlowSpacing.sm)
            .glassEffect()
        }
    }
}

// 正本: design/p2-wireframe-reservation-hub-liquidglass.png
private struct ReservationSourceChip: View {
    let title: String
    let value: Int
    let marker: String
    let isDirect: Bool

    var body: some View {
        GlassEffectContainer {
            HStack(spacing: PrepFlowSpacing.sm) {
                Text(marker)
                    .font(PrepFlowFont.smallBold)
                    .foregroundStyle(isDirect ? PrepFlowColor.white : PrepFlowColor.g2)
                    .frame(width: PrepFlowSpacing.xl, height: PrepFlowSpacing.xl)
                    .background(isDirect ? PrepFlowColor.ink : PrepFlowColor.ink.opacity(PrepFlowOpacity.selection))
                    .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))

                VStack(alignment: .leading, spacing: PrepFlowSpacing.xxs) {
                    Text("\(value)名")
                        .font(PrepFlowFont.railTitle)
                        .monospacedDigit()
                    Text(title)
                        .font(PrepFlowFont.railMeta)
                        .foregroundStyle(PrepFlowColor.g2)
                }

                Spacer()
            }
            .padding(PrepFlowSpacing.sm)
            .background(PrepFlowColor.white.opacity(PrepFlowOpacity.glass))
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous)
                    .stroke(PrepFlowColor.white.opacity(PrepFlowOpacity.glassStroke), lineWidth: PrepFlowMetric.lineWidth)
            }
            .glassEffect()
        }
    }
}

// 正本: design/p2-wireframe-reservation-hub-liquidglass.png
private struct ReservationHubList: View {
    let reservations: [ManualReservation]
    let hasDuplicate: Bool
    let duplicateDecision: String?
    let assignedCourses: [String: String]
    let keepSeparate: () -> Void
    let mergeDuplicate: () -> Void
    let assignCourse: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.sm) {
            ReservationDuplicateAlert(
                hasDuplicate: hasDuplicate,
                duplicateDecision: duplicateDecision,
                keepSeparate: keepSeparate,
                mergeDuplicate: mergeDuplicate
            )

            HStack {
                Text("本日の予約（合算 \(reservations.reduce(0) { $0 + $1.covers })名 / \(reservations.count)件）")
                    .font(PrepFlowFont.sectionTitle)
                Spacer()
                Text("時刻順")
                    .font(PrepFlowFont.railMeta)
                    .foregroundStyle(PrepFlowColor.g2)
            }

            ScrollView {
                VStack(spacing: PrepFlowSpacing.xs) {
                    ForEach(reservations) { reservation in
                        ReservationHubRow(
                            reservation: reservation,
                            isDuplicate: hasDuplicate && reservation.partyName.contains("鈴木"),
                            assignedCourse: assignedCourses[reservation.id],
                            assignCourse: {
                                assignCourse(reservation.id)
                            }
                        )
                    }
                }
            }
        }
        .padding(.trailing, PrepFlowSpacing.md)
    }
}

// 正本: design/p2-wireframe-reservation-hub-liquidglass.png
private struct ReservationDuplicateAlert: View {
    let hasDuplicate: Bool
    let duplicateDecision: String?
    let keepSeparate: () -> Void
    let mergeDuplicate: () -> Void

    var body: some View {
        HStack(spacing: PrepFlowSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(PrepFlowFont.icon)
                .foregroundStyle(PrepFlowColor.white)
                .frame(width: PrepFlowMetric.checkSize, height: PrepFlowMetric.checkSize)
                .background(PrepFlowColor.time) // time-use: urgent duplicate reservation alert
                .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))

            VStack(alignment: .leading, spacing: PrepFlowSpacing.xxs) {
                Text(alertTitle)
                    .font(PrepFlowFont.smallBold)
                    .foregroundStyle(PrepFlowColor.time) // time-use: urgent reservation diff alert
                Text(alertDetail)
                    .font(PrepFlowFont.railMeta)
                    .foregroundStyle(PrepFlowColor.time) // time-use: urgent reservation diff alert detail
            }

            Spacer()

            Button("別々で残す", action: keepSeparate)
                .buttonStyle(ReservationSecondaryButtonStyle())
                .disabled(!hasDuplicate || duplicateDecision == "kept_separate")
            Button("1件に統合", action: mergeDuplicate)
                .buttonStyle(ReservationAlertButtonStyle())
                .disabled(!hasDuplicate || duplicateDecision == "kept_separate")
        }
        .padding(PrepFlowSpacing.sm)
        .background(PrepFlowColor.time.opacity(PrepFlowOpacity.timeSoft)) // time-use: urgent duplicate alert background
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous)
                .stroke(PrepFlowColor.time.opacity(PrepFlowOpacity.timeStroke), lineWidth: PrepFlowMetric.lineWidth) // time-use: urgent duplicate alert border
        }
    }

    private var alertTitle: String {
        if duplicateDecision == "kept_separate" {
            return "別々の予約として確定"
        }
        return hasDuplicate ? "重複の疑い — 18:00 / 4名「鈴木」" : "再同期で外部予約の差分を確認"
    }

    private var alertDetail: String {
        if duplicateDecision == "kept_separate" {
            return "手入力と TableCheck を二重ではなく別予約として扱います。"
        }
        return hasDuplicate
            ? "手入力と TableCheck に同条件。二重計上を防ぐため確認してください。"
            : "TableCheck mock を取り込み、仕込み影響を右パネルに出します。"
    }
}

// 正本: design/p2-wireframe-reservation-hub-liquidglass.png
private struct ReservationHubRow: View {
    let reservation: ManualReservation
    let isDuplicate: Bool
    let assignedCourse: String?
    let assignCourse: () -> Void

    var body: some View {
        HStack(spacing: PrepFlowSpacing.sm) {
            Text(reservation.visitTime)
                .font(PrepFlowFont.railTitle)
                .monospacedDigit()
                .frame(width: PrepFlowMetric.actionButtonHeight, alignment: .leading)

            Text(sourceLabel)
                .font(PrepFlowFont.countdownLabel)
                .foregroundStyle(sourceIsDirect ? PrepFlowColor.white : PrepFlowColor.g2)
                .padding(.horizontal, PrepFlowSpacing.sm)
                .padding(.vertical, PrepFlowSpacing.xxs)
                .background(sourceIsDirect ? PrepFlowColor.ink : PrepFlowColor.g5)
                .clipShape(Capsule(style: .continuous))

            VStack(alignment: .leading, spacing: PrepFlowSpacing.xxs) {
                Text(reservation.partyName)
                    .font(PrepFlowFont.bodyBold)
                Text(reservation.note)
                    .font(PrepFlowFont.railMeta)
                    .foregroundStyle(isDuplicate ? PrepFlowColor.time : PrepFlowColor.g2) // time-use: duplicate reservation row note
            }

            Spacer()

            Text(courseLabel)
                .font(PrepFlowFont.railMeta)
                .foregroundStyle(courseNeedsAssignment ? PrepFlowColor.time : PrepFlowColor.ink) // time-use: course deadline before prep apply
                .padding(.horizontal, PrepFlowSpacing.sm)
                .padding(.vertical, PrepFlowSpacing.xs)
                .background(courseNeedsAssignment ? PrepFlowColor.time.opacity(PrepFlowOpacity.timeNow) : PrepFlowColor.g5) // time-use: course deadline chip
                .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))

            if courseNeedsAssignment {
                Button("割当", action: assignCourse)
                    .buttonStyle(ReservationAlertButtonStyle())
            }

            Text("\(reservation.covers)名")
                .font(PrepFlowFont.railTitle)
                .monospacedDigit()
                .frame(width: PrepFlowMetric.actionButtonHeight, alignment: .trailing)
        }
        .padding(PrepFlowSpacing.sm)
        .background(isDuplicate ? PrepFlowColor.time.opacity(PrepFlowOpacity.timeNow) : PrepFlowColor.white) // time-use: duplicate reservation row background
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous)
                .stroke(
                    isDuplicate ? PrepFlowColor.time.opacity(PrepFlowOpacity.timeStroke) : PrepFlowColor.g4, // time-use: duplicate reservation row stroke
                    lineWidth: PrepFlowMetric.lineWidth
                ) // time-use: duplicate reservation row border
        }
    }

    private var sourceIsDirect: Bool {
        reservation.id.contains("direct")
    }

    private var sourceLabel: String {
        if reservation.id.contains("direct") {
            return "Direct"
        }
        if reservation.id.contains("tablecheck") {
            return "Table"
        }
        return "手入力"
    }

    private var courseNeedsAssignment: Bool {
        reservation.id.contains("tablecheck") && assignedCourse == nil
    }

    private var courseLabel: String {
        if courseNeedsAssignment {
            return "コース未確定"
        }
        if assignedCourse != nil {
            return "割当済み"
        }
        return "おまかせ"
    }
}

// 正本: design/p2-wireframe-reservation-hub-liquidglass.png
private struct ReservationHubApplyPanel: View {
    let covers: Int
    let diff: ReservationDiffSummary?
    let plan: PlanDiff?
    let unassignedCovers: Int
    let needsDuplicateReview: Bool
    let canApply: Bool
    let applyCount: Int
    let appliedAt: String?
    let connectorItems: [ConnectorDiffReviewItem]
    let connectorSummary: String
    let specialPrepTasks: [SpecialPrepTask]
    let allergenLabels: [AllergenLabel]
    let guestMessages: [GuestMessage]
    let specialPrepLastAction: String
    let guestMessageLastAction: String
    let allergenLabelPrintCount: Int
    let guestReplyRecheckCount: Int
    let guestReplyRecheckLastAction: String
    let guestReplyRequiresLabelReprint: Bool
    let acceptConnectorDiff: (String) -> Void
    let rejectConnectorDiff: (String) -> Void
    let completeSpecialPrep: (String) -> Void
    let skipSpecialPrep: (String) -> Void
    let sendGuestMessages: () -> Void
    let printAllergenLabels: () -> Void
    let recordGuestReplyChange: () -> Void
    let completeGuestReplyRecheck: () -> Void
    let openDirectBooking: () -> Void
    let openServicePass: () -> Void
    let apply: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.sm) {
            Text("仕込みへ反映（確定）")
                .font(PrepFlowFont.sectionTitle)
            Text("合算後の人数と差分。重複を1件にすると自動で更新されます。")
                .font(PrepFlowFont.railMeta)
                .foregroundStyle(PrepFlowColor.g2)

            ReservationPanelRow(title: "おまかせ握り", detail: "手入力 / Direct / TableCheck", value: "\(covers)")
            ReservationPanelRow(title: "追加差分", detail: "新規・人数増", value: "+\(diff?.addedCovers ?? 0)")
            ReservationPanelRow(title: "取消差分", detail: "キャンセル・統合", value: "-\(diff?.cancelledCovers ?? 0)")
            ReservationPanelRow(title: "追加仕込み", detail: "煮切り換算", value: "\(Int(plan?.added.first?.qty ?? 0))ml")
            ReservationPanelRow(title: "コース未確定", detail: "割当前の人数", value: "\(unassignedCovers)")
            ReservationPanelRow(title: "反映ゲート", detail: gateDetail, value: canApply ? "OK" : "要確認")

            ReservationConnectorReviewPanel(
                items: connectorItems,
                summary: connectorSummary,
                accept: acceptConnectorDiff,
                reject: rejectConnectorDiff
            )

            ReservationOmotenashiPanel(
                specialPrepTasks: specialPrepTasks,
                allergenLabels: allergenLabels,
                guestMessages: guestMessages,
                specialPrepLastAction: specialPrepLastAction,
                guestMessageLastAction: guestMessageLastAction,
                allergenLabelPrintCount: allergenLabelPrintCount,
                guestReplyRecheckCount: guestReplyRecheckCount,
                guestReplyRecheckLastAction: guestReplyRecheckLastAction,
                guestReplyRequiresLabelReprint: guestReplyRequiresLabelReprint,
                completeSpecialPrep: completeSpecialPrep,
                skipSpecialPrep: skipSpecialPrep,
                sendGuestMessages: sendGuestMessages,
                printAllergenLabels: printAllergenLabels,
                recordGuestReplyChange: recordGuestReplyChange,
                completeGuestReplyRecheck: completeGuestReplyRecheck
            )

            Spacer()

            HStack {
                Text("合計")
                    .font(PrepFlowFont.sectionTitle)
                Spacer()
                Text("\(covers)名")
                    .font(PrepFlowFont.iconLarge)
                    .monospacedDigit()
            }

            if applyCount > 0 {
                ReservationAppliedStatus(appliedAt: appliedAt)
            }

            ReservationHubGateStatus(
                unassignedCovers: unassignedCovers,
                needsDuplicateReview: needsDuplicateReview,
                canApply: canApply
            )

            Button(applyCount > 0 ? "ボードへ戻る" : "仕込みに反映", action: apply)
                .buttonStyle(ReservationPrimaryButtonStyle(isEnabled: applyCount > 0 || canApply))
                .disabled(applyCount == 0 && !canApply)

            Text("数量算出・逆算タイムラインが更新されます（FR-03/06）")
                .font(PrepFlowFont.railMeta)
                .foregroundStyle(PrepFlowColor.g2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            HStack(spacing: PrepFlowSpacing.sm) {
                Button("Direct受付", action: openDirectBooking)
                    .buttonStyle(ReservationSecondaryWideButtonStyle())
                Button("パス同期", action: openServicePass)
                    .buttonStyle(ReservationSecondaryWideButtonStyle())
            }
        }
        .padding(PrepFlowSpacing.md)
        .background(PrepFlowColor.white)
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous)
                .stroke(PrepFlowColor.g4, lineWidth: PrepFlowMetric.lineWidth)
        }
    }

    private var gateDetail: String {
        if needsDuplicateReview {
            return "重複確認待ち"
        }
        if unassignedCovers > 0 {
            return "コース割当待ち"
        }
        return "反映可能"
    }
}

// 正本: design/p2-wireframe-reservation-hub-liquidglass.png
private struct ReservationAppliedStatus: View {
    let appliedAt: String?

    var body: some View {
        HStack(spacing: PrepFlowSpacing.sm) {
            Text("反映済み")
                .font(PrepFlowFont.smallBold)
            Spacer()
            Text(appliedAt ?? "ローカル保存済み")
                .font(PrepFlowFont.railMeta)
                .foregroundStyle(PrepFlowColor.g2)
        }
        .padding(PrepFlowSpacing.sm)
        .background(PrepFlowColor.g5)
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
    }
}

// 正本: design/p2-wireframe-reservation-hub-liquidglass.png
private struct ReservationHubGateStatus: View {
    let unassignedCovers: Int
    let needsDuplicateReview: Bool
    let canApply: Bool

    var body: some View {
        HStack(spacing: PrepFlowSpacing.sm) {
            Text(statusTitle)
                .font(PrepFlowFont.smallBold)
                .foregroundStyle(canApply ? PrepFlowColor.ink : PrepFlowColor.time) // time-use: reservation apply gate blocking
            Spacer()
            Text(statusDetail)
                .font(PrepFlowFont.railMeta)
                .foregroundStyle(canApply ? PrepFlowColor.g2 : PrepFlowColor.time) // time-use: reservation apply gate blocking detail
        }
        .padding(PrepFlowSpacing.sm)
        .background(canApply ? PrepFlowColor.g5 : PrepFlowColor.time.opacity(PrepFlowOpacity.timeSoft)) // time-use: reservation apply gate blocking background
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous)
                .stroke(
                    canApply ? PrepFlowColor.g4 : PrepFlowColor.time.opacity(PrepFlowOpacity.timeStroke), // time-use: reservation apply gate blocking stroke
                    lineWidth: PrepFlowMetric.lineWidth
                ) // time-use: reservation apply gate border
        }
    }

    private var statusTitle: String {
        canApply ? "反映可能" : "反映前の確認あり"
    }

    private var statusDetail: String {
        if needsDuplicateReview {
            return "重複を統合または別々で確定"
        }
        if unassignedCovers > 0 {
            return "未確定 \(unassignedCovers)名"
        }
        return "数量更新できます"
    }
}

// 正本: design/p2-wireframe-reservation-hub-liquidglass.png
private struct ReservationPanelRow: View {
    let title: String
    let detail: String
    let value: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: PrepFlowSpacing.xxs) {
                Text(title)
                    .font(PrepFlowFont.bodyBold)
                Text(detail)
                    .font(PrepFlowFont.railMeta)
                    .foregroundStyle(PrepFlowColor.g2)
            }
            Spacer()
            Text(value)
                .font(PrepFlowFont.railTitle)
                .monospacedDigit()
        }
        .padding(.vertical, PrepFlowSpacing.xs)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(PrepFlowColor.g4)
                .frame(height: PrepFlowMetric.lineWidth)
        }
    }
}

// 正本: design/p2-wireframe-reservation-hub-liquidglass.png
// 正本: design/flow-vertical-slice-reservations.png
private struct ReservationConnectorReviewPanel: View {
    let items: [ConnectorDiffReviewItem]
    let summary: String
    let accept: (String) -> Void
    let reject: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.xs) {
            HStack {
                VStack(alignment: .leading, spacing: PrepFlowSpacing.xxs) {
                    Text("外部差分承認")
                        .font(PrepFlowFont.bodyBold)
                    Text(summary)
                        .font(PrepFlowFont.railMeta)
                        .foregroundStyle(PrepFlowColor.g2)
                }
                Spacer()
                Text("\(pendingCount)")
                    .font(PrepFlowFont.railTitle)
                    .monospacedDigit()
            }

            if items.isEmpty {
                Text("再同期すると TableCheck の変更をここで承認できます。")
                    .font(PrepFlowFont.railMeta)
                    .foregroundStyle(PrepFlowColor.g2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(PrepFlowSpacing.sm)
                    .background(PrepFlowColor.g5)
                    .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
            } else {
                ForEach(items.prefix(3)) { item in
                    ReservationConnectorReviewRow(item: item, accept: accept, reject: reject)
                }
            }
        }
        .padding(PrepFlowSpacing.sm)
        .background(PrepFlowColor.g5)
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous)
                .stroke(PrepFlowColor.g4, lineWidth: PrepFlowMetric.lineWidth)
        }
    }

    private var pendingCount: Int {
        items.count { $0.state == "未処理" }
    }
}

// 正本: design/p2-wireframe-reservation-hub-liquidglass.png
private struct ReservationConnectorReviewRow: View {
    let item: ConnectorDiffReviewItem
    let accept: (String) -> Void
    let reject: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.xs) {
            HStack(alignment: .top, spacing: PrepFlowSpacing.xs) {
                VStack(alignment: .leading, spacing: PrepFlowSpacing.xxs) {
                    Text("\(item.visitTime) \(item.partyName)")
                        .font(PrepFlowFont.smallBold)
                    Text("\(item.sourceLabel) ・ \(item.course)")
                        .font(PrepFlowFont.railMeta)
                        .foregroundStyle(PrepFlowColor.g2)
                    Text(item.prepNote)
                        .font(PrepFlowFont.railMeta)
                        .foregroundStyle(PrepFlowColor.g2)
                        .lineLimit(1)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: PrepFlowSpacing.xxs) {
                    Text(item.diffLabel)
                        .font(PrepFlowFont.railTitle)
                        .monospacedDigit()
                    Text(item.state)
                        .font(PrepFlowFont.countdownLabel)
                        .foregroundStyle(item.state == "未処理" ? PrepFlowColor.time : PrepFlowColor.g2) // time-use: connector diff pending before service
                }
            }

            if item.state == "未処理" {
                HStack(spacing: PrepFlowSpacing.xs) {
                    Button("却下") {
                        reject(item.id)
                    }
                    .buttonStyle(ReservationReviewButtonStyle(isPrimary: false))

                    Button("承認して反映") {
                        accept(item.id)
                    }
                    .buttonStyle(ReservationReviewButtonStyle(isPrimary: true))
                }
            }
        }
        .padding(PrepFlowSpacing.xs)
        .background(PrepFlowColor.white)
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous)
                .stroke(PrepFlowColor.g4, lineWidth: PrepFlowMetric.lineWidth)
        }
    }
}

private struct ReservationReviewButtonStyle: ButtonStyle {
    let isPrimary: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PrepFlowFont.smallBold)
            .foregroundStyle(isPrimary ? PrepFlowColor.white : PrepFlowColor.ink)
            .frame(maxWidth: .infinity)
            .frame(height: PrepFlowMetric.catalogFieldHeight)
            .background(isPrimary ? PrepFlowColor.ink : PrepFlowColor.g5)
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
            .opacity(configuration.isPressed ? PrepFlowOpacity.pressed : PrepFlowOpacity.solid)
    }
}

private struct ReservationGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PrepFlowFont.smallBold)
            .foregroundStyle(PrepFlowColor.ink)
            .frame(height: PrepFlowMetric.catalogFieldHeight)
            .padding(.horizontal, PrepFlowSpacing.md)
            .background(PrepFlowColor.white.opacity(PrepFlowOpacity.glass))
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
            .opacity(configuration.isPressed ? PrepFlowOpacity.pressed : PrepFlowOpacity.solid)
    }
}

private struct ReservationSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PrepFlowFont.smallBold)
            .foregroundStyle(PrepFlowColor.time) // time-use: duplicate alert secondary action
            .frame(height: PrepFlowMetric.catalogFieldHeight)
            .padding(.horizontal, PrepFlowSpacing.sm)
            .background(PrepFlowColor.white)
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
            .opacity(configuration.isPressed ? PrepFlowOpacity.pressed : PrepFlowOpacity.solid)
    }
}

private struct ReservationAlertButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PrepFlowFont.smallBold)
            .foregroundStyle(PrepFlowColor.white)
            .frame(height: PrepFlowMetric.catalogFieldHeight)
            .padding(.horizontal, PrepFlowSpacing.sm)
            .background(PrepFlowColor.time) // time-use: urgent reservation action before prep deadline
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
            .opacity(configuration.isPressed ? PrepFlowOpacity.pressed : PrepFlowOpacity.solid)
    }
}

private struct ReservationPrimaryButtonStyle: ButtonStyle {
    let isEnabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PrepFlowFont.action)
            .foregroundStyle(isEnabled ? PrepFlowColor.white : PrepFlowColor.g2)
            .frame(maxWidth: .infinity)
            .frame(height: PrepFlowMetric.actionButtonHeight)
            .background(isEnabled ? PrepFlowColor.ink : PrepFlowColor.g4)
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous))
            .opacity(configuration.isPressed ? PrepFlowOpacity.pressed : PrepFlowOpacity.solid)
    }
}

private struct ReservationSecondaryWideButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PrepFlowFont.smallBold)
            .foregroundStyle(PrepFlowColor.ink)
            .frame(maxWidth: .infinity)
            .frame(height: PrepFlowMetric.catalogFieldHeight)
            .background(PrepFlowColor.g5)
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
            .opacity(configuration.isPressed ? PrepFlowOpacity.pressed : PrepFlowOpacity.solid)
    }
}
