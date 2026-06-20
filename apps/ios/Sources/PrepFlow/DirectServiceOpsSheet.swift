// 正本: design/p3-wireframe-direct-booking.png
// 正本: design/p4-wireframe-passview.png
// swiftlint:disable file_length
import DesignTokens
import Engine
import SwiftUI

// 正本: design/p3-wireframe-direct-booking.png
struct DirectBookingOpsSheet: View {
    @ObservedObject var store: BoardStore
    @State private var covers = 2
    @State private var note = "甲殻類NG / VIP:gold / 記念日"
    @State private var allotment = 1

    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.lg) {
            DirectOpsHeader(title: "PrepFlow Direct", subtitle: "直販予約 → 枠判定 → 仕込み差分")

            HStack(alignment: .top, spacing: PrepFlowSpacing.md) {
                DirectBrandPanel()
                VStack(alignment: .leading, spacing: PrepFlowSpacing.md) {
                    DirectStepCard(number: "1", title: "日付・時間", detail: "6/11(木) 18:00 / 直販枠")
                    DirectPartyCard(covers: $covers)
                    DirectCourseCard()
                    DirectNoteCard(note: $note)
                    DirectPaymentCard(covers: covers)
                }
            }

            DirectOpsStatus(store: store)

            HStack(spacing: PrepFlowSpacing.md) {
                Button("枠判定") {
                    store.evaluateDirectAllotment(directBooking, allottedCovers: allotment)
                }
                .buttonStyle(OpsSecondaryButtonStyle())

                Button("直販予約を確定") {
                    store.acceptDirectBooking(directBooking, depositRequired: true)
                }
                .buttonStyle(OpsPrimaryButtonStyle())

                Button("キャンセル") {
                    store.cancelDirectBooking(directBooking.id)
                }
                .buttonStyle(OpsSecondaryButtonStyle())

                Button("ゲスト情報を厨房へ") {
                    store.replayGuestSignals(vipReservation, seatRef: "卓3", language: "ja")
                }
                .buttonStyle(OpsSecondaryButtonStyle())
            }
        }
        .padding(PrepFlowSpacing.xl)
        .background(PrepFlowColor.g5)
        .foregroundStyle(PrepFlowColor.ink)
        .presentationDetents([.large])
    }

    private var directBooking: DirectBooking {
        DirectBooking(
            id: "direct-ops",
            visitTime: "18:00",
            covers: covers,
            course: "course-omakase",
            guestName: "Direct Guest",
            guestNote: note
        )
    }

    private var vipReservation: NormalizedReservation {
        NormalizedReservation(
            id: "reservation-direct-ops-vip",
            source: "direct",
            externalID: directBooking.id,
            visitTime: directBooking.visitTime,
            covers: directBooking.covers,
            course: directBooking.course,
            partyName: directBooking.guestName,
            status: "confirmed",
            prepNote: note
        )
    }
}

// 正本: design/p4-wireframe-passview.png
struct ServicePassOpsSheet: View {
    @ObservedObject var store: BoardStore
    @State private var mode: ServicePassMode = .pass

    var body: some View {
        VStack(spacing: PrepFlowSpacing.md) {
            ServicePassTopBar(mode: $mode)
            ServiceFireBanner(
                fire: {
                    store.acceptIncomingServiceFire()
                },
                hold: {
                    store.holdIncomingServiceFire()
                }
            )

            HStack(alignment: .top, spacing: PrepFlowSpacing.md) {
                switch mode {
                case .remaining:
                    ServiceRemainingBoard(store: store)
                case .pass:
                    ServicePassMatrix(events: store.serviceSyncEventTimeline, passState: store.passState)
                case .staff:
                    ServicePassStaffHandoff(store: store)
                }
                ServiceSyncPanel(store: store)
                    .frame(width: PrepFlowMetric.railWidth)
            }
        }
        .padding(PrepFlowSpacing.md)
        .background(PrepFlowColor.g5)
        .foregroundStyle(PrepFlowColor.ink)
        .presentationDetents([.large])
    }
}

private enum ServicePassMode: String, CaseIterable, Identifiable {
    case remaining = "残数"
    case pass = "パス"
    case staff = "担当"

    var id: String {
        rawValue
    }
}

