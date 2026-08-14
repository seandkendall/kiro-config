---
name: cognito-passkey-auth
description: 'Amazon Cognito — Custom UI with Passkeys, Social Login & Face ID. Reference skill (loaded via skill:// from the ios agent).'
---

# Amazon Cognito — Custom UI with Passkeys, Social Login & Face ID

## Overview

Full custom authentication UI (no Hosted UI) using Cognito User Pools with:

- Email + Password (standard)
- Sign in with Apple
- Sign in with Google
- Passkey / WebAuthn (FIDO2)
- Face ID / Touch ID (biometric after initial auth)
- Magic Link (passwordless email)

## CDK Configuration

### User Pool

```python
from aws_cdk import (
    aws_cognito as cognito,
    Duration,
)

user_pool = cognito.UserPool(self, 'RoadCastUserPool',
    user_pool_name='roadcast-users',
    self_sign_up_enabled=True,
    sign_in_aliases=cognito.SignInAliases(email=True, phone=True),
    auto_verify=cognito.AutoVerifiedAttrs(email=True),
    standard_attributes=cognito.StandardAttributes(
        email=cognito.StandardAttribute(required=True, mutable=True),
        fullname=cognito.StandardAttribute(required=True, mutable=True),
        phone_number=cognito.StandardAttribute(required=False, mutable=True),
    ),
    custom_attributes={
        'avatar_url': cognito.StringAttribute(mutable=True),
        'preferences': cognito.StringAttribute(mutable=True),
    },
    password_policy=cognito.PasswordPolicy(
        min_length=8,
        require_lowercase=True,
        require_uppercase=True,
        require_digits=True,
        require_symbols=False,
        temp_valid_duration=Duration.days(7),
    ),
    account_recovery=cognito.AccountRecovery.EMAIL_ONLY,
    removal_policy=RemovalPolicy.RETAIN,
    mfa=cognito.Mfa.OPTIONAL,
    mfa_second_factor=cognito.MfaSecondFactor(sms=True, otp=True),
)
```

### App Client (Custom UI — no Hosted UI)

```python
app_client = user_pool.add_client('RoadCastMobileClient',
    user_pool_client_name='roadcast-ios',
    generate_secret=False,  # Public client for mobile
    auth_flows=cognito.AuthFlow(
        user_password=True,       # Email + password
        user_srp=True,            # Secure Remote Password
        custom=True,              # Custom auth (magic link, passkey)
    ),
    o_auth=cognito.OAuthSettings(
        flows=cognito.OAuthFlows(authorization_code_grant=True),
        scopes=[cognito.OAuthScope.OPENID, cognito.OAuthScope.EMAIL, cognito.OAuthScope.PROFILE],
        callback_urls=['roadcast://auth/callback'],
        logout_urls=['roadcast://auth/logout'],
    ),
    prevent_user_existence_errors=True,
    access_token_validity=Duration.hours(1),
    id_token_validity=Duration.hours(1),
    refresh_token_validity=Duration.days(30),
)
```

### Social Identity Providers

```python
# Sign in with Apple
apple_provider = cognito.UserPoolIdentityProviderApple(self, 'AppleProvider',
    user_pool=user_pool,
    client_id='com.roadcast.app',
    team_id='YOUR_TEAM_ID',
    key_id='YOUR_KEY_ID',
    private_key='-----BEGIN PRIVATE KEY-----\n...',
    scopes=['email', 'name'],
    attribute_mapping=cognito.AttributeMapping(
        email=cognito.ProviderAttribute.APPLE_EMAIL,
        fullname=cognito.ProviderAttribute.APPLE_NAME,
    ),
)

# Sign in with Google
google_provider = cognito.UserPoolIdentityProviderGoogle(self, 'GoogleProvider',
    user_pool=user_pool,
    client_id='YOUR_GOOGLE_CLIENT_ID',
    client_secret_value=SecretValue.secrets_manager('google-oauth-secret'),
    scopes=['email', 'profile', 'openid'],
    attribute_mapping=cognito.AttributeMapping(
        email=cognito.ProviderAttribute.GOOGLE_EMAIL,
        fullname=cognito.ProviderAttribute.GOOGLE_NAME,
        profile_picture=cognito.ProviderAttribute.GOOGLE_PICTURE,
    ),
)
```

