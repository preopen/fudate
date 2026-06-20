// swiftlint:disable file_length
// 正本: design/p2-wireframe-label-flow.png
// 正本: design/p2-wireframe-prep-larder.png
// 正本: design/p2-wireframe-label-settings.png
import DesignTokens
import Engine
import SwiftUI

// 正本: design/p2-wireframe-label-flow.png
struct LabelOpsSheet: View {
    @ObservedObject var store: BoardStore
    @State private var madeQty = 200
    @State private var remainingQty = 65
    @State private var selectedScanMode = LabelScanMode.remaining
    @State private var latestAction = "完了 → ラベル作成待ち"
    let done: () -> Void

    var body: some View {
        ZStack {
            PrepFlowColor.g5.ignoresSafeArea()

            VStack(spacing: PrepFlowSpacing.md) {
                LabelOpsTopBar(done: done)

                HStack(alignment: .top, spacing: PrepFlowSpacing.md) {
                    LabelFlowColumn(
                        madeQty: $madeQty,
                        remainingQty: $remainingQty,
                        selectedScanMode: $selectedScanMode,
                        label: store.latestPrepLabel,
                        larderPlan: store.larderConsumptionPlan,
                        latestAction: latestAction,
                        qrRoute: store.latestQRReturnRoute,
                        issueLabel: issueLabel,
                        recordScan: recordScan,
                        openQR: openQR
                    )

                    PrepLarderPanel(
                        labelModeEnabled: store.labelModeEnabled,
                        printers: store.labelPrinterDevices,
                        selectedPrinterID: store.selectedLabelPrinterID,
                        paperSize: store.labelPaperSize,
                        printJob: store.latestLabelPrintJob,
                        pdfPath: store.latestLabelPDFPath,
                        items: store.larderItems,
                        alerts: store.larderAlerts,
                        plan: store.larderConsumptionPlan,
                        latestSummary: store.latestLarderUseSummary,
                        fridgeTemperatureC: store.fridgeTemperatureC,
                        fridgeTemperatureLoggedAt: store.fridgeTemperatureLoggedAt,
                        inspectionMissingCount: store.fridgeInspectionMissingCount,
                        refresh: refreshLarder,
                        applyUse: applyFIFOUse,
                        recordTemperature: recordTemperature,
                        completeInspection: completeInspection,
                        toggleLabelMode: toggleLabelMode,
                        selectPrinter: selectPrinter,
                        selectPaperSize: selectPaperSize,
                        testPrint: testPrint,
                        exportPDF: exportPDF
                    )
                    .frame(width: PrepFlowMetric.railWidth)
                }
            }
            .padding(PrepFlowSpacing.md)
        }
        .foregroundStyle(PrepFlowColor.ink)
        .presentationDetents([.large])
    }

    private func issueLabel() {
        let label = store.issueNikiriPrepLabel(madeQty: Double(madeQty))
        if store.latestPrepLabel?.id == label.id {
            latestAction = "\(valueText(label.madeQty))\(label.unit) のラベルを発行 / \(store.latestLabelPrintJob?.status ?? "queued")"
        } else {
            latestAction = store.todayPrepCompletionBlockReason
        }
        refreshLarder()
    }

    private func recordScan() {
        switch selectedScanMode {
        case .remaining:
            let result = store.scanLatestLabelRemaining(qty: Double(remainingQty))
            latestAction = "\(valueText(result.larderItem?.qty ?? 0))\(result.larderItem?.unit ?? "ml") を翌日繰越"
        case .used:
            store.scanLatestLabelUsed()
            latestAction = "使い切りとして記録"
        case .wasted:
            store.scanLatestLabelWaste(qty: Double(remainingQty), reason: .quality)
            latestAction = "\(remainingQty)ml を品質廃棄として記録"
        }
        refreshLarder()
        store.planLarderUse(requiredQty: Double(max(0, madeQty - remainingQty)))
    }

    private func refreshLarder() {
        store.refreshLarderFIFO()
        store.planLarderUse(requiredQty: Double(max(0, madeQty - remainingQty)))
    }

    private func applyFIFOUse() {
        let plan = store.applyPlannedLarderUse(requiredQty: Double(max(0, madeQty - remainingQty)))
        latestAction = "\(valueText(plan.plannedQty))\(plan.unit) をFIFO使用"
    }

    private func recordTemperature() {
        store.recordFridgeTemperature()
        latestAction = "冷蔵2 \(store.fridgeTemperatureC)℃ を記録"
    }

    private func completeInspection() {
        let changedCount = store.completeFridgeInspection()
        latestAction = "冷蔵点検完了 / 差異 \(changedCount)件"
    }

    private func toggleLabelMode() {
        store.toggleLabelMode()
        latestAction = store.labelModeEnabled ? "ラベルモード ON" : "ラベルモード OFF"
    }