// 正本: design/p3-wireframe-direct-booking.png
private struct DirectOpsHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        GlassEffectContainer {
            HStack {
                VStack(alignment: .leading, spacing: PrepFlowSpacing.xxs) {
                    Text(title)
                        .font(PrepFlowFont.topTitle)
                    Text(subtitle)
                        .font(PrepFlowFont.topSubtitle)
                        .foregroundStyle(PrepFlowColor.g2)
                }
                Spacer()
                Text("公式予約")
                    .font(PrepFlowFont.smallBold)
                    .foregroundStyle(PrepFlowColor.white)
                    .padding(.horizontal, PrepFlowSpacing.md)
                    .frame(height: PrepFlowMetric.catalogFieldHeight)
                    .background(PrepFlowColor.ink)
                    .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
            }
            .padding(.horizontal, PrepFlowSpacing.lg)
            .frame(height: PrepFlowMetric.topBarHeight)
            .background(PrepFlowColor.white.opacity(PrepFlowOpacity.glass))
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.xxl, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: PrepFlowRadius.xxl, style: .continuous)
                    .stroke(PrepFlowColor.white.opacity(PrepFlowOpacity.glassStroke), lineWidth: PrepFlowMetric.lineWidth)
            }
            .glassEffect()
        }
    }
}

// 正本: design/p3-wireframe-direct-booking.png
private struct DirectBrandPanel: View {
    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.md) {
            Text("鮨 はやし")
                .font(PrepFlowFont.focusTitle)
            Text("東京・西麻布 / おまかせコース / カウンター10席")
                .font(PrepFlowFont.body)
                .foregroundStyle(PrepFlowColor.g2)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: PrepFlowSpacing.sm) {
                ForEach(0 ..< DirectOpsLayout.tileCount, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous)
                        .fill(PrepFlowColor.g4)
                        .aspectRatio(PrepFlowRatio.square, contentMode: .fit)
                }
            }
            Text("アレルギー等は厨房に直接共有されます。法的な完全判定ではなく、当日確認の補助情報として扱います。")
                .font(PrepFlowFont.railMeta)
                .foregroundStyle(PrepFlowColor.g2)
                .padding(PrepFlowSpacing.sm)
                .background(PrepFlowColor.white)
                .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous))
        }
        .padding(PrepFlowSpacing.md)
        .frame(width: PrepFlowMetric.railWidth)
        .background(PrepFlowColor.white)
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous)
                .stroke(PrepFlowColor.g4, lineWidth: PrepFlowMetric.lineWidth)
        }
    }
}

// 正本: design/p3-wireframe-direct-booking.png
private struct DirectStepCard: View {
    let number: String
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: PrepFlowSpacing.sm) {
            Text(number)
                .font(PrepFlowFont.smallBold)
                .foregroundStyle(PrepFlowColor.white)
                .frame(width: PrepFlowMetric.checkSize, height: PrepFlowMetric.checkSize)
                .background(PrepFlowColor.ink)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: PrepFlowSpacing.xxs) {
                Text(title)
                    .font(PrepFlowFont.sectionTitle)
                Text(detail)
                    .font(PrepFlowFont.railMeta)
                    .foregroundStyle(PrepFlowColor.g2)
            }
            Spacer()
        }
        .padding(PrepFlowSpacing.sm)
        .background(PrepFlowColor.white)
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous))
    }
}

// 正本: design/p3-wireframe-direct-booking.png
private struct DirectPartyCard: View {
    @Binding var covers: Int

    var body: some View {
        DirectStepCard(number: "2", title: "人数", detail: "\(covers)名")
            .overlay(alignment: .trailing) {
                HStack(spacing: PrepFlowSpacing.xs) {
                    Button("−") {
                        covers = max(1, covers - 1)
                    }
                    .buttonStyle(OpsMiniButtonStyle())
                    Button("+") {
                        covers += 1
                    }
                    .buttonStyle(OpsMiniButtonStyle())
                }
                .padding(.trailing, PrepFlowSpacing.sm)
            }
    }
}

// 正本: design/p3-wireframe-direct-booking.png
private struct DirectCourseCard: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: PrepFlowSpacing.xxs) {
                Text("おまかせ握り")
                    .font(PrepFlowFont.bodyBold)
                Text("つまみ＋握り 15貫＋椀＋水菓子")
                    .font(PrepFlowFont.railMeta)
                    .foregroundStyle(PrepFlowColor.g2)
            }
            Spacer()
            Text("¥16,500")
                .font(PrepFlowFont.railTitle)
                .monospacedDigit()
        }
        .padding(PrepFlowSpacing.sm)
        .background(PrepFlowColor.white)
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous)
                .stroke(PrepFlowColor.ink, lineWidth: PrepFlowMetric.lineWidth)
        }
    }
}

