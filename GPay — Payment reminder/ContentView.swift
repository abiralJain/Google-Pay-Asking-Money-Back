//
//  ContentView.swift
//  GPay — Payment reminder
//
//  Created by Abiral Jain on 10/06/26.
//
//  Satire: UPI made splitting easy. Asking for your ₹350 back is still
//  emotionally impossible. The Awkwardness slider quantifies the exact
//  amount of friendship damage you're willing to do.
//

import SwiftUI

// MARK: - Google Pay palette (sampled from the real iOS app)

enum GPay {
    static let blue       = Color(red: 26/255,  green: 115/255, blue: 232/255) // #1A73E8
    static let green      = Color(red: 30/255,  green: 142/255, blue: 62/255)  // #1E8E3E
    static let amber      = Color(red: 249/255, green: 171/255, blue: 0/255)   // #F9AB00
    static let deepOrange = Color(red: 217/255, green: 94/255,  blue: 0/255)   // #D95E00
    static let red        = Color(red: 217/255, green: 48/255,  blue: 37/255)  // #D93025
    static let ink        = Color(red: 32/255,  green: 33/255,  blue: 36/255)  // #202124
    static let gray       = Color(red: 95/255,  green: 99/255,  blue: 104/255) // #5F6368
    static let surface    = Color(red: 241/255, green: 243/255, blue: 244/255) // #F1F3F4
    static let outline    = Color(red: 218/255, green: 220/255, blue: 224/255) // #DADCE0
    static let purple     = Color(red: 147/255, green: 52/255,  blue: 230/255) // #9334E6
}

// MARK: - The five levels of friendship damage

enum Awkwardness: Int, CaseIterable {
    case saint, nudge, persistent, passiveAggressive, nuclear

    var label: String {
        switch self {
        case .saint:             "Saint"
        case .nudge:             "Gentle nudge"
        case .persistent:        "Persistent"
        case .passiveAggressive: "Passive-aggressive"
        case .nuclear:           "Nuclear"
        }
    }

    var emoji: String {
        switch self {
        case .saint:             "😇"
        case .nudge:             "🙂"
        case .persistent:        "😬"
        case .passiveAggressive: "🙃"
        case .nuclear:           "☢️"
        }
    }

    var message: String {
        switch self {
        case .saint:
            "Hey Rohan! Absolutely no rush on the ₹350 — whenever works for you! Hope the family's doing great 😊"
        case .nudge:
            "Hey! That ₹350 from Saturday's dinner… no pressure 😅"
        case .persistent:
            "Reminder #4: ₹350. I remember, Rohan. I always remember."
        case .passiveAggressive:
            "Saw your Goa story — looked pricey! Anyway, totally unrelated: ₹350."
        case .nuclear:
            "Adding your mother to this chat."
        }
    }

    var sendLabel: String {
        switch self {
        case .saint:             "Send (no rush!)"
        case .nudge:             "Send nudge"
        case .persistent:        "Send reminder #4"
        case .passiveAggressive: "Send with love ✨"
        case .nuclear:           "Add Mummy to chat"
        }
    }

    var caption: String {
        switch self {
        case .saint:             "Friendship preserved. ₹350 gone forever."
        case .nudge:             "Deniability: plausible."
        case .persistent:        "He has seen all three. He will see this one."
        case .passiveAggressive: "Technically, this is still friendly."
        case .nuclear:           "There is no coming back from this."
        }
    }

    var aftermath: String {
        switch self {
        case .saint:             "Rohan hearted your message. No transfer detected."
        case .nudge:             "Seen. Rohan has chosen peace."
        case .persistent:        "Seen. Read receipts are his love language."
        case .passiveAggressive: "Rohan is typing… Rohan stopped typing."
        case .nuclear:           "Seen immediately."
        }
    }

    var color: Color {
        switch self {
        case .saint:             GPay.green
        case .nudge:             GPay.blue
        case .persistent:        GPay.amber
        case .passiveAggressive: GPay.deepOrange
        case .nuclear:           GPay.red
        }
    }

    // Amber needs dark text to stay readable; everything else takes white.
    var textColor: Color {
        self == .persistent ? GPay.ink : .white
    }
}

// MARK: - Chat thread model

struct ChatItem: Identifiable, Equatable {
    enum Sender: Equatable { case rohan, mummy }
    enum Kind: Equatable {
        case dateChip(String)
        case splitCard
        case received(String, time: String, sender: Sender)
        case sent(String, stage: Int)
        case system(String)
        case typing
    }
    let id = UUID()
    let kind: Kind