    private func selectPrinter(_ id: String) {
        store.selectLabelPrinter(id)
        latestAction = "既定プリンタを更新"
    }

    private func selectPaperSize(_ paperSize: String) {
        store.selectLabelPaperSize(paperSize)
        latestAction = "\(paperSize) を選択"
    }

    private func testPrint() {
        let job = store.testLabelPrint()
        latestAction = "\(job.destination) / \(job.status)"
    }

    private func exportPDF() {
        let job = store.exportLatestLabelPDF()
        latestAction = job.outputPath ?? "PDFを生成"
    }

    private func openQR() {
        latestAction = store.openLatestLabelQR()
    }
}

private enum LabelScanMode: String, CaseIterable {
    case remaining = "残った"
    case used = "使い切り"
    case wasted = "廃棄"

    var detail: String {
        switch self {
        case .remaining:
            "翌日へ繰越"
        case .used:
            "残0"
        case .wasted:
            "ロス計上"
        }
    }
}

// 正本: design/p2-wireframe-label-flow.png
private struct LabelOpsTopBar: View {
    let done: () -> Void

    var body: some View {
        GlassEffectContainer {
            HStack(spacing: PrepFlowSpacing.md) {
                VStack(alignment: .leading, spacing: PrepFlowSpacing.xxs) {
                    Text("ラベル運用")
                        .font(PrepFlowFont.topTitle)
                    Text("完了 → 印刷 → QR残量記録 → 翌日繰越")
                        .font(PrepFlowFont.topSubtitle)
                        .foregroundStyle(PrepFlowColor.g2)
                }

                Spacer()

                Text("期限・残量")
                    .font(PrepFlowFont.countdownLabel)
                    .foregroundStyle(PrepFlowColor.time) // time-use: expiry and remaining mode marker
                    .padding(.horizontal, PrepFlowSpacing.md)
                    .padding(.vertical, PrepFlowSpacing.xs)
                    .background(PrepFlowColor.time.opacity(PrepFlowOpacity.timeGlass)) // time-use: expiry and remaining mode marker tint
                    .clipShape(Capsule(style: .continuous))
                    .glassEffect()

                Button("閉じる", action: done)
                    .buttonStyle(LabelGlassButtonStyle())
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

// 正本: design/p2-wireframe-label-flow.png
private struct LabelFlowColumn: View {
    @Binding var madeQty: Int
    @Binding var remainingQty: Int
    @Binding var selectedScanMode: LabelScanMode
    let label: PrepLabel?
    let larderPlan: LarderConsumptionPlan?
    let latestAction: String
    let qrRoute: String
    let issueLabel: () -> Void
    let recordScan: () -> Void
    let openQR: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: PrepFlowSpacing.md) {
                HStack(spacing: PrepFlowSpacing.md) {
                    LabelStepCard(step: "1", title: "完了チェック", subtitle: "ボードで完了→担当を確定") {
                        CompletedTaskPreview(madeQty: madeQty)
                    }

                    LabelStepCard(step: "2", title: "ラベル印刷", subtitle: "期限とQRを自動で印字") {
                        VStack(spacing: PrepFlowSpacing.sm) {
                            LabelPreview(label: label, madeQty: madeQty)
                            QuantityStepper(title: "作った量", value: $madeQty, unit: "ml", step: 10)
                            Button("ラベルを作成", action: issueLabel)
                                .buttonStyle(LabelPrimaryButtonStyle())
                        }
                    }
                }

                HStack(spacing: PrepFlowSpacing.md) {
                    LabelStepCard(step: "3", title: "QRで残量記録", subtitle: "営業後、かざして記録") {
                        VStack(spacing: PrepFlowSpacing.sm) {
                            QRScanHero(label: label, qrRoute: qrRoute, openQR: openQR)
                            LabelScanSegment(selectedMode: $selectedScanMode)
                            QuantityStepper(title: selectedScanMode == .wasted ? "廃棄量" : "残り", value: $remainingQty, unit: "ml", step: 5)
                            Button("記録する", action: recordScan)
                                .buttonStyle(LabelPrimaryButtonStyle())
                        }
                    }

                    LabelStepCard(step: "4", title: "翌日に繰越", subtitle: "残量を推奨から差引") {
                        CarryoverPreview(plan: larderPlan, remainingQty: remainingQty, latestAction: latestAction)
                    }
                }
            }
            .padding(.bottom, PrepFlowSpacing.md)
        }
    }
}

// 正本: design/p2-wireframe-label-flow.png
private struct LabelStepCard<Content: View>: View {
    let step: String
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.sm) {
            HStack(spacing: PrepFlowSpacing.xs) {
                Text(step)
                    .font(PrepFlowFont.countdownLabel)
                    .foregroundStyle(PrepFlowColor.white)
                    .frame(width: PrepFlowSpacing.lg, height: PrepFlowSpacing.lg)
                    .background(PrepFlowColor.time) // time-use: expiry flow step marker
                    .clipShape(Circle())
                Text(title)
                    .font(PrepFlowFont.sectionTitle)
                    .foregroundStyle(PrepFlowColor.time) // time-use: expiry flow step title
            }

            Text(subtitle)
                .font(PrepFlowFont.railMeta)
                .foregroundStyle(PrepFlowColor.g2)

            content
        }
        .padding(PrepFlowSpacing.md)
        .frame(maxWidth: .infinity, minHeight: 300, alignment: .topLeading)
        .background(PrepFlowColor.white)
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous)
                .stroke(PrepFlowColor.g4, lineWidth: PrepFlowMetric.lineWidth)
        }
    }
}