// 正本: design/p3-wireframe-direct-booking.png
private struct DirectNoteCard: View {
    @Binding var note: String

    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.sm) {
            Text("アレルギー・苦手")
                .font(PrepFlowFont.sectionTitle)
            TextField("厨房への補助情報", text: $note)
                .font(PrepFlowFont.body)
                .textFieldStyle(.plain)
                .padding(PrepFlowSpacing.sm)
                .background(PrepFlowColor.g5)
                .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
            Text("最終可否は当日スタッフが確認します。")
                .font(PrepFlowFont.railMeta)
                .foregroundStyle(PrepFlowColor.g2)
        }
        .padding(PrepFlowSpacing.sm)
        .background(PrepFlowColor.white)
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous))
    }
}

// 正本: design/p3-wireframe-direct-booking.png
private struct DirectPaymentCard: View {
    let covers: Int

    var body: some View {
        VStack(spacing: PrepFlowSpacing.xs) {
            DirectPaymentRow(title: "デポジット", value: "¥\(covers * DirectOpsLayout.depositYen)")
            DirectPaymentRow(title: "来店時残額", value: "¥\(covers * DirectOpsLayout.remainingYen)")
        }
        .padding(PrepFlowSpacing.sm)
        .background(PrepFlowColor.white)
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous))
    }
}

// 正本: design/p3-wireframe-direct-booking.png
private struct DirectPaymentRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(PrepFlowFont.railMeta)
                .foregroundStyle(PrepFlowColor.g2)
            Spacer()
            Text(value)
                .font(PrepFlowFont.smallBold)
                .monospacedDigit()
        }
    }
}

// 正本: design/p3-wireframe-direct-booking.png
private struct DirectOpsStatus: View {
    @ObservedObject var store: BoardStore

    var body: some View {
        HStack(spacing: PrepFlowSpacing.sm) {
            OpsMetric(title: "Direct", value: directStatus)
            OpsMetric(title: "差分", value: "+\(store.reservationDiffSummary?.addedCovers ?? 0)")
            OpsMetric(title: "待ち", value: "\(store.latestDirectDecision?.waitlistCovers ?? 0)")
            OpsMetric(title: "席札", value: "\(store.passSeatFlags.count)")
            OpsMetric(title: "特別", value: "\(store.specialPrepTasks.count)")
            OpsMetric(title: "確認文", value: "\(store.guestMessages.count)")
        }
    }

    private var directStatus: String {
        store.latestDirectBooking?.status.rawValue ?? store.latestDirectDecision?.reason ?? "未判定"
    }
}

// 正本: design/p4-wireframe-passview.png
private struct ServicePassTopBar: View {
    @Binding var mode: ServicePassMode

    var body: some View {
        GlassEffectContainer {
            HStack {
                Text("パス")
                    .font(PrepFlowFont.smallBold)
                    .foregroundStyle(PrepFlowColor.white)
                    .padding(.horizontal, PrepFlowSpacing.md)
                    .frame(height: PrepFlowMetric.catalogFieldHeight)
                    .background(PrepFlowColor.time) // time-use: active service pass mode
                    .clipShape(Capsule(style: .continuous))
                VStack(alignment: .leading, spacing: PrepFlowSpacing.xxs) {
                    Text("サービス進行（卓×コース）")
                        .font(PrepFlowFont.topTitle)
                    Text("鮨 はやし ・ 6卓 / 14名")
                        .font(PrepFlowFont.topSubtitle)
                        .foregroundStyle(PrepFlowColor.g2)
                }
                Spacer()
                HStack(spacing: PrepFlowSpacing.xxs) {
                    ForEach(ServicePassMode.allCases) { candidate in
                        Button(candidate.rawValue) {
                            mode = candidate
                        }
                        .buttonStyle(ServicePassSegmentButtonStyle(isSelected: mode == candidate))
                    }
                }
                .padding(PrepFlowSpacing.xxs)
                .background(PrepFlowColor.g5)
                .clipShape(Capsule(style: .continuous))
                Spacer()
                Text("T+0:42")
                    .font(PrepFlowFont.countdownValue)
                    .foregroundStyle(PrepFlowColor.time) // time-use: service elapsed countdown
                    .monospacedDigit()
            }
            .padding(.horizontal, PrepFlowSpacing.lg)
            .frame(height: PrepFlowMetric.topBarHeight)
            .background(PrepFlowColor.white.opacity(PrepFlowOpacity.glass))
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.xxl, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: PrepFlowRadius.xxl, style: .continuous)
                    .stroke(PrepFlowColor.white.opacity(PrepFlowOpacity.glassStroke), lineWidth: PrepFlowMetric.lineWidth)
            }
            .glassEffect()
        }
    }
}

