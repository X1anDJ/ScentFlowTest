//
//  LoginView.swift
//

import SwiftUI

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authSession: AuthSession

    @State private var mode: LoginMode = .code
    @State private var selectedCountryCode: SupportedCountryCode = .us
    @State private var phoneNumber: String = ""
    @State private var password: String = ""
    @State private var agreedToTerms: Bool = false
    @State private var showCountryPicker = false
    @State private var navigateToSMS = false
    @State private var errorMessage: String?
    @State private var agreementShakeTrigger: CGFloat = 0

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        headerSection

                        Spacer()
                            .frame(height: 20)

                        testHintCard

                        Spacer()
                            .frame(height: 24)

                        inputSection

                        if let errorMessage {
                            Spacer()
                                .frame(height: 14)

                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(.orange)
                        }

                        Spacer()
                            .frame(height: 28)

                        primaryButton

                        Spacer()
                            .frame(height: 24)

                        agreementSection
                            .modifier(AgreementShakeEffect(animatableData: agreementShakeTrigger))

                        Spacer()
                            .frame(height: 40)

                        socialSection
                    }
                    .frame(maxWidth: 420, alignment: .leading)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, 28)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .preferredColorScheme(.dark)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

//            ToolbarItem(placement: .topBarTrailing) {
//                Button("Help") {
//                }
//                .foregroundStyle(.secondary)
//            }
        }
        .confirmationDialog("Country Code", isPresented: $showCountryPicker, titleVisibility: .visible) {
            ForEach(SupportedCountryCode.allCases, id: \.self) { code in
                Button(code.displayName) {
                    selectedCountryCode = code
                }
            }

            Button("Cancel", role: .cancel) { }
        }
        .navigationDestination(isPresented: $navigateToSMS) {
            SMSCodeEntryView(
                countryCode: selectedCountryCode,
                phoneNumber: phoneNumber
            ) {
                dismiss()
            }
            .environmentObject(authSession)
        }
    }

    private var headerSection: some View {
        HStack(alignment: .center) {
            Text(mode.title)
                .font(.title.weight(.bold))
                .foregroundStyle(.primary)

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    mode = mode == .code ? .password : .code
                    errorMessage = nil
                }
            } label: {
                HStack(spacing: 4) {
                    Text(mode.toggleTitle)
                        .font(.body)

                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                }
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    private var testHintCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Test Account")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            Text("+86 16666666666 · Password 0000 · SMS 0000")
                .font(.footnote.monospaced())
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }

    private var inputSection: some View {
        VStack(spacing: 22) {
            phoneInputRow

            if mode == .password {
                passwordInputRow
            }
        }
    }

    private var phoneInputRow: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Button {
                    showCountryPicker = true
                } label: {
                    HStack(spacing: 6) {
                        Text(selectedCountryCode.displayName)
                            .font(.title3)
                            .foregroundStyle(.primary)

                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Text("|")
                    .foregroundStyle(.tertiary)

                TextField(selectedCountryCode.examplePhone, text: phoneBinding)
                    .keyboardType(.numberPad)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(.title3)
                    .foregroundStyle(.primary)
                    .tint(.accentColor)
                    .onChange(of: phoneNumber) { _, _ in
                        errorMessage = nil
                    }
            }

            Divider()
                .overlay(.white.opacity(0.12))
        }
    }

    private var passwordInputRow: some View {
        VStack(spacing: 10) {
            SecureField("Password", text: $password)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.title3)
                .foregroundStyle(.primary)
                .tint(.accentColor)
                .onChange(of: password) { _, _ in
                    errorMessage = nil
                }

            Divider()
                .overlay(.white.opacity(0.12))
        }
    }

    private var primaryButton: some View {
        Button {
            errorMessage = nil

            var hasError = false

            if !agreedToTerms {
                withAnimation(.easeInOut(duration: 0.4)) {
                    agreementShakeTrigger += 1
                }
                hasError = true
            }

            guard isPhoneValid else {
                errorMessage = "Please enter a valid phone number."
                return
            }

            if mode == .password && password.isEmpty {
                errorMessage = "Please enter your password."
                return
            }

            guard !hasError else { return }

            if mode == .code {
                navigateToSMS = true
            } else {
                let success = authSession.loginWithPassword(
                    countryCode: selectedCountryCode,
                    phoneNumber: phoneNumber,
                    password: password
                )

                guard success else {
                    errorMessage = "Incorrect phone number or password."
                    return
                }

                dismiss()
            }
        } label: {
            Text(mode.primaryButtonTitle)
                .font(.headline)
                .foregroundStyle(canSubmit ? .black : .black)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    Capsule(style: .continuous)
                        .fill(canSubmit ? Color.accentColor : Color.gray.opacity(0.45))
                )
        }
        .buttonStyle(.plain)
    }

    private var agreementSection: some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                agreedToTerms.toggle()
                errorMessage = nil
            } label: {
                ZStack {
                    Circle()
                        .strokeBorder(.secondary.opacity(0.5), lineWidth: 1.5)
                        .frame(width: 24, height: 24)

                    if agreedToTerms {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.tint)
                    }
                }
            }
            .buttonStyle(.plain)

            (
                Text("By logging in for the first time, you agree to the ")
                    .foregroundColor(.secondary)
                + Text("Terms of Service")
                    .foregroundColor(.accentColor)
                + Text(" and ")
                    .foregroundColor(.secondary)
                + Text("Privacy Policy")
                    .foregroundColor(.accentColor)
            )
            .font(.caption2)
            .lineSpacing(3)
        }
    }

    private var socialSection: some View {
        VStack(spacing: 22) {
            HStack(spacing: 16) {
                Rectangle()
                    .fill(.white.opacity(0.08))
                    .frame(height: 1)

                Text("Or")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Rectangle()
                    .fill(.white.opacity(0.08))
                    .frame(height: 1)
            }

            HStack(spacing: 34) {
                SocialLoginButton(icon: .asset("wechat"), tint: .green) {
                }

                SocialLoginButton(icon: .asset("google"), tint: .white.opacity(0.9)) {
                }

                SocialLoginButton(icon: .system("phone.fill"), tint: .blue) {
                    mode = .code
                }

                SocialLoginButton(icon: .system("applelogo"), tint: .white.opacity(0.9)) {
                }
            }
        }
    }

    private var phoneBinding: Binding<String> {
        Binding(
            get: { phoneNumber },
            set: { newValue in
                let digits = newValue.filter(\.isNumber)
                phoneNumber = String(digits.prefix(selectedCountryCode.maxDigits))
            }
        )
    }

    private var isPhoneValid: Bool {
        phoneNumber.count >= selectedCountryCode.minDigits &&
        phoneNumber.count <= selectedCountryCode.maxDigits
    }

    private var canSubmit: Bool {
        guard agreedToTerms else { return false }

        switch mode {
        case .code:
            return isPhoneValid
        case .password:
            return isPhoneValid && !password.isEmpty
        }
    }
}

private struct AgreementShakeEffect: GeometryEffect {
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
        LoginView()
            .environmentObject(AuthSession())
    }
}