// 正本: design/p2-wireframe-label-flow.png
private struct CompletedTaskPreview: View {
    let madeQty: Int

    var body: some View {
        VStack(spacing: PrepFlowSpacing.sm) {
            HStack(spacing: PrepFlowSpacing.sm) {
                CheckCircleMini()
                VStack(alignment: .leading, spacing: PrepFlowSpacing.xxs) {
                    Text("煮切り仕込み")
                        .font(PrepFlowFont.bodyBold)
                    Text("\(madeQty)ml ・ 親方")
                        .font(PrepFlowFont.smallBold)
                        .foregroundStyle(PrepFlowColor.white)
                        .padding(.horizontal, PrepFlowSpacing.sm)
                        .padding(.vertical, PrepFlowSpacing.xxs)
                        .background(PrepFlowColor.ink)
                        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.sm, style: .continuous))
                }
                Spacer()
            }
            .padding(PrepFlowSpacing.sm)
            .background(PrepFlowColor.g5)
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))

            Text("完了 → ラベルを作成します")
                .font(PrepFlowFont.smallBold)
                .foregroundStyle(PrepFlowColor.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(PrepFlowSpacing.sm)
                .background(PrepFlowColor.ink)
                .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
        }
    }
}

// 正本: design/p2-wireframe-label-flow.png
private struct CheckCircleMini: View {
    var body: some View {
        Image(systemName: "checkmark")
            .font(PrepFlowFont.icon)
            .foregroundStyle(PrepFlowColor.white)
            .frame(width: PrepFlowMetric.checkSize, height: PrepFlowMetric.checkSize)
            .background(PrepFlowColor.ink)
            .clipShape(Circle())
    }
}

// 正本: design/p2-wireframe-label-flow.png
private struct LabelPreview: View {
    let label: PrepLabel?
    let madeQty: Int

    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.xs) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: PrepFlowSpacing.xxs) {
                    Text("煮切り")
                        .font(PrepFlowFont.topTitle)
                    Text("PREVIEW")
                        .font(PrepFlowFont.countdownLabel)
                        .foregroundStyle(PrepFlowColor.time) // time-use: label expiry preview badge
                }
                Spacer()
                QRBlock(size: PrepFlowMetric.actionButtonHeight)
            }

            LabelInfoRow(title: "仕込み", value: label?.printedAt ?? "未発行")
            LabelInfoRow(title: "使用期限", value: label?.expireAt ?? "発行後に自動計算", isTime: true)
            LabelInfoRow(title: "量 / 担当", value: "\(valueText(label?.madeQty ?? Double(madeQty)))ml ・ 親方")
        }
        .padding(PrepFlowSpacing.sm)
        .background(PrepFlowColor.white)
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous)
                .stroke(PrepFlowColor.g3, style: StrokeStyle(lineWidth: PrepFlowMetric.heavyLineWidth, dash: [PrepFlowSpacing.xs, PrepFlowSpacing.xs]))
        }
    }
}

// 正本: design/p2-wireframe-label-flow.png
private struct LabelInfoRow: View {
    let title: String
    let value: String
    var isTime = false

    var body: some View {
        HStack {
            Text(title)
                .font(PrepFlowFont.railMeta)
                .foregroundStyle(PrepFlowColor.g2)
            Spacer()
            Text(value)
                .font(PrepFlowFont.smallBold)
                .foregroundStyle(isTime ? PrepFlowColor.time : PrepFlowColor.ink) // time-use: label expiry value
                .monospacedDigit()
        }
        .padding(.top, PrepFlowSpacing.xs)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(PrepFlowColor.g4)
                .frame(height: PrepFlowMetric.lineWidth)
        }
    }
}

// 正本: design/p2-wireframe-label-flow.png
private struct QRScanHero: View {
    let label: PrepLabel?
    let qrRoute: String
    let openQR: () -> Void

