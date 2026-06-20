// 正本: design/p1-wireframe-template-editor-liquidglass.png
// 正本: design/p1-wireframe-prepitem-editor.png
import DesignTokens
import Engine
import SwiftUI

// 正本: design/p1-wireframe-template-editor-liquidglass.png
struct CatalogEditorView: View {
    @StateObject private var store: BoardStore
    private let previewBoard: (() -> Void)?

    init(store: BoardStore = BoardStore(), previewBoard: (() -> Void)? = nil) {
        _store = StateObject(wrappedValue: store)
        self.previewBoard = previewBoard
    }

    var body: some View {
        ZStack(alignment: .top) {
            PrepFlowColor.g5.ignoresSafeArea()

            HStack(spacing: PrepFlowSpacing.none) {
                CatalogTree(store: store)
                    .frame(width: PrepFlowMetric.catalogTreeWidth)

                CatalogDetail(store: store)
            }
            .padding(.top, PrepFlowMetric.topInset)

            CatalogTopBar(
                courseName: store.catalog.courseName,
                previewBoard: {
                    store.previewCatalogOnBoard()
                    previewBoard?()
                },
                save: {
                    store.saveCatalogForBoard()
                }
            )
            .padding(PrepFlowSpacing.md)
        }
        .foregroundStyle(PrepFlowColor.ink)
    }
}

// 正本: design/p1-wireframe-template-editor-liquidglass.png
private struct CatalogTopBar: View {
    let courseName: String
    let previewBoard: () -> Void
    let save: () -> Void

    var body: some View {
        GlassEffectContainer {
            HStack(spacing: PrepFlowSpacing.md) {
                Text("テンプレート /")
                    .font(PrepFlowFont.small)
                    .foregroundStyle(PrepFlowColor.g2)
                Text(courseName)
                    .font(PrepFlowFont.topTitle)
                Spacer()
                Button("当日ボードでプレビュー", action: previewBoard)
                    .buttonStyle(GlassButtonStyle())
                Button("保存", action: save)
                    .buttonStyle(PrimaryButtonStyle())
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

// 正本: design/p1-wireframe-template-editor-liquidglass.png
private struct CatalogTree: View {
    @ObservedObject var store: BoardStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PrepFlowSpacing.xs) {
                Text("構成（階層）")
                    .font(PrepFlowFont.countdownLabel)
                    .foregroundStyle(PrepFlowColor.g2)
                    .textCase(.uppercase)
                    .padding(.horizontal, PrepFlowSpacing.md)
                    .padding(.top, PrepFlowSpacing.md)

                ForEach(store.catalog.dishes) { dish in
                    CatalogTreeDishRow(name: dish.name)
                    ForEach(dish.components) { component in
                        CatalogTreeComponentRow(name: component.name)
                        ForEach(component.tasks) { task in
                            CatalogTreeTaskRow(task: task, isSelected: store.catalog.selectedTaskID == task.id) {
                                store.selectTask(task.id)
                            }
                        }
                    }
                }

                Button("＋ サブ仕込みを追加") {
                    store.addTask()
                }
                .buttonStyle(DashedTreeButtonStyle(inset: .task))

                Button("＋ 構成要素を追加") {
                    store.addComponent()
                }
                .buttonStyle(DashedTreeButtonStyle(inset: .component))

                Button("＋ 料理を追加") {
                    store.addDish()
                }
                .buttonStyle(DashedTreeButtonStyle(inset: .dish))
            }
            .padding(.bottom, PrepFlowSpacing.lg)
        }
        .background(PrepFlowColor.white.opacity(PrepFlowOpacity.contentHeader))
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(PrepFlowColor.g4)
                .frame(width: PrepFlowMetric.lineWidth)
        }
    }
}

// 正本: design/p1-wireframe-template-editor-liquidglass.png
private struct CatalogTreeDishRow: View {
    let name: String