// 正本: design/p4-wireframe-passview.png
private struct ServiceFireBanner: View {
    let fire: () -> Void
    let hold: () -> Void

    var body: some View {
        HStack(spacing: PrepFlowSpacing.md) {
            Text("ハンディ")
                .font(PrepFlowFont.smallBold)
                .foregroundStyle(PrepFlowColor.time) // time-use: incoming fire source tag
                .padding(.horizontal, PrepFlowSpacing.sm)
                .frame(height: PrepFlowMetric.catalogFieldHeight)
                .background(PrepFlowColor.white)
                .clipShape(Capsule(style: .continuous))
            VStack(alignment: .leading, spacing: PrepFlowSpacing.xxs) {
                Text("卓3 ・ 握り ファイア")
                    .font(PrepFlowFont.railTitle)
                Text("ホールから着信")
                    .font(PrepFlowFont.railMeta)
            }
            Spacer()
            Button("ホールド", action: hold)
                .buttonStyle(OpsAlertOutlineButtonStyle())
            Button("キッチンへ反映", action: fire)
                .buttonStyle(OpsAlertButtonStyle())
        }
        .padding(PrepFlowSpacing.md)
        .background(PrepFlowColor.time) // time-use: incoming fire banner
        .foregroundStyle(PrepFlowColor.white)
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous))
    }
}

// 正本: design/p4-wireframe-passview.png
private struct ServicePassMatrix: View {
    let events: [ServiceSyncEvent]
    let passState: ServicePassState?

    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.sm) {
            HStack {
                Text("テーブル")
                    .font(PrepFlowFont.sectionTitle)
                Spacer()
                Text("先付 / 握り / 椀 / 水菓子")
                    .font(PrepFlowFont.railMeta)
                    .foregroundStyle(PrepFlowColor.g2)
            }
            ForEach(ServicePassRows.rows(events: events)) { row in
                HStack(spacing: PrepFlowSpacing.sm) {
                    VStack(alignment: .leading, spacing: PrepFlowSpacing.xxs) {
                        Text(row.table)
                            .font(PrepFlowFont.bodyBold)
                        Text(row.detail)
                            .font(PrepFlowFont.railMeta)
                            .foregroundStyle(PrepFlowColor.g2)
                    }
                    .frame(width: PrepFlowMetric.actionButtonHeight, alignment: .leading)
                    ForEach(row.states, id: \.self) { state in
                        ServicePassCell(state: state)
                    }
                }
            }
            if let passState {
                Text("FIRE \(passState.firedCovers)名 / HOLD \(passState.heldCovers)名 / \(passState.recommendation)")
                    .font(PrepFlowFont.railMeta)
                    .foregroundStyle(PrepFlowColor.g2)
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
}

// 正本: design/p4-wireframe-passview.png
private struct ServiceRemainingBoard: View {
    @ObservedObject var store: BoardStore

    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.sm) {
            HStack {
                Text("残数")
                    .font(PrepFlowFont.sectionTitle)
                Spacer()
                Text(store.servicePassLastAction)
                    .font(PrepFlowFont.railMeta)
                    .foregroundStyle(PrepFlowColor.g2)
            }

            HStack(spacing: PrepFlowSpacing.sm) {
                OpsMetric(title: "計画", value: "\(store.service.omakaseCovers)")
                OpsMetric(title: "残数", value: "\(store.serviceSyncState?.remainingCovers ?? store.service.omakaseCovers)")
                OpsMetric(title: "提供済", value: "\(store.serviceSyncState?.servedCovers ?? 0)")
                OpsMetric(title: "未送信", value: "\(store.servicePassPendingOfflineCount)")
            }

            VStack(alignment: .leading, spacing: PrepFlowSpacing.xs) {
                Text("直近イベント")
                    .font(PrepFlowFont.smallBold)
                ForEach(Array(store.serviceSyncEventTimeline.suffix(ServicePassLayout.timelineLimit))) { event in
                    ServiceTimelineRow(event: event)
                }
            }
            .padding(PrepFlowSpacing.sm)
            .background(PrepFlowColor.g5)
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))

            Spacer()
        }
        .padding(PrepFlowSpacing.md)
        .background(PrepFlowColor.white)
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous)
                .stroke(PrepFlowColor.g4, lineWidth: PrepFlowMetric.lineWidth)
        }
    }
}

