// 正本: design/p0-wireframe-service-setup-liquidglass.png
import DesignTokens
import Engine
import SwiftUI

struct ServiceSetupView: View {
    @StateObject private var store: BoardStore

    init(store: BoardStore = BoardStore()) {
        _store = StateObject(wrappedValue: store)
    }

    var body: some View {
        ZStack(alignment: .top) {
            PrepFlowColor.g5.ignoresSafeArea()

            HStack(spacing: PrepFlowSpacing.none) {
                ReservationList(service: store.service)
                ServiceCoversPanel(store: store)
                    .frame(width: PrepFlowMetric.railWidth)
            }
            .padding(.top, PrepFlowMetric.topInset + PrepFlowMetric.topBarHeight)

            VStack(spacing: PrepFlowSpacing.sm) {
                ServiceTopBar()
                ServiceControlStrip(store: store)
            }
            .padding(PrepFlowSpacing.md)
        }
        .foregroundStyle(PrepFlowColor.ink)
    }
}

// 正本: design/p0-wireframe-service-setup-liquidglass.png
private struct ServiceTopBar: View {
    var body: some View {
        GlassEffectContainer {
            HStack {
                VStack(alignment: .leading, spacing: PrepFlowSpacing.xxs) {
                    Text("本日のサービス設定")
                        .font(PrepFlowFont.topTitle)
                    Text("鮨 はやし ・ STEP 1/2 → 当日ボード生成")
                        .font(PrepFlowFont.topSubtitle)
                        .foregroundStyle(PrepFlowColor.g2)
                }

                Spacer()

                HStack(spacing: PrepFlowSpacing.none) {
                    Text("STEP 1/2 ・ 設定 → ")
                        .font(PrepFlowFont.smallBold)
                        .foregroundStyle(PrepFlowColor.g2)
                    Text("当日ボード生成")
                        .font(PrepFlowFont.smallBold)
                        .foregroundStyle(PrepFlowColor.ink)
                }
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

// 正本: design/p0-wireframe-service-setup-liquidglass.png
private struct ServiceControlStrip: View {
    @ObservedObject var store: BoardStore

    var body: some View {
        GlassEffectContainer {
            HStack(spacing: PrepFlowSpacing.lg) {
                ServiceControl(label: "日付", value: store.service.displayDate)
                ServicePeriodToggle(period: store.service.period)
                ServiceOpenTimeControl(openTime: store.service.openTime) {
                    store.updateOpenTime($0)
                }

                Spacer()

                HStack(spacing: PrepFlowSpacing.xxs) {
                    MethodChip(title: "手入力", isSelected: true)
                    MethodChip(title: "メール取込（準備中）", isSelected: false, isDimmed: true)
                    MethodChip(title: "CSV・貼付", isSelected: false)
                }
                .padding(PrepFlowSpacing.xxs)
                .background(PrepFlowColor.ink.opacity(PrepFlowOpacity.selection))
                .clipShape(Capsule(style: .continuous))
            }
            .padding(.horizontal, PrepFlowSpacing.lg)
            .frame(height: PrepFlowMetric.bottomBarHeight)
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

// 正本: design/p0-wireframe-service-setup-liquidglass.png
private struct ServiceControl: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.xxs) {
            Text(label)
                .font(PrepFlowFont.countdownLabel)
                .foregroundStyle(PrepFlowColor.g2)
            Text(value)
                .font(PrepFlowFont.smallBold)
                .padding(.horizontal, PrepFlowSpacing.sm)
                .padding(.vertical, PrepFlowSpacing.xs)
                .background(PrepFlowColor.white.opacity(PrepFlowOpacity.glassStroke))
                .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
        }
    }
}

// 正本: design/p0-wireframe-service-setup-liquidglass.png
private struct ServiceOpenTimeControl: View {
    let openTime: String
    let update: @MainActor @Sendable (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.xxs) {
            Text("開店時刻（T=0）")
                .font(PrepFlowFont.countdownLabel)
                .foregroundStyle(PrepFlowColor.g2)
            TextField("", text: Binding(get: { openTime }, set: { nextValue in
                Task { @MainActor in
                    update(nextValue)
                }
            }))
            .font(PrepFlowFont.smallBold)
            .monospacedDigit()
            .padding(.horizontal, PrepFlowSpacing.sm)
            .padding(.vertical, PrepFlowSpacing.xs)
            .frame(minWidth: PrepFlowMetric.countdownRingInner * PrepFlowSpacing.xs)
            .background(PrepFlowColor.white.opacity(PrepFlowOpacity.glassStroke))
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
        }
    }
}

// 正本: design/p0-wireframe-service-setup-liquidglass.png
private struct ServicePeriodToggle: View {
    let period: String

    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.xxs) {
            Text("営業")
                .font(PrepFlowFont.countdownLabel)
                .foregroundStyle(PrepFlowColor.g2)
            HStack(spacing: PrepFlowSpacing.none) {
                Text("昼")
                    .font(PrepFlowFont.smallBold)
                    .foregroundStyle(PrepFlowColor.g2)
                    .padding(.horizontal, PrepFlowSpacing.md)
                    .padding(.vertical, PrepFlowSpacing.xs)
                Text(period)
                    .font(PrepFlowFont.smallBold)
                    .foregroundStyle(PrepFlowColor.white)
                    .padding(.horizontal, PrepFlowSpacing.md)
                    .padding(.vertical, PrepFlowSpacing.xs)
                    .background(PrepFlowColor.ink)
            }
            .clipShape(Capsule(style: .continuous))
            .background(PrepFlowColor.ink.opacity(PrepFlowOpacity.selection), in: Capsule(style: .continuous))
        }
    }
}

// 正本: design/p0-wireframe-service-setup-liquidglass.png
private struct MethodChip: View {
    let title: String
    let isSelected: Bool
    var isDimmed = false