    var body: some View {
        HStack(spacing: PrepFlowSpacing.xs) {
            Text("▾")
                .font(PrepFlowFont.smallBold)
                .foregroundStyle(PrepFlowColor.g2)
            Text(name)
                .font(PrepFlowFont.smallBold)
        }
        .padding(.horizontal, PrepFlowSpacing.sm)
        .padding(.vertical, PrepFlowSpacing.xs)
        .background(PrepFlowColor.white)
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous)
                .stroke(PrepFlowColor.g4, lineWidth: PrepFlowMetric.lineWidth)
        }
        .padding(.horizontal, PrepFlowSpacing.md)
    }
}

// 正本: design/p1-wireframe-template-editor-liquidglass.png
private struct CatalogTreeComponentRow: View {
    let name: String

    var body: some View {
        HStack(spacing: PrepFlowSpacing.xs) {
            Circle()
                .fill(PrepFlowColor.ink)
                .frame(width: PrepFlowSpacing.xs, height: PrepFlowSpacing.xs)
            Text("構成要素：\(name)")
                .font(PrepFlowFont.small)
        }
        .padding(.leading, PrepFlowSpacing.lg)
        .padding(.trailing, PrepFlowSpacing.md)
        .padding(.vertical, PrepFlowSpacing.xs)
    }
}

// 正本: design/p1-wireframe-template-editor-liquidglass.png
private struct CatalogTreeTaskRow: View {
    let task: CatalogPrepTask
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: PrepFlowSpacing.xs) {
                Circle()
                    .fill(isSelected ? PrepFlowColor.white : PrepFlowColor.g2)
                    .frame(width: PrepFlowSpacing.xs, height: PrepFlowSpacing.xs)
                Text(task.name)
                    .font(isSelected ? PrepFlowFont.smallBold : PrepFlowFont.small)
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? PrepFlowColor.white : PrepFlowColor.g2)
            .padding(.leading, PrepFlowSpacing.xxl)
            .padding(.trailing, PrepFlowSpacing.sm)
            .padding(.vertical, PrepFlowSpacing.xs)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? PrepFlowColor.ink : PrepFlowColor.clear)
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, PrepFlowSpacing.md)
    }
}

// 正本: design/p1-wireframe-template-editor-liquidglass.png
// 正本: design/p1-wireframe-prepitem-editor.png
private struct CatalogDetail: View {
    @ObservedObject var store: BoardStore

    var body: some View {
        let task = store.selectedCatalogTask
        let quantity = calcQty(task.engineTask, covers: 14)

        HStack(spacing: PrepFlowSpacing.none) {
            ScrollView {
                VStack(alignment: .leading, spacing: PrepFlowSpacing.md) {
                    Text(task.name)
                        .font(PrepFlowFont.countdownValue)
                    Text("\(store.catalog.courseName) › 煮切り・ツメ")
                        .font(PrepFlowFont.railMeta)
                        .foregroundStyle(PrepFlowColor.g3)

                    CatalogFieldGrid {
                        CatalogTextField(label: "サブ仕込み名", text: bindingText(task.name) { store.updateSelectedTask(name: $0) })
                        CatalogReadOnlyField(label: "担当セクション", value: task.sectionName)
                        CatalogNumberField(label: "1人前の必要量（FR-03/37）", value: task.coeffPerCover, unit: "\(task.unit) / 人") {
                            store.updateSelectedTask(coeffPerCover: $0)
                        }
                        CatalogNumberField(label: "歩留り", value: task.yieldPercent, unit: "%") {
                            store.updateSelectedTask(yieldPercent: $0)
                        }
                        CatalogIntegerField(label: "所要時間（FR-06）", value: task.durationMin, unit: "分") {
                            store.updateSelectedTask(durationMin: $0)
                        }
                        CatalogIntegerField(label: "着手リード", value: task.leadMinBeforeOpen, unit: "分前") {
                            store.updateSelectedTask(leadMinBeforeOpen: $0)
                        }
                    }

                    VStack(alignment: .leading, spacing: PrepFlowSpacing.xs) {
                        Text("スケール則（出力量の決め方）")
                            .font(PrepFlowFont.sectionTitle)
                            .foregroundStyle(PrepFlowColor.g2)
                        HStack(spacing: PrepFlowSpacing.sm) {
                            CatalogScaleOption(title: "人数連動", subtitle: "per_cover", isSelected: true)
                            CatalogScaleOption(title: "1人前×人数", subtitle: "per_portion", isSelected: false)
                            CatalogScaleOption(title: "固定バッチ", subtitle: "fixed_batch", isSelected: false)
                        }
                    }

                    CatalogTextArea(text: bindingText(task.instruction) { store.updateSelectedTask(instruction: $0) })

                    CatalogMediaStrip()
                }
                .padding(.horizontal, PrepFlowSpacing.lg)
                .padding(.vertical, PrepFlowSpacing.md)
            }

            CatalogPreview(
                task: task,
                quantity: quantity,
                saveCount: store.catalogSaveCount,
                summary: store.catalogBoardPreviewSummary,
                savedAt: store.catalogLastSavedAt
            )
            .frame(width: PrepFlowMetric.catalogPreviewWidth)
        }
        .background(PrepFlowColor.g5)
    }