## iOS Implementation

### Auth Service (Protocol-Based)

```swift
protocol AuthServiceProtocol: Sendable {
    func signUp(email: String, password: String, name: String) async throws -> AuthResult
    func signIn(email: String, password: String) async throws -> AuthSession
    func signInWithApple() async throws -> AuthSession
    func signInWithGoogle() async throws -> AuthSession
    func signInWithPasskey() async throws -> AuthSession
    func signInWithBiometric() async throws -> AuthSession
    func forgotPassword(email: String) async throws
    func confirmForgotPassword(email: String, code: String, newPassword: String) async throws
    func verifyEmail(code: String) async throws
    func signOut() async throws
    func refreshSession() async throws -> AuthSession
    var currentSession: AuthSession? { get }
}
```

### Cognito SDK (AWS Amplify Auth or raw SDK)

```swift
import AWSCognitoIdentityProvider

final class CognitoAuthService: AuthServiceProtocol {
    private let client: CognitoIdentityProviderClient
    private let userPoolId: String
    private let clientId: String
    private let keychain: KeychainAccess.Keychain

    func signIn(email: String, password: String) async throws -> AuthSession {
        let input = InitiateAuthInput(
            authFlow: .userPasswordAuth,
            authParameters: ["USERNAME": email, "PASSWORD": password],
            clientId: clientId
        )
        let response = try await client.initiateAuth(input: input)

        guard let result = response.authenticationResult else {
            // MFA challenge or other challenge
            throw AuthError.challengeRequired(response.challengeName)
        }

        let session = AuthSession(
            accessToken: result.accessToken!,
            idToken: result.idToken!,
            refreshToken: result.refreshToken!,
            expiresAt: Date().addingTimeInterval(TimeInterval(result.expiresIn))
        )
        try saveToKeychain(session)
        return session
    }
}
```

### Passkey / WebAuthn (FIDO2)

Cognito supports passkeys via custom auth challenge flow:

```swift
// 1. Initiate custom auth
func signInWithPasskey() async throws -> AuthSession {
    // Start authentication with ASAuthorizationController
    let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(
        relyingPartyIdentifier: "roadcast.app"
    )
    let request = provider.createCredentialAssertionRequest(
        challenge: try await fetchChallengeFromCognito()
    )

    let controller = ASAuthorizationController(authorizationRequests: [request])
    controller.delegate = self
    controller.performRequests()

    // After user authenticates with passkey/Face ID:
    // 2. Send assertion to Cognito custom auth Lambda
    // 3. Lambda verifies the assertion
    // 4. Cognito issues tokens
}
```

### Passkey Registration

```swift
func registerPasskey() async throws {
    let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(
        relyingPartyIdentifier: "roadcast.app"
    )
    let request = provider.createCredentialRegistrationRequest(
        challenge: try await fetchRegistrationChallenge(),
        name: currentUser.email,
        userID: Data(currentUser.id.utf8)
    )

    let controller = ASAuthorizationController(authorizationRequests: [request])
    controller.delegate = self
    controller.performRequests()
}
```

### Face ID / Touch ID (Biometric Unlock)

After first successful login, enable biometric for subsequent sessions:

```swift
import LocalAuthentication

func signInWithBiometric() async throws -> AuthSession {
    let context = LAContext()
    var error: NSError?

    guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
        throw AuthError.biometricNotAvailable
    }

    let success = try await context.evaluatePolicy(
        .deviceOwnerAuthenticationWithBiometrics,
        localizedReason: "Sign in to RoadCast"
    )

    guard success else { throw AuthError.biometricFailed }

    // Retrieve refresh token from Keychain (stored after first password login)
    guard let refreshToken = keychain.get("refresh_token") else {
        throw AuthError.noStoredSession
    }

    // Use refresh token to get new access/id tokens
    return try await refreshSession(with: refreshToken)
}
```