    var body: some View {
        VStack(spacing: PrepFlowSpacing.xs) {
            QRBlock(size: PrepFlowMetric.topBarHeight)
            Text(label == nil ? "ラベル未発行" : "煮切り（QR読み取り済み）")
                .font(PrepFlowFont.bodyBold)
            Text(label?.qrToken ?? "ラベル作成後にQRを読み取れます")
                .font(PrepFlowFont.railMeta)
                .foregroundStyle(PrepFlowColor.g2)
                .lineLimit(1)
            Text(qrRoute)
                .font(PrepFlowFont.countdownLabel)
                .foregroundStyle(PrepFlowColor.g2)
                .lineLimit(1)
            Button("QRを開く", action: openQR)
                .buttonStyle(LabelSmallPillButtonStyle())
        }
        .frame(maxWidth: .infinity)
        .padding(PrepFlowSpacing.sm)
        .background(PrepFlowColor.g5)
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
    }
}

// 正本: design/p2-wireframe-label-flow.png
private struct QRBlock: View {
    let size: CGFloat

    var body: some View {
        Grid(horizontalSpacing: PrepFlowSpacing.xxs, verticalSpacing: PrepFlowSpacing.xxs) {
            ForEach(0 ..< 4, id: \.self) { row in
                GridRow {
                    ForEach(0 ..< 4, id: \.self) { column in
                        Rectangle()
                            .fill((row + column).isMultiple(of: 2) ? PrepFlowColor.ink : PrepFlowColor.white)
                    }
                }
            }
        }
        .padding(PrepFlowSpacing.xxs)
        .frame(width: size, height: size)
        .background(PrepFlowColor.white)
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.sm, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PrepFlowRadius.sm, style: .continuous)
                .stroke(PrepFlowColor.ink, lineWidth: PrepFlowMetric.heavyLineWidth)
        }
    }
}

// 正本: design/p2-wireframe-label-flow.png
private struct LabelScanSegment: View {
    @Binding var selectedMode: LabelScanMode

    var body: some View {
        HStack(spacing: PrepFlowSpacing.xs) {
            ForEach(LabelScanMode.allCases, id: \.self) { mode in
                Button {
                    selectedMode = mode
                } label: {
                    VStack(spacing: PrepFlowSpacing.xxs) {
                        Text(mode.rawValue)
                            .font(PrepFlowFont.smallBold)
                        Text(mode.detail)
                            .font(PrepFlowFont.countdownLabel)
                            .foregroundStyle(PrepFlowColor.g2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, PrepFlowSpacing.sm)
                    .background(PrepFlowColor.white)
                    .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous)
                            .stroke(
                                mode == selectedMode ? segmentStroke(for: mode) : PrepFlowColor.g4,
                                lineWidth: mode == selectedMode ? PrepFlowMetric.heavyLineWidth : PrepFlowMetric.lineWidth
                            )
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func segmentStroke(for mode: LabelScanMode) -> Color {
        mode == .wasted ? PrepFlowColor.time : PrepFlowColor.ink // time-use: waste mode selection border
    }
}

// 正本: design/p2-wireframe-label-flow.png
private struct QuantityStepper: View {
    let title: String
    @Binding var value: Int
    let unit: String
    let step: Int

    var body: some View {
        HStack {
            Text(title)
                .font(PrepFlowFont.railMeta)
                .foregroundStyle(PrepFlowColor.g2)
            Spacer()
            Button("-") {
                value = max(0, value - step)
            }
            .buttonStyle(LabelSmallButtonStyle())
            Text("\(value)")
                .font(PrepFlowFont.railTitle)
                .monospacedDigit()
                .frame(width: PrepFlowMetric.actionButtonHeight)
            Button("+") {
                value += step
            }
            .buttonStyle(LabelSmallButtonStyle())
            Text(unit)
                .font(PrepFlowFont.railMeta)
                .foregroundStyle(PrepFlowColor.g2)
        }
        .padding(PrepFlowSpacing.sm)
        .background(PrepFlowColor.g5)
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
    }
}

// 正本: design/p2-wireframe-prep-larder.png
private struct CarryoverPreview: View {
    let plan: LarderConsumptionPlan?
    let remainingQty: Int
    let latestAction: String

    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.sm) {
            Text("翌営業日 6/13 の仕込みボード")
                .font(PrepFlowFont.smallBold)
                .foregroundStyle(PrepFlowColor.time) // time-use: next day expiry/carryover banner
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(PrepFlowSpacing.sm)
                .background(PrepFlowColor.time.opacity(PrepFlowOpacity.timeSoft)) // time-use: next day expiry/carryover banner tint
                .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))

            CarryoverCalcRow(title: "本日必要（推奨）", value: "\(valueText(plan?.requestedQty ?? 0))\(plan?.unit ?? "ml")", isTotal: false)
            CarryoverCalcRow(title: "昨日の繰越（期限内）", value: "-\(remainingQty)ml", isTotal: false)
            CarryoverCalcRow(title: "今日の追い仕込み", value: "\(valueText(plan?.shortfallQty ?? 0))\(plan?.unit ?? "ml")", isTotal: true)

            Text(latestAction)
                .font(PrepFlowFont.railMeta)
                .foregroundStyle(PrepFlowColor.g2)

            VStack(alignment: .leading, spacing: PrepFlowSpacing.xs) {
                Text("ボード表示")
                    .font(PrepFlowFont.countdownLabel)
                    .foregroundStyle(PrepFlowColor.g2)
                Text("煮切り（追い仕込み）")
                    .font(PrepFlowFont.bodyBold)
                Text("昨日分 \(remainingQty)ml + 追い仕込み")
                    .font(PrepFlowFont.railMeta)
                    .foregroundStyle(PrepFlowColor.g2)
            }
            .padding(PrepFlowSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(PrepFlowColor.g5)
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
        }
    }
}

// 正本: design/p2-wireframe-prep-larder.png
private struct CarryoverCalcRow: View {
    let title: String
    let value: String
    let isTotal: Bool