    private func bindingText(_ value: String, update: @escaping @MainActor @Sendable (String) -> Void) -> Binding<String> {
        Binding(
            get: { value },
            set: { nextValue in
                Task { @MainActor in
                    update(nextValue)
                }
            }
        )
    }
}

// 正本: design/p1-wireframe-template-editor-liquidglass.png
private struct CatalogFieldGrid<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: PrepFlowSpacing.md) {
            content
        }
    }
}

// 正本: design/p1-wireframe-template-editor-liquidglass.png
private struct CatalogTextField: View {
    let label: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.xs) {
            CatalogLabel(label)
            TextField("", text: $text)
                .font(PrepFlowFont.smallBold)
                .padding(.horizontal, PrepFlowSpacing.sm)
                .frame(height: PrepFlowMetric.catalogFieldHeight)
                .background(PrepFlowColor.white)
                .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous)
                        .stroke(PrepFlowColor.g4, lineWidth: PrepFlowMetric.lineWidth)
                }
        }
    }
}

// 正本: design/p1-wireframe-template-editor-liquidglass.png
private struct CatalogReadOnlyField: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.xs) {
            CatalogLabel(label)
            Text(value)
                .font(PrepFlowFont.smallBold)
                .padding(.horizontal, PrepFlowSpacing.sm)
                .frame(maxWidth: .infinity, minHeight: PrepFlowMetric.catalogFieldHeight, alignment: .leading)
                .background(PrepFlowColor.white)
                .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous)
                        .stroke(PrepFlowColor.g4, lineWidth: PrepFlowMetric.lineWidth)
                }
        }
    }
}

// 正本: design/p1-wireframe-template-editor-liquidglass.png
private struct CatalogNumberField: View {
    let label: String
    let value: Double
    let unit: String
    let update: @MainActor @Sendable (Double) -> Void

    var body: some View {
        CatalogUnitField(label: label, value: formatted(value), unit: unit) { text in
            if let number = Double(text) {
                update(number)
            }
        }
    }

    private func formatted(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0 ... 2)))
    }
}

// 正本: design/p1-wireframe-template-editor-liquidglass.png
private struct CatalogIntegerField: View {
    let label: String
    let value: Int
    let unit: String
    let update: @MainActor @Sendable (Int) -> Void

    var body: some View {
        CatalogUnitField(label: label, value: String(value), unit: unit) { text in
            if let number = Int(text) {
                update(number)
            }
        }
    }
}

// 正本: design/p1-wireframe-template-editor-liquidglass.png
private struct CatalogUnitField: View {
    let label: String
    let value: String
    let unit: String
    let update: @MainActor @Sendable (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.xs) {
            CatalogLabel(label)
            HStack(spacing: PrepFlowSpacing.none) {
                TextField("", text: Binding(get: { value }, set: { nextValue in
                    Task { @MainActor in
                        update(nextValue)
                    }
                }))
                .font(PrepFlowFont.smallBold)
                .monospacedDigit()
                .padding(.horizontal, PrepFlowSpacing.sm)
                Text(unit)
                    .font(PrepFlowFont.small)
                    .foregroundStyle(PrepFlowColor.g2)
                    .padding(.horizontal, PrepFlowSpacing.sm)
                    .frame(maxHeight: .infinity)
                    .background(PrepFlowColor.g5)
            }
            .frame(height: PrepFlowMetric.catalogFieldHeight)
            .background(PrepFlowColor.white)
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous)
                    .stroke(PrepFlowColor.g4, lineWidth: PrepFlowMetric.lineWidth)
            }
        }
    }
}