    static let mock: [ChatItem] = [
        ChatItem(kind: .dateChip("Saturday • 11:48 PM")),
        ChatItem(kind: .splitCard),
        ChatItem(kind: .received("bro yes tonight 100%", time: "6d", sender: .rohan)),
        ChatItem(kind: .received("👍", time: "4d", sender: .rohan)),
    ]
}

// MARK: - Root screen

struct ContentView: View {
    @State private var awkwardness: Double = 0      // 0…4, continuous while dragging
    @State private var isDragging = false
    @State private var thread = ChatItem.mock
    @State private var hasSent = false
    @State private var status: String?
    @Namespace private var bubbleNS

    private var stage: Awkwardness {
        Awkwardness(rawValue: Int(awkwardness.rounded().clamped(to: 0...4)))!
    }

    /// Piecewise-linear friendship damage so the meter creeps while dragging.
    private var damage: Double {
        let anchors: [Double] = [0, 12, 47, 78, 100]
        let v = awkwardness.clamped(to: 0...4)
        let i = min(Int(v), 3)
        return anchors[i] + (anchors[i + 1] - anchors[i]) * (v - Double(i))
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            chatThread
            controlPanel
        }
        .background(Color.white)
        // Escalating haptics every time the slider crosses a stage boundary.
        .sensoryFeedback(trigger: stage) { _, new in
            switch new {
            case .saint:             .impact(weight: .light, intensity: 0.4)
            case .nudge:             .impact(weight: .light, intensity: 0.6)
            case .persistent:        .impact(weight: .medium, intensity: 0.8)
            case .passiveAggressive: .impact(weight: .heavy, intensity: 0.9)
            case .nuclear:           .warning
            }
        }
        // Grab / release of the thumb gets its own gesture-phase feedback.
        .sensoryFeedback(trigger: isDragging) { _, began in
            began ? .impact(weight: .light, intensity: 0.5)
                  : .impact(weight: .medium, intensity: 0.7)
        }
        .sensoryFeedback(trigger: hasSent) { _, sent in
            guard sent else { return nil }
            return stage == .nuclear ? .error : .success
        }
    }

    // MARK: Header (pixel-matched to the GPay chat top bar)

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.left")
                .font(.system(size: 19, weight: .medium))
                .foregroundStyle(GPay.ink)

            avatar("R", color: GPay.purple, size: 36)

            VStack(alignment: .leading, spacing: 1) {
                Text("Rohan Sharma")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(GPay.ink)
                Text("+91 98765 43210 • owes you ₹350")
                    .font(.system(size: 12))
                    .foregroundStyle(GPay.gray)
            }

            Spacer()

            Image(systemName: "ellipsis")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(GPay.ink)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white)
        .overlay(alignment: .bottom) {
            Rectangle().fill(GPay.outline.opacity(0.6)).frame(height: 0.5)
        }
    }

    // MARK: Chat thread

    private var chatThread: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(thread) { item in
                        row(for: item)
                            .scrollTransition(.animated(.spring(duration: 0.4, bounce: 0.2))) { content, phase in
                                content
                                    .opacity(phase.isIdentity ? 1 : 0.3)
                                    .offset(y: phase.isIdentity ? 0 : 10)
                            }
                    }

                    if !hasSent { draftBubble }

                    if let status {
                        Text(status)
                            .font(.system(size: 11))
                            .foregroundStyle(GPay.gray)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .transition(.opacity)
                            .contentTransition(.opacity)
                    }

                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .scrollIndicators(.hidden)
            .onChange(of: thread.count) {
                withAnimation(.spring(duration: 0.4, bounce: 0.15)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
        }
    }

    @ViewBuilder
    private func row(for item: ChatItem) -> some View {
        switch item.kind {
        case .dateChip(let text):
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(GPay.gray)
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(GPay.surface, in: Capsule())

        case .splitCard:
            splitRequestCard
                .frame(maxWidth: .infinity, alignment: .trailing)

        case .received(let text, let time, let sender):
            HStack(alignment: .bottom, spacing: 8) {
                avatar(sender == .rohan ? "R" : "M",
                       color: sender == .rohan ? GPay.purple : GPay.amber,
                       size: 26)
                VStack(alignment: .leading, spacing: 2) {
                    Text(text)
                        .font(.system(size: 15))
                        .foregroundStyle(GPay.ink)
                        .padding(.horizontal, 14).padding(.vertical, 9)
                        .background(GPay.surface, in: BubbleShape(myMessage: false))
                    Text(time)
                        .font(.system(size: 10))
                        .foregroundStyle(GPay.gray.opacity(0.8))
                        .padding(.leading, 6)
                }
                Spacer(minLength: 60)
            }

        case .sent(let text, let stageRaw):
            let s = Awkwardness(rawValue: stageRaw) ?? .nudge
            Text(text)
                .font(.system(size: 15))
                .foregroundStyle(s.textColor)
                .padding(.horizontal, 14).padding(.vertical, 9)
                .background(s.color, in: BubbleShape(myMessage: true))
                .frame(maxWidth: 280, alignment: .trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .matchedGeometryEffect(id: "draft", in: bubbleNS)

        case .system(let text):
            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(GPay.gray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 2)

        case .typing:
            HStack(alignment: .bottom, spacing: 8) {
                avatar("R", color: GPay.purple, size: 26)
                TypingDots()
                    .padding(.horizontal, 16).padding(.vertical, 12)
                    .background(GPay.surface, in: BubbleShape(myMessage: false))
                Spacer(minLength: 60)
            }
        }
    }

    // GPay "Split request" card, matched to the real one.
    private var splitRequestCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Split request")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(GPay.ink)
            Text("₹350.00")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(GPay.ink)
            Text("Dinner at Pind Balluchi 🍛")
                .font(.system(size: 12))
                .foregroundStyle(GPay.gray)

            ProgressView(value: 0.33)
                .tint(GPay.blue)
                .scaleEffect(y: 0.8)

            HStack(spacing: 5) {
                Image(systemName: "clock")
                    .font(.system(size: 11))
                Text("1 of 3 paid • 6 days ago")
                    .font(.system(size: 11))
            }
            .foregroundStyle(GPay.gray)
        }
        .padding(14)
        .frame(width: 220, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(GPay.outline, lineWidth: 1)
        )
    }

    // The live-morphing preview. Color, size and text all follow the slider;
    // past "passive-aggressive" the bubble itself starts to tremble.
    private var draftBubble: some View {
        let trembleAmp = max(0, awkwardness - 2.6) * 1.8

        return VStack(alignment: .trailing, spacing: 5) {
            Text("PREVIEW")
                .font(.system(size: 9, weight: .bold))
                .kerning(1.2)
                .foregroundStyle(GPay.gray.opacity(0.7))

            TimelineView(.animation(minimumInterval: 1 / 60, paused: trembleAmp <= 0)) { context in
                // The text pops between stages; the bubble around it morphs
                // continuously (color, size, tremble) so the matched-geometry
                // identity never changes mid-drag.
                ZStack {
                    Text(stage.message)
                        .font(.system(size: 15))
                        .foregroundStyle(stage.textColor)
                        .id(stage)
                        .transition(.blurReplace.combined(with: .scale(0.92, anchor: .bottomTrailing)))
                }
                .padding(.horizontal, 14).padding(.vertical, 9)
                .background(stage.color, in: BubbleShape(myMessage: true))
                .overlay(
                    BubbleShape(myMessage: true)
                        .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                        .foregroundStyle(stage.color.opacity(0.45))
                        .padding(-4)
                )
                .distortionEffect(
                    ShaderLibrary.tremble(
                        .float(Float(context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1000))),
                        .float(Float(trembleAmp))
                    ),
                    maxSampleOffset: CGSize(width: 8, height: 8)
                )
            }
            .matchedGeometryEffect(id: "draft", in: bubbleNS)
        }
        .frame(maxWidth: 280, alignment: .trailing)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .animation(.spring(duration: 0.45, bounce: 0.35), value: stage)
    }

    // MARK: Control panel — the punchline

    private var controlPanel: some View {
        VStack(spacing: 14) {
            damageMeter
            AwkwardnessSlider(value: $awkwardness, isDragging: $isDragging, stage: stage)
                .disabled(hasSent)
                .opacity(hasSent ? 0.45 : 1)

            Text(stage.caption)
                .font(.system(size: 12).italic())
                .foregroundStyle(GPay.gray)
                .id(stage.caption)
                .transition(.blurReplace)
                .animation(.spring(duration: 0.35, bounce: 0.2), value: stage)

            sendButton
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 8)
        .background(Color.white)
        .overlay(alignment: .top) {
            Rectangle().fill(GPay.outline.opacity(0.6)).frame(height: 0.5)
        }
    }

    private var damageMeter: some View {
        HStack(spacing: 10) {
            Text("Friendship damage")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(GPay.gray)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(GPay.surface)
                    Capsule()
                        .fill(stage.color)
                        .frame(width: max(6, geo.size.width * damage / 100))
                }
            }
            .frame(height: 6)
            .animation(.spring(duration: 0.35, bounce: 0.2), value: damage)

            Text("\(Int(damage))%")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(stage.color)
                .contentTransition(.numericText(value: damage))
                .animation(.spring(duration: 0.3), value: Int(damage))
                .monospacedDigit()
                .frame(width: 44, alignment: .trailing)
        }
    }

    @ViewBuilder
    private var sendButton: some View {
        if hasSent {
            Button {
                withAnimation(.spring(duration: 0.5, bounce: 0.25)) {
                    thread = ChatItem.mock
                    status = nil
                    hasSent = false
                }
            } label: {
                Text("Draft another reminder")
                    .font(.system(size: 15, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.glass)
            .transition(.blurReplace)
        } else {
            Button {
                send()
            } label: {
                HStack(spacing: 8) {
                    Text(stage.emoji)
                    Text(stage.sendLabel)
                        .font(.system(size: 15, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(.glassProminent)
            .tint(stage.color)
            .animation(.spring(duration: 0.35, bounce: 0.25), value: stage)
        }
    }

    // MARK: Send + aftermath

    private func send() {
        let s = stage
        withAnimation(.spring(duration: 0.55, bounce: 0.3)) {
            hasSent = true
            thread.append(ChatItem(kind: .sent(s.message, stage: s.rawValue)))
        }
        Task { await runAftermath(for: s) }
    }

    private func runAftermath(for s: Awkwardness) async {
        try? await Task.sleep(for: .seconds(0.9))
        setStatus(s == .nuclear ? "Seen immediately" : "Seen just now")

        if s == .nuclear {
            try? await Task.sleep(for: .seconds(1.3))
            append(.system("Rohan left the chat"))
            try? await Task.sleep(for: .seconds(1.1))
            append(.system("Mummy joined the chat"))
            try? await Task.sleep(for: .seconds(1.4))
            append(.received("Beta. Call me.", time: "now", sender: .mummy))
            try? await Task.sleep(for: .seconds(1.2))
            append(.received("₹350 sent to you", time: "now", sender: .mummy))
            setStatus("Debt recovered. Friendship not included.")
        } else {
            try? await Task.sleep(for: .seconds(1.1))
            append(.typing)
            try? await Task.sleep(for: .seconds(2.4))
            removeTyping()
            try? await Task.sleep(for: .seconds(0.7))
            setStatus(s.aftermath)
        }
    }

    private func append(_ kind: ChatItem.Kind) {
        withAnimation(.spring(duration: 0.5, bounce: 0.35)) {
            thread.append(ChatItem(kind: kind))
        }
    }

    private func removeTyping() {
        withAnimation(.spring(duration: 0.4, bounce: 0.2)) {
            thread.removeAll { $0.kind == .typing }
        }
    }

    private func setStatus(_ text: String) {
        withAnimation(.easeInOut(duration: 0.3)) { status = text }
    }

    private func avatar(_ initial: String, color: Color, size: CGFloat) -> some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .overlay(
                Text(initial)
                    .font(.system(size: size * 0.44, weight: .medium))
                    .foregroundStyle(.white)
            )
    }
}

// MARK: - The Awkwardness slider

struct AwkwardnessSlider: View {
    @Binding var value: Double      // 0…4
    @Binding var isDragging: Bool
    let stage: Awkwardness

    @Namespace private var glassNS
    private let thumbSize: CGFloat = 48

    var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                let trackWidth = geo.size.width - thumbSize
                let thumbX = trackWidth * value.clamped(to: 0...4) / 4

                ZStack(alignment: .leading) {
                    // Track: gray base with a green→red gradient revealed up to the thumb.
                    Capsule()
                        .fill(GPay.surface)
                        .frame(height: 8)
                        .padding(.horizontal, thumbSize / 2)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [GPay.green, GPay.blue, GPay.amber, GPay.deepOrange, GPay.red],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(height: 8)
                        .padding(.horizontal, thumbSize / 2)
                        .mask(alignment: .leading) {
                            Rectangle().frame(width: thumbX + thumbSize / 2)
                        }

                    // Stage tick dots
                    HStack(spacing: 0) {
                        ForEach(Awkwardness.allCases, id: \.rawValue) { s in
                            Circle()
                                .fill(s.rawValue <= Int(value.rounded()) ? .white : GPay.outline)
                                .frame(width: 4, height: 4)
                            if s != .nuclear { Spacer() }
                        }
                    }
                    .padding(.horizontal, thumbSize / 2 - 2)

                    // Glass thumb. The container lets the chip and thumb read as
                    // one piece of liquid glass that morphs as it travels.
                    GlassEffectContainer(spacing: 12) {
                        ZStack {
                            if stage == .nuclear { NuclearPulse() }

                            Text(stage.emoji)
                                .font(.system(size: 23))
                                .id(stage.emoji)
                                .transition(.scale(0.4).combined(with: .opacity))
                                .frame(width: thumbSize, height: thumbSize)
                                .glassEffect(
                                    .regular.tint(stage.color.opacity(0.28)).interactive(),
                                    in: .circle
                                )
                                .glassEffectID("thumb", in: glassNS)
                        }
                        .scaleEffect(isDragging ? 1.18 : 1)
                        .animation(.spring(duration: 0.3, bounce: 0.5), value: isDragging)
                        .animation(.spring(duration: 0.3, bounce: 0.4), value: stage)
                    }
                    .offset(x: thumbX)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { g in
                            isDragging = true
                            let fraction = ((g.location.x - thumbSize / 2) / trackWidth)
                                .clamped(to: 0...1)
                            // Track the finger raw — no animation lag mid-gesture.
                            value = fraction * 4
                        }
                        .onEnded { _ in
                            isDragging = false
                            withAnimation(.spring(duration: 0.35, bounce: 0.45)) {
                                value = value.rounded()
                            }
                        }
                )
            }
            .frame(height: 56)
            .accessibilityElement()
            .accessibilityLabel("Awkwardness")
            .accessibilityValue(stage.label)
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: value = min(4, value.rounded() + 1)
                case .decrement: value = max(0, value.rounded() - 1)
                @unknown default: break
                }
            }

            HStack {
                Text("Polite")
                Spacer()
                Text(stage.label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(stage.color)
                    .id(stage.label)
                    .transition(.blurReplace)
                Spacer()
                Text("Scorched earth")
            }
            .font(.system(size: 11))
            .foregroundStyle(GPay.gray)
            .animation(.spring(duration: 0.3, bounce: 0.2), value: stage)
        }
    }
}