    var body: some View {
        HStack {
            Text(title)
                .font(isTotal ? PrepFlowFont.smallBold : PrepFlowFont.railMeta)
                .foregroundStyle(isTotal ? PrepFlowColor.ink : PrepFlowColor.g2)
            Spacer()
            Text(value)
                .font(isTotal ? PrepFlowFont.railTitle : PrepFlowFont.smallBold)
                .foregroundStyle(isTotal ? PrepFlowColor.time : PrepFlowColor.ink) // time-use: next-day required quantity
                .monospacedDigit()
        }
        .padding(PrepFlowSpacing.sm)
        .background(isTotal ? PrepFlowColor.time.opacity(PrepFlowOpacity.timeSoft) : PrepFlowColor.white) // time-use: next-day total background
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous)
                .stroke(isTotal ? PrepFlowColor.time.opacity(PrepFlowOpacity.timeStroke) : PrepFlowColor.g4, lineWidth: PrepFlowMetric.lineWidth) // time-use: next-day total border
        }
    }
}

// 正本: design/p2-wireframe-prep-larder.png
private struct PrepLarderPanel: View {
    let labelModeEnabled: Bool
    let printers: [LabelPrinterDevice]
    let selectedPrinterID: String
    let paperSize: String
    let printJob: LabelPrintJob?
    let pdfPath: String?
    let items: [PrepLarderItem]
    let alerts: [LarderAlert]
    let plan: LarderConsumptionPlan?
    let latestSummary: String
    let fridgeTemperatureC: Int
    let fridgeTemperatureLoggedAt: String?
    let inspectionMissingCount: Int
    let refresh: () -> Void
    let applyUse: () -> Void
    let recordTemperature: () -> Void
    let completeInspection: () -> Void
    let toggleLabelMode: () -> Void
    let selectPrinter: (String) -> Void
    let selectPaperSize: (String) -> Void
    let testPrint: () -> Void
    let exportPDF: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: PrepFlowSpacing.xxs) {
                    Text("今ある仕込み")
                        .font(PrepFlowFont.sectionTitle)
                    Text("作り置き・残量・期限")
                        .font(PrepFlowFont.railMeta)
                        .foregroundStyle(PrepFlowColor.g2)
                }
                Spacer()
                Button("FIFO更新", action: refresh)
                    .buttonStyle(LabelGlassButtonStyle())
            }

            HStack(spacing: PrepFlowSpacing.sm) {
                LarderKPI(title: "作り置き", value: "\(items.count)", isTime: false)
                LarderKPI(title: "期限注意", value: "\(alerts.count(where: { $0.level != "ok" }))", isTime: true)
            }

            LabelPrinterSettingsCard(
                labelModeEnabled: labelModeEnabled,
                printers: printers,
                selectedPrinterID: selectedPrinterID,
                paperSize: paperSize,
                printJob: printJob,
                pdfPath: pdfPath,
                toggleLabelMode: toggleLabelMode,
                selectPrinter: selectPrinter,
                selectPaperSize: selectPaperSize,
                testPrint: testPrint,
                exportPDF: exportPDF
            )

            FridgeLensCard(
                temperatureC: fridgeTemperatureC,
                loggedAt: fridgeTemperatureLoggedAt,
                missingCount: inspectionMissingCount,
                recordTemperature: recordTemperature,
                completeInspection: completeInspection
            )

            ScrollView {
                VStack(spacing: PrepFlowSpacing.xs) {
                    if items.isEmpty {
                        EmptyLarderView()
                    } else {
                        ForEach(items.sorted { $0.expireAt < $1.expireAt }) { item in
                            LarderItemRow(item: item, alert: alerts.first { $0.labelID == item.labelID })
                        }
                    }
                }
            }

            LarderPlanFooter(plan: plan, latestSummary: latestSummary, applyUse: applyUse)
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