// 正本: design/p1-wireframe-prepitem-editor.png
private struct CatalogScaleOption: View {
    let title: String
    let subtitle: String
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.xxs) {
            Text(title)
                .font(PrepFlowFont.smallBold)
            Text(subtitle)
                .font(PrepFlowFont.railMeta)
                .foregroundStyle(PrepFlowColor.g2)
        }
        .padding(PrepFlowSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PrepFlowColor.white)
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous)
                .stroke(isSelected ? PrepFlowColor.ink : PrepFlowColor.g4, lineWidth: isSelected ? PrepFlowMetric.heavyLineWidth : PrepFlowMetric.lineWidth)
        }
    }
}

// 正本: design/p1-wireframe-template-editor-liquidglass.png
private struct CatalogTextArea: View {
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.xs) {
            CatalogLabel("手順テキスト")
            TextEditor(text: $text)
                .font(PrepFlowFont.small)
                .scrollContentBackground(.hidden)
                .padding(PrepFlowSpacing.sm)
                .frame(minHeight: PrepFlowMetric.bottomBarHeight)
                .background(PrepFlowColor.white)
                .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous)
                        .stroke(PrepFlowColor.g4, lineWidth: PrepFlowMetric.lineWidth)
                }
        }
    }
}

// 正本: design/p1-wireframe-template-editor-liquidglass.png
private struct CatalogMediaStrip: View {
    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.xs) {
            CatalogLabel("手順メディア（P0はテキストのみ・枠を保持）")
            HStack(spacing: PrepFlowSpacing.sm) {
                CatalogMediaThumb(title: "手順写真1")
                CatalogMediaThumb(title: "完成見本")
                CatalogMediaThumb(title: "動画")
                CatalogMediaThumb(title: "＋ 追加", isAdd: true)
            }
            .padding(PrepFlowSpacing.sm)
            .background(PrepFlowColor.white)
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous)
                    .stroke(PrepFlowColor.g4, lineWidth: PrepFlowMetric.lineWidth)
            }
        }
    }
}

// 正本: design/p1-wireframe-template-editor-liquidglass.png
private struct CatalogMediaThumb: View {
    let title: String
    var isAdd = false

    var body: some View {
        Text(title)
            .font(PrepFlowFont.railMeta)
            .foregroundStyle(isAdd ? PrepFlowColor.ink : PrepFlowColor.g2)
            .frame(width: PrepFlowMetric.catalogMediaThumbWidth, height: PrepFlowMetric.catalogMediaThumbHeight)
            .background(isAdd ? PrepFlowColor.white : PrepFlowColor.g5)
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous)
                    .stroke(isAdd ? PrepFlowColor.g3 : PrepFlowColor.g4, style: StrokeStyle(lineWidth: PrepFlowMetric.lineWidth, dash: isAdd ? [PrepFlowSpacing.xs] : []))
            }
    }
}