// 正本: design/p4-wireframe-passview.png
private struct ServicePassStaffHandoff: View {
    @ObservedObject var store: BoardStore

    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.sm) {
            HStack {
                Text("担当")
                    .font(PrepFlowFont.sectionTitle)
                Spacer()
                Text(store.servicePacingProposal?.recommendation ?? "keep")
                    .font(PrepFlowFont.smallBold)
                    .foregroundStyle(PrepFlowColor.ink)
                    .padding(.horizontal, PrepFlowSpacing.sm)
                    .frame(height: PrepFlowMetric.catalogFieldHeight)
                    .background(PrepFlowColor.g5)
                    .clipShape(Capsule(style: .continuous))
            }

            ForEach(passFlags) { flag in
                HStack(spacing: PrepFlowSpacing.sm) {
                    Text(flag.seatRef)
                        .font(PrepFlowFont.railTitle)
                        .frame(width: PrepFlowMetric.actionButtonHeight, alignment: .leading)
                    VStack(alignment: .leading, spacing: PrepFlowSpacing.xxs) {
                        Text(flag.kind.rawValue)
                            .font(PrepFlowFont.bodyBold)
                        Text(flag.displayText)
                            .font(PrepFlowFont.railMeta)
                            .foregroundStyle(PrepFlowColor.g2)
                    }
                    Spacer()
                }
                .padding(PrepFlowSpacing.sm)
                .background(PrepFlowColor.g5)
                .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
            }

            ForEach(store.specialPrepTasks.prefix(ServicePassLayout.specialPrepLimit)) { task in
                ServiceTimelineRow(title: task.title, detail: task.note, value: "特別")
            }

            ServiceTimelineRow(title: "最終操作", detail: store.servicePassLastAction, value: "\(store.serviceSyncEventTimeline.count)件")
            Spacer()
        }
        .padding(PrepFlowSpacing.md)
        .background(PrepFlowColor.white)
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous)
                .stroke(PrepFlowColor.g4, lineWidth: PrepFlowMetric.lineWidth)
        }
    }

    private var passFlags: [PassSeatFlag] {
        if store.passSeatFlags.isEmpty {
            return [
                PassSeatFlag(
                    id: "pass-empty",
                    reservationID: "local",
                    seatRef: "卓3",
                    kind: .vip,
                    displayText: "ゲスト情報を厨房へ送るとここに表示"
                ),
            ]
        }
        return store.passSeatFlags
    }
}

// 正本: design/p4-wireframe-passview.png
private struct ServiceTimelineRow: View {
    let title: String
    let detail: String
    let value: String

    init(event: ServiceSyncEvent) {
        title = event.kind.rawValue
        detail = event.reservationID ?? event.source.rawValue
        value = event.offlineSequence == nil ? "\(event.covers)名" : "未送信"
    }

    init(title: String, detail: String, value: String) {
        self.title = title
        self.detail = detail
        self.value = value
    }

    var body: some View {
        HStack(spacing: PrepFlowSpacing.sm) {
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
                .foregroundStyle(value == "未送信" ? PrepFlowColor.time : PrepFlowColor.ink) // time-use: unsent service event deadline
                .monospacedDigit()
        }
        .padding(PrepFlowSpacing.sm)
        .background(PrepFlowColor.white)
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
    }
}

// 正本: design/p4-wireframe-passview.png
private struct ServicePassCell: View {
    let state: ServiceCellState

    var body: some View {
        Text(state.title)
            .font(PrepFlowFont.railMeta)
            .foregroundStyle(state.foreground)
            .frame(maxWidth: .infinity)
            .frame(height: PrepFlowMetric.actionButtonHeight)
            .background(state.background)
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous)
                    .stroke(state.border, lineWidth: PrepFlowMetric.lineWidth)
            }
    }
}