// 正本: design/p2-wireframe-label-settings.png
private struct LabelPrinterSettingsCard: View {
    let labelModeEnabled: Bool
    let printers: [LabelPrinterDevice]
    let selectedPrinterID: String
    let paperSize: String
    let printJob: LabelPrintJob?
    let pdfPath: String?
    let toggleLabelMode: () -> Void
    let selectPrinter: (String) -> Void
    let selectPaperSize: (String) -> Void
    let testPrint: () -> Void
    let exportPDF: () -> Void

    private let paperSizes = ["62mm 連続", "29 × 90mm", "40 × 40mm", "PDF / A4"]

    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.xs) {
            HStack(spacing: PrepFlowSpacing.sm) {
                VStack(alignment: .leading, spacing: PrepFlowSpacing.xxs) {
                    Text("ラベルモード")
                        .font(PrepFlowFont.bodyBold)
                    Text(labelModeEnabled ? "自動ラベル・QR・期限アラート ON" : "手書き運用")
                        .font(PrepFlowFont.railMeta)
                        .foregroundStyle(PrepFlowColor.g2)
                }
                Spacer()
                Button(labelModeEnabled ? "ON" : "OFF", action: toggleLabelMode)
                    .buttonStyle(LabelSmallPillButtonStyle())
                    .frame(width: PrepFlowMetric.actionButtonHeight)
            }

            VStack(spacing: PrepFlowSpacing.xs) {
                ForEach(printers) { printer in
                    LabelPrinterRow(
                        printer: printer,
                        isSelected: printer.id == selectedPrinterID,
                        select: { selectPrinter(printer.id) }
                    )
                }
            }

            VStack(alignment: .leading, spacing: PrepFlowSpacing.xs) {
                Text("用紙サイズ")
                    .font(PrepFlowFont.countdownLabel)
                    .foregroundStyle(PrepFlowColor.g2)
                ForEach(paperSizes, id: \.self) { size in
                    Button {
                        selectPaperSize(size)
                    } label: {
                        HStack {
                            Text(size)
                                .font(PrepFlowFont.smallBold)
                            Spacer()
                            if size == paperSize {
                                Image(systemName: "checkmark")
                                    .font(PrepFlowFont.icon)
                            }
                        }
                        .foregroundStyle(size == paperSize ? PrepFlowColor.white : PrepFlowColor.ink)
                        .padding(.horizontal, PrepFlowSpacing.sm)
                        .frame(height: PrepFlowMetric.smallControlHeight)
                        .background(size == paperSize ? PrepFlowColor.ink : PrepFlowColor.white)
                        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.sm, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: PrepFlowRadius.sm, style: .continuous)
                                .stroke(PrepFlowColor.g4, lineWidth: PrepFlowMetric.lineWidth)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            LabelPrintStatusCard(printJob: printJob, pdfPath: pdfPath)

            HStack(spacing: PrepFlowSpacing.xs) {
                Button("テスト印刷", action: testPrint)
                    .buttonStyle(LabelSmallPillButtonStyle())
                Button("PDF出力", action: exportPDF)
                    .buttonStyle(LabelSmallPillButtonStyle())
            }

            Text("プリンタ未接続でもPDFで出力し、汎用ラベル用紙に印刷できます。")
                .font(PrepFlowFont.countdownLabel)
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
}

// 正本: design/p2-wireframe-label-settings.png
private struct LabelPrinterRow: View {
    let printer: LabelPrinterDevice
    let isSelected: Bool
    let select: () -> Void

    var body: some View {
        Button(action: select) {
            HStack(spacing: PrepFlowSpacing.sm) {
                Image(systemName: "printer")
                    .font(PrepFlowFont.icon)
                    .foregroundStyle(PrepFlowColor.ink)
                    .frame(width: PrepFlowMetric.catalogFieldHeight, height: PrepFlowMetric.catalogFieldHeight)
                    .background(PrepFlowColor.white)
                    .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))

                VStack(alignment: .leading, spacing: PrepFlowSpacing.xxs) {
                    Text(printer.name)
                        .font(PrepFlowFont.smallBold)
                        .lineLimit(1)
                    Text(printer.detail)
                        .font(PrepFlowFont.countdownLabel)
                        .foregroundStyle(PrepFlowColor.g2)
                        .lineLimit(1)
                }

                Spacer()

                Text(printer.status == "connected" ? "接続" : printer.status.uppercased())
                    .font(PrepFlowFont.countdownLabel)
                    .foregroundStyle(PrepFlowColor.g2)
                    .padding(.horizontal, PrepFlowSpacing.xs)
                    .frame(height: PrepFlowMetric.smallControlHeight)
                    .background(PrepFlowColor.white)
                    .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.sm, style: .continuous))
            }
            .padding(PrepFlowSpacing.xs)
            .background(PrepFlowColor.white)
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous)
                    .stroke(
                        isSelected ? PrepFlowColor.ink : PrepFlowColor.g4,
                        lineWidth: isSelected ? PrepFlowMetric.heavyLineWidth : PrepFlowMetric.lineWidth
                    )
            }
        }
        .buttonStyle(.plain)
    }
}