// 正本: design/p1-wireframe-prepitem-editor.png
private struct CatalogPreview: View {
    let task: CatalogPrepTask
    let quantity: Quantity
    let saveCount: Int
    let summary: String?
    let savedAt: String?

    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.md) {
            Text("ボード数量プレビュー")
                .font(PrepFlowFont.sectionTitle)
            Text("14名・入力中の係数/歩留りをEngineで計算")
                .font(PrepFlowFont.railMeta)
                .foregroundStyle(PrepFlowColor.g2)

            VStack(alignment: .leading, spacing: PrepFlowSpacing.sm) {
                HStack {
                    Text(task.name)
                        .font(PrepFlowFont.smallBold)
                    Spacer()
                    Text("\(Int(quantity.total))\(quantity.unit)")
                        .font(PrepFlowFont.countdownValue)
                        .monospacedDigit()
                }
                Divider()
                    .background(PrepFlowColor.g4)
                Text("15:00 着手・\(task.durationMin)分・\(task.sectionName)")
                    .font(PrepFlowFont.small)
                    .foregroundStyle(PrepFlowColor.g2)
            }
            .padding(PrepFlowSpacing.md)
            .background(PrepFlowColor.white)
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous)
                    .stroke(PrepFlowColor.g4, lineWidth: PrepFlowMetric.lineWidth)
            }

            if let summary {
                CatalogSavedStatus(saveCount: saveCount, summary: summary, savedAt: savedAt)
            }

            Spacer()
        }
        .padding(PrepFlowSpacing.md)
        .background(PrepFlowColor.white.opacity(PrepFlowOpacity.contentHeader))
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(PrepFlowColor.g4)
                .frame(width: PrepFlowMetric.lineWidth)
        }
    }
}

// 正本: design/p1-wireframe-template-editor-liquidglass.png
private struct CatalogSavedStatus: View {
    let saveCount: Int
    let summary: String
    let savedAt: String?

    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.xs) {
            HStack {
                Text("保存済み")
                    .font(PrepFlowFont.smallBold)
                Spacer()
                Text("\(saveCount)回")
                    .font(PrepFlowFont.railMeta)
                    .foregroundStyle(PrepFlowColor.g2)
                    .monospacedDigit()
            }
            Text(summary)
                .font(PrepFlowFont.railMeta)
                .foregroundStyle(PrepFlowColor.g2)
            Text(savedAt ?? "ローカル保存済み")
                .font(PrepFlowFont.railMeta)
                .foregroundStyle(PrepFlowColor.g2)
        }
        .padding(PrepFlowSpacing.sm)
        .background(PrepFlowColor.g5)
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
    }
}

// 正本: design/p1-wireframe-template-editor-liquidglass.png
private struct CatalogLabel: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(PrepFlowFont.railMeta)
            .foregroundStyle(PrepFlowColor.g2)
    }
}

private struct GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PrepFlowFont.smallBold)
            .foregroundStyle(PrepFlowColor.ink)
            .padding(.horizontal, PrepFlowSpacing.md)
            .padding(.vertical, PrepFlowSpacing.sm)
            .background(PrepFlowColor.white.opacity(PrepFlowOpacity.glass))
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous)
                    .stroke(PrepFlowColor.white.opacity(PrepFlowOpacity.glassStroke), lineWidth: PrepFlowMetric.lineWidth)
            }
            .opacity(configuration.isPressed ? PrepFlowOpacity.contentHeader : 1)
            .glassEffect()
    }
}

private struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PrepFlowFont.smallBold)
            .foregroundStyle(PrepFlowColor.white)
            .padding(.horizontal, PrepFlowSpacing.lg)
            .padding(.vertical, PrepFlowSpacing.sm)
            .background(PrepFlowColor.ink)
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
            .opacity(configuration.isPressed ? PrepFlowOpacity.contentHeader : 1)
    }
}

private struct DashedTreeButtonStyle: ButtonStyle {
    enum Inset {
        case dish
        case component
        case task
    }

    let inset: Inset

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PrepFlowFont.railMeta)
            .foregroundStyle(PrepFlowColor.g2)
            .padding(.vertical, PrepFlowSpacing.xs)
            .padding(.horizontal, PrepFlowSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(PrepFlowColor.clear)
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous)
                    .stroke(PrepFlowColor.g3, style: StrokeStyle(lineWidth: PrepFlowMetric.lineWidth, dash: [PrepFlowSpacing.xs]))
            }
            .padding(.leading, leadingPadding)
            .padding(.trailing, PrepFlowSpacing.md)
            .opacity(configuration.isPressed ? PrepFlowOpacity.contentHeader : 1)
    }

    private var leadingPadding: CGFloat {
        switch inset {
        case .dish:
            PrepFlowSpacing.md
        case .component:
            PrepFlowSpacing.md
        case .task:
            PrepFlowSpacing.xxl
        }
    }
}