// 正本: design/p4-wireframe-passview.png
private struct ServiceSyncPanel: View {
    @ObservedObject var store: BoardStore

    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.sm) {
            Text("残数同期")
                .font(PrepFlowFont.sectionTitle)
            OpsMetric(title: "残数", value: "\(store.serviceSyncState?.remainingCovers ?? store.service.omakaseCovers)")
            OpsMetric(title: "提供済", value: "\(store.serviceSyncState?.servedCovers ?? 0)")
            OpsMetric(title: "未送信", value: "\(store.servicePassPendingOfflineCount)")
            OpsMetric(title: "ペース", value: store.servicePacingProposal?.recommendation ?? "未同期")
            OpsMetric(title: "最終", value: store.servicePassLastAction)
            OpsMetric(title: "席札印刷", value: "\(store.allergenLabelPrintCount)")
            OpsMetric(title: "再確認", value: "\(store.guestReplyRecheckCount)")

            Spacer()

            Button("提供済みにする") {
                store.markServiceCourseServed()
            }
            .buttonStyle(OpsSecondaryButtonStyle())

            Button("オフライン保存") {
                store.queueOfflineServiceServed()
            }
            .buttonStyle(OpsSecondaryButtonStyle())

            Button("未送信を再同期") {
                store.flushOfflineServiceEvents()
            }
            .buttonStyle(OpsSecondaryButtonStyle())

            Button("POS残数を同期") {
                store.replayServiceSyncEvent(ServiceSyncEvent(
                    id: "service-pass-remaining",
                    source: .pos,
                    kind: .remainingSync,
                    covers: 5,
                    occurredAt: "2026-06-17T18:52:00Z"
                ))
            }
            .buttonStyle(OpsPrimaryButtonStyle())
        }
        .padding(PrepFlowSpacing.md)
        .background(PrepFlowColor.white)
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous)
                .stroke(PrepFlowColor.g4, lineWidth: PrepFlowMetric.lineWidth)
        }
    }
}

// 正本: design/p4-wireframe-passview.png
private struct OpsMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.xxs) {
            Text(title)
                .font(PrepFlowFont.railMeta)
                .foregroundStyle(PrepFlowColor.g2)
            Text(value)
                .font(PrepFlowFont.railTitle)
                .monospacedDigit()
        }
        .padding(PrepFlowSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PrepFlowColor.white)
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous)
                .stroke(PrepFlowColor.g4, lineWidth: PrepFlowMetric.lineWidth)
        }
    }
}

private enum DirectOpsLayout {
    static let tileCount = 4
    static let depositYen = 5000
    static let remainingYen = 11500
}

private enum ServicePassRows {
    static func rows(events: [ServiceSyncEvent]) -> [ServicePassRow] {
        var rows = baseRows
        if let satoEvent = events.last(where: { $0.reservationID == "reservation-sato" && $0.kind != .remainingSync }) {
            update(&rows, table: "卓3", courseIndex: ServicePassLayout.nigiriIndex, state: cellState(for: satoEvent.kind))
        }
        if events.contains(where: { $0.reservationID == "reservation-yamada" && $0.kind == .served }) {
            update(&rows, table: "卓1", courseIndex: ServicePassLayout.nigiriIndex, state: .served)
        }
        return rows
    }

    private static let baseRows = [
        ServicePassRow(table: "卓1", detail: "2名 ・ 18:00", states: [.served, .cooking, .waiting, .waiting]),
        ServicePassRow(table: "卓3", detail: "4名 ・ 18:00", states: [.served, .fire, .waiting, .waiting]),
        ServicePassRow(table: "卓5", detail: "6名 ・ 18:30", states: [.served, .served, .cooking, .waiting]),
        ServicePassRow(table: "卓6", detail: "2名 ・ 19:00", states: [.cooking, .waiting, .hold, .waiting]),
    ]

    private static func update(_ rows: inout [ServicePassRow], table: String, courseIndex: Int, state: ServiceCellState) {
        guard let rowIndex = rows.firstIndex(where: { $0.table == table }), rows[rowIndex].states.indices.contains(courseIndex) else {
            return
        }
        rows[rowIndex].states[courseIndex] = state
    }

    private static func cellState(for kind: ServiceEventKind) -> ServiceCellState {
        switch kind {
        case .fire:
            .fire
        case .hold:
            .hold
        case .served:
            .served
        case .remainingSync:
            .waiting
        }
    }
}

private struct ServicePassRow: Identifiable {
    var id: String {
        table
    }

    let table: String
    let detail: String
    var states: [ServiceCellState]
}