// 正本: design/p2-wireframe-label-settings.png
private struct LabelPrintStatusCard: View {
    let printJob: LabelPrintJob?
    let pdfPath: String?

    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.xxs) {
            Text("出力状態")
                .font(PrepFlowFont.countdownLabel)
                .foregroundStyle(PrepFlowColor.g2)
            Text(printJob?.destination ?? "ラベル未発行")
                .font(PrepFlowFont.bodyBold)
                .lineLimit(1)
            Text(statusText)
                .font(PrepFlowFont.countdownLabel)
                .foregroundStyle(PrepFlowColor.g2)
                .lineLimit(1)
        }
        .padding(PrepFlowSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PrepFlowColor.white)
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
    }

    private var statusText: String {
        if let pdfPath {
            return pdfPath
        }
        guard let printJob else {
            return "テスト印刷またはPDF出力で確認"
        }
        return "\(printJob.paperSize) / \(printJob.status)"
    }
}

// 正本: design/p2-wireframe-fridge-lens.png
private struct FridgeLensCard: View {
    let temperatureC: Int
    let loggedAt: String?
    let missingCount: Int
    let recordTemperature: () -> Void
    let completeInspection: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.xs) {
            HStack(spacing: PrepFlowSpacing.sm) {
                VStack(alignment: .leading, spacing: PrepFlowSpacing.xxs) {
                    Text("冷蔵2 レンズ")
                        .font(PrepFlowFont.bodyBold)
                    Text(loggedAt ?? "温度未記録")
                        .font(PrepFlowFont.railMeta)
                        .foregroundStyle(PrepFlowColor.g2)
                        .lineLimit(1)
                }
                Spacer()
                Text("\(temperatureC)℃")
                    .font(PrepFlowFont.iconLarge)
                    .foregroundStyle(PrepFlowColor.ink)
                    .monospacedDigit()
            }

            HStack(spacing: PrepFlowSpacing.xs) {
                Button("温度記録", action: recordTemperature)
                    .buttonStyle(LabelSmallPillButtonStyle())
                Button("点検完了", action: completeInspection)
                    .buttonStyle(LabelSmallPillButtonStyle())
            }

            Text("差異 \(missingCount)件")
                .font(PrepFlowFont.countdownLabel)
                .foregroundStyle(missingCount > 0 ? PrepFlowColor.time : PrepFlowColor.g2) // time-use: fridge inspection variance
                .monospacedDigit()
        }
        .padding(PrepFlowSpacing.sm)
        .background(PrepFlowColor.g5)
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous)
                .stroke(
                    missingCount > 0 ? PrepFlowColor.time.opacity(PrepFlowOpacity.timeStroke) : PrepFlowColor.g4, // time-use: fridge inspection variance stroke
                    lineWidth: PrepFlowMetric.lineWidth
                ) // time-use: fridge inspection variance border
        }
    }
}

// 正本: design/p2-wireframe-prep-larder.png
private struct LarderKPI: View {
    let title: String
    let value: String
    let isTime: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.xxs) {
            Text(title)
                .font(PrepFlowFont.railMeta)
                .foregroundStyle(PrepFlowColor.g2)
            Text(value)
                .font(PrepFlowFont.iconLarge)
                .foregroundStyle(isTime ? PrepFlowColor.time : PrepFlowColor.ink) // time-use: expiry warning KPI
                .monospacedDigit()
        }
        .padding(PrepFlowSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isTime ? PrepFlowColor.time.opacity(PrepFlowOpacity.timeSoft) : PrepFlowColor.g5) // time-use: expiry warning KPI background
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
    }
}

// 正本: design/p2-wireframe-prep-larder.png
private struct LarderItemRow: View {
    let item: PrepLarderItem
    let alert: LarderAlert?

    var body: some View {
        HStack(spacing: PrepFlowSpacing.sm) {
            Rectangle()
                .fill(isAlert ? PrepFlowColor.time : PrepFlowColor.ink) // time-use: expiry item swatch
                .frame(width: PrepFlowSpacing.xs, height: PrepFlowMetric.catalogFieldHeight)
                .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.sm, style: .continuous))