    var body: some View {
        Text(title)
            .font(PrepFlowFont.railMeta)
            .foregroundStyle(isDimmed ? PrepFlowColor.g3 : (isSelected ? PrepFlowColor.ink : PrepFlowColor.g2))
            .padding(.horizontal, PrepFlowSpacing.md)
            .padding(.vertical, PrepFlowSpacing.xs)
            .background(isSelected ? PrepFlowColor.white : PrepFlowColor.clear)
            .clipShape(Capsule(style: .continuous))
    }
}

// 正本: design/p0-wireframe-service-setup-liquidglass.png
private struct ReservationList: View {
    let service: ServiceDaySettings

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PrepFlowSpacing.sm) {
                Text("本日の予約（手入力）")
                    .font(PrepFlowFont.sectionTitle)
                Text("コース別の人数を確定すると、数量算出・逆算タイムラインが生成されます。")
                    .font(PrepFlowFont.railMeta)
                    .foregroundStyle(PrepFlowColor.g2)

                ForEach(service.reservations) { reservation in
                    ReservationRow(reservation: reservation)
                }

                Button("＋ 予約を手入力で追加") {}
                    .buttonStyle(ServiceDashedButtonStyle())

                HStack(spacing: PrepFlowSpacing.sm) {
                    Image(systemName: "envelope")
                        .font(PrepFlowFont.small)
                        .foregroundStyle(PrepFlowColor.g2)
                    Text("メール取込（FR-10）は準備中。")
                        .font(PrepFlowFont.smallBold)
                    Text("当面はCSV/手入力で運用。")
                        .font(PrepFlowFont.small)
                        .foregroundStyle(PrepFlowColor.g2)
                }
                .padding(PrepFlowSpacing.sm)
                .background(PrepFlowColor.g5)
                .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
            }
            .padding(.horizontal, PrepFlowSpacing.lg)
            .padding(.vertical, PrepFlowSpacing.md)
        }
        .background(PrepFlowColor.g5)
    }
}

// 正本: design/p0-wireframe-service-setup-liquidglass.png
private struct ReservationRow: View {
    let reservation: ManualReservation