private enum ServiceCellState: String {
    case served
    case cooking
    case waiting
    case hold
    case fire

    var title: String {
        switch self {
        case .served:
            "提供済"
        case .cooking:
            "調理中"
        case .waiting:
            "待機"
        case .hold:
            "HOLD"
        case .fire:
            "FIRE"
        }
    }

    var foreground: Color {
        switch self {
        case .served, .fire:
            PrepFlowColor.white
        case .cooking, .hold:
            PrepFlowColor.ink
        case .waiting:
            PrepFlowColor.g2
        }
    }

    var background: Color {
        switch self {
        case .served:
            PrepFlowColor.ink
        case .fire:
            PrepFlowColor.time // time-use: active fire cell
        case .cooking, .waiting:
            PrepFlowColor.white
        case .hold:
            PrepFlowColor.g5
        }
    }

    var border: Color {
        switch self {
        case .served:
            PrepFlowColor.ink
        case .fire:
            PrepFlowColor.time // time-use: active fire cell border
        case .cooking:
            PrepFlowColor.ink
        case .waiting, .hold:
            PrepFlowColor.g4
        }
    }
}

private enum ServicePassLayout {
    static let nigiriIndex = 1
    static let timelineLimit = 4
    static let specialPrepLimit = 2
}

private struct ServicePassSegmentButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PrepFlowFont.smallBold)
            .foregroundStyle(isSelected ? PrepFlowColor.ink : PrepFlowColor.g2)
            .frame(height: PrepFlowMetric.catalogFieldHeight)
            .padding(.horizontal, PrepFlowSpacing.md)
            .background(isSelected ? PrepFlowColor.white : PrepFlowColor.clear)
            .clipShape(Capsule(style: .continuous))
            .shadow(
                color: isSelected ? PrepFlowColor.ink.opacity(PrepFlowOpacity.glassShadow) : PrepFlowColor.clear,
                radius: PrepFlowSpacing.xs,
                y: PrepFlowSpacing.xxs
            )
            .opacity(configuration.isPressed ? PrepFlowOpacity.pressed : PrepFlowOpacity.solid)
    }
}

private struct OpsPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PrepFlowFont.action)
            .foregroundStyle(PrepFlowColor.white)
            .frame(maxWidth: .infinity)
            .frame(height: PrepFlowMetric.actionButtonHeight)
            .background(PrepFlowColor.ink)
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous))
            .opacity(configuration.isPressed ? PrepFlowOpacity.pressed : PrepFlowOpacity.solid)
    }
}

private struct OpsSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PrepFlowFont.smallBold)
            .foregroundStyle(PrepFlowColor.ink)
            .frame(maxWidth: .infinity)
            .frame(height: PrepFlowMetric.actionButtonHeight)
            .background(PrepFlowColor.white)
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous)
                    .stroke(PrepFlowColor.g4, lineWidth: PrepFlowMetric.lineWidth)
            }
            .opacity(configuration.isPressed ? PrepFlowOpacity.pressed : PrepFlowOpacity.solid)
    }
}

private struct OpsMiniButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PrepFlowFont.smallBold)
            .foregroundStyle(PrepFlowColor.ink)
            .frame(width: PrepFlowMetric.checkSize, height: PrepFlowMetric.checkSize)
            .background(PrepFlowColor.g5)
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
            .opacity(configuration.isPressed ? PrepFlowOpacity.pressed : PrepFlowOpacity.solid)
    }
}

private struct OpsAlertButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PrepFlowFont.smallBold)
            .foregroundStyle(PrepFlowColor.time) // time-use: incoming fire primary action
            .frame(height: PrepFlowMetric.actionButtonHeight)
            .padding(.horizontal, PrepFlowSpacing.md)
            .background(PrepFlowColor.white)
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
            .opacity(configuration.isPressed ? PrepFlowOpacity.pressed : PrepFlowOpacity.solid)
    }
}

private struct OpsAlertOutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PrepFlowFont.smallBold)
            .foregroundStyle(PrepFlowColor.white)
            .frame(height: PrepFlowMetric.actionButtonHeight)
            .padding(.horizontal, PrepFlowSpacing.md)
            .overlay {
                RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous)
                    .stroke(PrepFlowColor.white, lineWidth: PrepFlowMetric.lineWidth)
            }
            .opacity(configuration.isPressed ? PrepFlowOpacity.pressed : PrepFlowOpacity.solid)
    }
}
