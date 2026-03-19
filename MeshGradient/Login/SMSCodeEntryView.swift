//
//  SMSCodeEntryView.swift
//  MeshGradient
//
//  Created by Dajun Xian on 3/18/26.
//

import SwiftUI
import Combine

struct SMSCodeEntryView: View {
    @EnvironmentObject private var authSession: AuthSession

    let countryCode: SupportedCountryCode
    let phoneNumber: String
    let onLoginSuccess: () -> Void

    private let codeLength = 4

    @State private var code: String = ""
    @State private var cooldownRemaining = 30
    @State private var isSending = false
    @State private var errorMessage: String?
    @State private var shakeTrigger: CGFloat = 0
    @State private var isHandlingFailure = false

    @FocusState private var isCodeFieldFocused: Bool

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("We sent a 4-digit verification code to \(countryCode.displayName) \(maskedPhoneNumber).")
                            .font(.body)
                            .foregroundStyle(.secondary)

                        Spacer()
                            .frame(height: 14)

                        Text("Use 0000 for testing.")
                            .font(.footnote.monospaced())
                            .foregroundStyle(.secondary)

                        Spacer()
                            .frame(height: 28)

                        centeredCodeInputRow

                        if let errorMessage {
                            Spacer()
                                .frame(height: 14)

                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(.orange)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }

                        Spacer()
                            .frame(height: 24)

                        HStack(spacing: 8) {
                            Text("Didn’t receive the code?")
                                .foregroundStyle(.secondary)

                            Button {
                                resendCode()
                            } label: {
                                Text(cooldownRemaining > 0 ? "Resend in \(cooldownRemaining)s" : "Resend Code")
                                    .foregroundStyle(cooldownRemaining > 0 ? .secondary : .primary)
                            }
                            .buttonStyle(.plain)
                            .disabled(cooldownRemaining > 0 || isSending)
                        }
                        .font(.footnote)
                        .frame(maxWidth: .infinity, alignment: .center)

                        Spacer()
                            .frame(height: 32)

                        Button {
                            completeIfPossible()
                        } label: {
                            Text("Continue")
                                .font(.headline)
                                .foregroundStyle(canContinue ? .black : .black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(canContinue ? .primary : Color.gray.opacity(0.45))
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(!canContinue)
                    }
                    .frame(maxWidth: 420, alignment: .leading)
                    .padding(.horizontal, 28)
                    .padding(.top, 24)
                    .padding(.bottom, 32)
                }
                .frame(maxWidth: .infinity)
            }

            hiddenCodeField
        }
        .preferredColorScheme(.dark)
        .navigationTitle("Enter Code")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            isCodeFieldFocused = true
        }
        .onReceive(timer) { _ in
            guard cooldownRemaining > 0 else { return }
            cooldownRemaining -= 1
        }
        .onChange(of: code) { _, newValue in
            let filtered = String(newValue.filter(\.isNumber).prefix(codeLength))
            if filtered != newValue {
                code = filtered
                return
            }

            errorMessage = nil
            isHandlingFailure = false

            if filtered.count == codeLength {
                completeIfPossible()
            }
        }
    }

    private var centeredCodeInputRow: some View {
        HStack {
            Spacer(minLength: 0)

            HStack(spacing: 12) {
                ForEach(0..<codeLength, id: \.self) { index in
                    codeBox(at: index)
                }
            }
            .modifier(ShakeEffect(animatableData: shakeTrigger))
            .contentShape(Rectangle())
            .onTapGesture {
                isCodeFieldFocused = true
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
    }

    private func codeBox(at index: Int) -> some View {
        let digit = digitAt(index)
        let isFocused = isCodeFieldFocused && currentCursorIndex == index

        return ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.06))

            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    isFocused ? Color.accentColor : Color.white.opacity(0.12),
                    lineWidth: isFocused ? 1.5 : 1
                )

            if digit.isEmpty {
                if isFocused {
                    RoundedRectangle(cornerRadius: 1, style: .continuous)
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 2, height: 28)
                }
            } else {
                Text(digit)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)
            }
        }
        .frame(width: 52, height: 58)
    }

    private var hiddenCodeField: some View {
        TextField("", text: codeBinding)
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
            .focused($isCodeFieldFocused)
            .opacity(0.001)
            .frame(width: 1, height: 1)
            .accessibilityHidden(true)
    }

    private var codeBinding: Binding<String> {
        Binding(
            get: { code },
            set: { newValue in
                code = String(newValue.filter(\.isNumber).prefix(codeLength))
            }
        )
    }

    private func digitAt(_ index: Int) -> String {
        guard index < code.count else { return "" }
        let array = Array(code)
        return String(array[index])
    }

    private var currentCursorIndex: Int {
        min(code.count, codeLength - 1)
    }

    private func resendCode() {
        guard cooldownRemaining == 0 else { return }
        isSending = true

        cooldownRemaining = 30
        code = ""
        errorMessage = nil
        isHandlingFailure = false
        isCodeFieldFocused = true

        isSending = false
    }

    private func completeIfPossible() {
        guard canContinue else { return }

        let success = authSession.loginWithSMS(
            countryCode: countryCode,
            phoneNumber: phoneNumber,
            code: code
        )

        guard success else {
            isHandlingFailure = true
            errorMessage = "Incorrect verification code."

            withAnimation(.easeInOut(duration: 0.4)) {
                shakeTrigger += 1
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                code = ""
                isCodeFieldFocused = true
                isHandlingFailure = false
            }

            return
        }

        onLoginSuccess()
    }

    private var isCodeComplete: Bool {
        code.count == codeLength
    }

    private var canContinue: Bool {
        isCodeComplete && !isHandlingFailure
    }

    private var maskedPhoneNumber: String {
        guard phoneNumber.count >= 5 else { return phoneNumber }
        let prefix = phoneNumber.prefix(3)
        let suffix = phoneNumber.suffix(2)
        return "\(prefix)****\(suffix)"
    }
}

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit: CGFloat = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let translationX = amount * sin(animatableData * .pi * shakesPerUnit)
        return ProjectionTransform(
            CGAffineTransform(translationX: translationX, y: 0)
        )
    }
}

#Preview {
    NavigationStack {
        SMSCodeEntryView(countryCode: .cn, phoneNumber: "16666666666") {
        }
        .environmentObject(AuthSession())
    }
}