    var body: some View {
        HStack(spacing: PrepFlowSpacing.md) {
            Text(reservation.visitTime)
                .font(PrepFlowFont.chip)
                .monospacedDigit()
                .frame(width: PrepFlowMetric.bottomBarHeight, alignment: .leading)
            VStack(alignment: .leading, spacing: PrepFlowSpacing.xxs) {
                Text(reservation.partyName)
                    .font(PrepFlowFont.bodyBold)
                Text(reservation.note)
                    .font(PrepFlowFont.railMeta)
                    .foregroundStyle(PrepFlowColor.g2)
            }
            Spacer()
            Text("\(reservation.covers)名")
                .font(PrepFlowFont.chip)
                .monospacedDigit()
            Button("編集") {}
                .buttonStyle(ServiceSmallButtonStyle())
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

// 正本: design/p0-wireframe-service-setup-liquidglass.png
private struct ServiceCoversPanel: View {
    @ObservedObject var store: BoardStore

    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.md) {
            Text("コース別の予約人数（確定）")
                .font(PrepFlowFont.sectionTitle)

            CoversStepper(title: "おまかせコース", value: store.service.omakaseCovers) {
                store.updateOmakaseCovers($0)
            }
            CoversStepper(title: "アラカルト/その他", value: store.service.otherCovers) {
                store.updateOtherCovers($0)
            }

            Divider()
                .background(PrepFlowColor.g4)

            HStack {
                Text("合計")
                    .font(PrepFlowFont.sectionTitle)
                Spacer()
                Text("\(store.service.totalCovers)名")
                    .font(PrepFlowFont.iconLarge)
                    .monospacedDigit()
            }

            HStack(spacing: PrepFlowSpacing.xxs) {
                Text("来店 18:00–20:00 ・ ピーク")
                    .font(PrepFlowFont.railMeta)
                    .foregroundStyle(PrepFlowColor.g2)
                Text("18:00（10名）")
                    .font(PrepFlowFont.railMeta)
                    .foregroundStyle(PrepFlowColor.time) // time-use: service peak time
            }

            Spacer()

            Button("この内容で当日ボードを生成") {}
                .buttonStyle(ServicePrimaryButtonStyle())

            Text("確定人数＋開店時刻から 数量算出・逆算（FR-03/06）を反映")
                .font(PrepFlowFont.railMeta)
                .foregroundStyle(PrepFlowColor.g2)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(PrepFlowSpacing.lg)
        .background(PrepFlowColor.white.opacity(PrepFlowOpacity.contentHeader))
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(PrepFlowColor.g4)
                .frame(width: PrepFlowMetric.lineWidth)
        }
    }
}

// 正本: design/p0-wireframe-service-setup-liquidglass.png
private struct CoversStepper: View {
    let title: String
    let value: Int
    let update: (Int) -> Void

    var body: some View {
        HStack {
            Text(title)
                .font(PrepFlowFont.smallBold)
            Spacer()
            HStack(spacing: PrepFlowSpacing.none) {
                Button("−") {
                    update(value - 1)
                }
                .buttonStyle(StepperButtonStyle())
                Text("\(value)")
                    .font(PrepFlowFont.chip)
                    .monospacedDigit()
                    .frame(width: PrepFlowMetric.actionButtonHeight)
                Button("+") {
                    update(value + 1)
                }
                .buttonStyle(StepperButtonStyle())
            }
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous)
                    .stroke(PrepFlowColor.g4, lineWidth: PrepFlowMetric.lineWidth)
            }
        }
        .padding(.vertical, PrepFlowSpacing.sm)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(PrepFlowColor.g4)
                .frame(height: PrepFlowMetric.lineWidth)
        }
    }
}

private struct ServiceSmallButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PrepFlowFont.railMeta)
            .foregroundStyle(PrepFlowColor.g2)
            .padding(.horizontal, PrepFlowSpacing.sm)
            .padding(.vertical, PrepFlowSpacing.xs)
            .background(PrepFlowColor.g5)
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous)
                    .stroke(PrepFlowColor.g4, lineWidth: PrepFlowMetric.lineWidth)
            }
            .opacity(configuration.isPressed ? PrepFlowOpacity.contentHeader : 1)
    }
}

private struct ServiceDashedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PrepFlowFont.smallBold)
            .foregroundStyle(PrepFlowColor.g2)
            .frame(maxWidth: .infinity)
            .padding(PrepFlowSpacing.md)
            .background(PrepFlowColor.clear)
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous)
                    .stroke(PrepFlowColor.g3, style: StrokeStyle(lineWidth: PrepFlowMetric.lineWidth, dash: [PrepFlowSpacing.xs]))
            }
            .opacity(configuration.isPressed ? PrepFlowOpacity.contentHeader : 1)
    }
}

private struct ServicePrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PrepFlowFont.action)
            .foregroundStyle(PrepFlowColor.white)
            .frame(maxWidth: .infinity, minHeight: PrepFlowMetric.actionButtonHeight)
            .background(PrepFlowColor.ink)
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous))
            .shadow(color: PrepFlowColor.ink.opacity(PrepFlowOpacity.glassShadow), radius: PrepFlowSpacing.md, y: PrepFlowSpacing.xs)
            .opacity(configuration.isPressed ? PrepFlowOpacity.contentHeader : 1)
    }
}

private struct StepperButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PrepFlowFont.icon)
            .foregroundStyle(PrepFlowColor.ink)
            .frame(width: PrepFlowMetric.catalogFieldHeight, height: PrepFlowMetric.catalogFieldHeight)
            .background(PrepFlowColor.g5)
            .opacity(configuration.isPressed ? PrepFlowOpacity.contentHeader : 1)
    }
}