### Sign in with Apple

```swift
import AuthenticationServices

func signInWithApple() async throws -> AuthSession {
    let request = ASAuthorizationAppleIDProvider().createRequest()
    request.requestedScopes = [.email, .fullName]

    let controller = ASAuthorizationController(authorizationRequests: [request])
    let result = try await performAppleSignIn(controller)

    // Exchange Apple credential for Cognito tokens via your backend
    let response = try await apiClient.post("/auth/social/apple", body: [
        "identity_token": result.identityToken,
        "authorization_code": result.authorizationCode,
        "user": result.user,
        "name": result.fullName
    ])

    return try JSONDecoder().decode(AuthSession.self, from: response.data)
}
```

### Token Management

```swift
actor TokenManager {
    private let keychain: Keychain
    private var session: AuthSession?

    var isAuthenticated: Bool { session != nil && !session!.isExpired }

    func getValidAccessToken() async throws -> String {
        guard let session else { throw AuthError.notAuthenticated }

        if session.isExpired {
            let refreshed = try await refreshSession(with: session.refreshToken)
            self.session = refreshed
            return refreshed.accessToken
        }
        return session.accessToken
    }

    func saveSession(_ session: AuthSession) throws {
        self.session = session
        try keychain.set(session.accessToken, key: "access_token")
        try keychain.set(session.idToken, key: "id_token")
        try keychain.set(session.refreshToken, key: "refresh_token")
    }

    func clearSession() throws {
        session = nil
        try keychain.removeAll()
    }
}
```

## Auth Screens (SwiftUI)

### Required Screens

1. **LoginView** — email/password fields, social login buttons, Face ID button, passkey button, "Forgot password?" link, "Create account" link
2. **RegistrationView** — name, email, password, confirm password, terms checkbox, social signup buttons
3. **ForgotPasswordView** — email input, submit button
4. **ResetPasswordView** — verification code, new password, confirm password
5. **EmailVerificationView** — 6-digit code input (auto-advance between fields)
6. **MFASetupView** — QR code for authenticator app, manual code entry

### UX Requirements

- Social login buttons at TOP (lowest friction first)
- "OR" divider between social and email
- Face ID / Passkey as one-tap options (prominent placement)
- Password field: show/hide toggle, strength indicator
- All fields: clear validation errors on edit
- Loading states on all buttons
- Error messages: inline (not alerts), specific and actionable
- Auto-focus first field on appear
- Keyboard aware: scroll up when keyboard covers fields
- Haptic feedback on successful login

## Lambda Triggers (Custom Auth)

For passkey verification, you need these Cognito Lambda triggers:

```python
# Define Auth Challenge
def define_auth_challenge(event, context):
    if event['request']['session'][-1]['challengeResult']:
        event['response']['issueTokens'] = True
    else:
        event['response']['challengeName'] = 'CUSTOM_CHALLENGE'
    return event

# Create Auth Challenge
def create_auth_challenge(event, context):
    # Generate WebAuthn challenge
    challenge = generate_webauthn_challenge(event['request']['userAttributes']['sub'])
    event['response']['publicChallengeParameters'] = {'challenge': challenge}
    event['response']['privateChallengeParameters'] = {'challenge': challenge}
    return event

# Verify Auth Challenge Response
def verify_auth_challenge(event, context):
    # Verify the WebAuthn assertion against stored credential
    is_valid = verify_webauthn_assertion(
        event['request']['challengeAnswer'],
        event['request']['privateChallengeParameters']['challenge']
    )
    event['response']['answerCorrect'] = is_valid
    return event
```

## Security Requirements

1. Tokens stored in iOS Keychain (NEVER UserDefaults)
2. Refresh token rotation enabled
3. Access tokens: 1 hour validity
4. Refresh tokens: 30 days validity (auto-logout after)
5. Certificate pinning for auth API calls
6. Prevent user enumeration (Cognito: `prevent_user_existence_errors=True`)
7. Rate limiting on auth endpoints (API Gateway throttling)
8. PKCE flow for OAuth (required for public clients)