// Expanding ring behind the thumb at stage 4. KeyframeAnimator restarts
// each repetition; `trigger` keeps it running while nuclear is active.
struct NuclearPulse: View {
    var body: some View {
        KeyframeAnimator(initialValue: 1.0, repeating: true) { scale in
            Circle()
                .stroke(GPay.red.opacity(max(0, 2 - scale)), lineWidth: 2)
                .frame(width: 48, height: 48)
                .scaleEffect(scale)
        } keyframes: { _ in
            LinearKeyframe(1.0, duration: 0.05)
            CubicKeyframe(1.9, duration: 1.0)
        }
    }
}

// Three-dot typing indicator driven by PhaseAnimator.
struct TypingDots: View {
    var body: some View {
        PhaseAnimator([0, 1, 2]) { phase in
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(GPay.gray.opacity(phase == i ? 0.9 : 0.35))
                        .frame(width: 6, height: 6)
                        .offset(y: phase == i ? -2 : 0)
                }
            }
        } animation: { _ in
            .easeInOut(duration: 0.28)
        }
    }
}

// GPay message bubble: big continuous corners, one tight corner on the
// sender's side, same as the real app.
struct BubbleShape: Shape {
    let myMessage: Bool

    func path(in rect: CGRect) -> Path {
        let big: CGFloat = 18
        let small: CGFloat = 5
        return Path(
            roundedRect: rect,
            cornerRadii: RectangleCornerRadii(
                topLeading: big,
                bottomLeading: myMessage ? big : small,
                bottomTrailing: myMessage ? small : big,
                topTrailing: big
            ),
            style: .continuous
        )
    }
}

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}

#Preview {
    ContentView()
}