            VStack(alignment: .leading, spacing: PrepFlowSpacing.xxs) {
                Text("煮切り")
                    .font(PrepFlowFont.bodyBold)
                Text("\(item.labelID) ・ \(item.status.rawValue)")
                    .font(PrepFlowFont.railMeta)
                    .foregroundStyle(PrepFlowColor.g2)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: PrepFlowSpacing.xxs) {
                Text("\(valueText(item.qty))\(item.unit)")
                    .font(PrepFlowFont.smallBold)
                    .monospacedDigit()
                Text(item.expireAt)
                    .font(PrepFlowFont.countdownLabel)
                    .foregroundStyle(isAlert ? PrepFlowColor.time : PrepFlowColor.g2) // time-use: larder expiry text
                    .monospacedDigit()
            }
        }
        .padding(PrepFlowSpacing.sm)
        .background(isAlert ? PrepFlowColor.time.opacity(PrepFlowOpacity.timeNow) : PrepFlowColor.white) // time-use: larder expiry alert background
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous)
                .stroke(isAlert ? PrepFlowColor.time.opacity(PrepFlowOpacity.timeStroke) : PrepFlowColor.g4, lineWidth: PrepFlowMetric.lineWidth) // time-use: larder expiry border
        }
    }

    private var isAlert: Bool {
        alert?.level != nil && alert?.level != "ok"
    }
}

// 正本: design/p2-wireframe-prep-larder.png
private struct EmptyLarderView: View {
    var body: some View {
        VStack(spacing: PrepFlowSpacing.xs) {
            Text("ラベル発行後に表示")
                .font(PrepFlowFont.bodyBold)
            Text("ここは半製品の現在地です。食材在庫・発注の管理はしません。")
                .font(PrepFlowFont.railMeta)
                .foregroundStyle(PrepFlowColor.g2)
                .multilineTextAlignment(.center)
        }
        .padding(PrepFlowSpacing.lg)
        .frame(maxWidth: .infinity)
        .background(PrepFlowColor.g5)
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
    }
}

// 正本: design/p2-wireframe-prep-larder.png
private struct LarderPlanFooter: View {
    let plan: LarderConsumptionPlan?
    let latestSummary: String
    let applyUse: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.xs) {
            Text("FIFO使用予定")
                .font(PrepFlowFont.countdownLabel)
                .foregroundStyle(PrepFlowColor.g2)
            Text("\(valueText(plan?.plannedQty ?? 0))/\(valueText(plan?.requestedQty ?? 0))\(plan?.unit ?? "ml") 使用")
                .font(PrepFlowFont.bodyBold)
                .monospacedDigit()
            Text("不足 \(valueText(plan?.shortfallQty ?? 0))\(plan?.unit ?? "ml")")
                .font(PrepFlowFont.railMeta)
                .foregroundStyle(PrepFlowColor.g2)
            Text(latestSummary)
                .font(PrepFlowFont.countdownLabel)
                .foregroundStyle(PrepFlowColor.g2)
                .lineLimit(1)
            Button("FIFOを使用", action: applyUse)
                .buttonStyle(LabelPrimaryButtonStyle())
        }
        .padding(PrepFlowSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PrepFlowColor.g5)
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
    }
}

private struct LabelSmallPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PrepFlowFont.countdownLabel)
            .foregroundStyle(PrepFlowColor.ink)
            .frame(maxWidth: .infinity)
            .frame(height: PrepFlowMetric.catalogFieldHeight)
            .background(PrepFlowColor.white)
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.sm, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: PrepFlowRadius.sm, style: .continuous)
                    .stroke(PrepFlowColor.g4, lineWidth: PrepFlowMetric.lineWidth)
            }
            .opacity(configuration.isPressed ? PrepFlowOpacity.pressed : PrepFlowOpacity.solid)
    }
}

private struct LabelGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PrepFlowFont.smallBold)
            .foregroundStyle(PrepFlowColor.ink)
            .frame(height: PrepFlowMetric.catalogFieldHeight)
            .padding(.horizontal, PrepFlowSpacing.md)
            .background(PrepFlowColor.white.opacity(PrepFlowOpacity.glass))
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
            .opacity(configuration.isPressed ? PrepFlowOpacity.pressed : PrepFlowOpacity.solid)
            .glassEffect()
    }
}

private struct LabelPrimaryButtonStyle: ButtonStyle {
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

private struct LabelSmallButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PrepFlowFont.bodyBold)
            .foregroundStyle(PrepFlowColor.ink)
            .frame(width: PrepFlowMetric.catalogFieldHeight, height: PrepFlowMetric.catalogFieldHeight)
            .background(PrepFlowColor.white)
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous)
                    .stroke(PrepFlowColor.g4, lineWidth: PrepFlowMetric.lineWidth)
            }
            .opacity(configuration.isPressed ? PrepFlowOpacity.pressed : PrepFlowOpacity.solid)
    }
}

private func valueText(_ value: Double) -> String {
    value.rounded() == value ? String(Int(value)) : String(format: "%.1f", value)
}
