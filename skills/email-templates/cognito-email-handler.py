"""
Sample Cognito CustomEmailSender Lambda handler.

Wired up via cognito.UserPoolTriggers(custom_email_sender=...) in CDK.
Cognito invokes this Lambda for every email it would otherwise send (verification,
password reset, MFA, admin-created user, etc.). The verification code arrives
KMS-encrypted; we decrypt it, render an HTML email matching the brand, and send
via SES.

Required env vars:
    KMS_KEY_ID            — the KMS key Cognito uses to encrypt the code
    SES_FROM_ADDRESS      — verified From: address (must be verified in SES)
    SES_CONFIG_SET        — SES configuration set for bounce/complaint tracking
    PRODUCT_NAME          — e.g. "Acme"
    PRIMARY_COLOR         — e.g. "#1a73e8"
    ACCENT_COLOR          — e.g. "#f0f6ff"
    LOGO_URL              — absolute HTTPS URL to logo
    SUPPORT_EMAIL         — support@acme.com
    COMPANY_ADDRESS       — physical mailing address for footer
    UNSUBSCRIBE_URL       — preferences page URL

Templates loaded from emails/ at deploy time (bundled into the Lambda package).
Use Jinja2 for rendering (lightweight, well-supported).
"""

from __future__ import annotations

import base64
import json
import logging
import os
from pathlib import Path
from typing import Any

import boto3
from aws_encryption_sdk import (
    CommitmentPolicy,
    EncryptionSDKClient,
    StrictAwsKmsMasterKeyProvider,
)
from jinja2 import Environment, FileSystemLoader, select_autoescape

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

# ----- Module-level init (runs once per Lambda container) -----

_ses = boto3.client("ses")
_kms_key_id = os.environ["KMS_KEY_ID"]
_ses_from = os.environ["SES_FROM_ADDRESS"]
_ses_config_set = os.environ.get("SES_CONFIG_SET", "")

# AWS Encryption SDK client — Cognito CustomEmailSender uses this format
_crypto_client = EncryptionSDKClient(
    commitment_policy=CommitmentPolicy.REQUIRE_ENCRYPT_REQUIRE_DECRYPT
)
_key_provider = StrictAwsKmsMasterKeyProvider(key_ids=[_kms_key_id])

# Jinja2 templates — assume emails/ is bundled into the Lambda zip
_template_dir = Path(__file__).parent / "emails"
_jinja_env = Environment(
    loader=FileSystemLoader(_template_dir),
    autoescape=select_autoescape(["html", "xml"]),
)

# Brand context (passed into every render)
_BRAND_CONTEXT = {
    "product_name": os.environ["PRODUCT_NAME"],
    "primary_color": os.environ["PRIMARY_COLOR"],
    "accent_color": os.environ["ACCENT_COLOR"],
    "logo_url": os.environ["LOGO_URL"],
    "support_email": os.environ["SUPPORT_EMAIL"],
    "company_address": os.environ["COMPANY_ADDRESS"],
    "unsubscribe_url": os.environ["UNSUBSCRIBE_URL"],
}

# Map Cognito trigger source → (html template, txt template, subject)
_TEMPLATES = {
    "CustomEmailSender_SignUp":           ("verification.html",   "verification.txt",   "Confirm your {product_name} account"),
    "CustomEmailSender_ResendCode":       ("verification.html",   "verification.txt",   "Your {product_name} verification code"),
    "CustomEmailSender_ForgotPassword":   ("password-reset.html", "password-reset.txt", "Reset your {product_name} password"),
    "CustomEmailSender_UpdateUserAttribute": ("verification.html", "verification.txt",  "Confirm your new email"),
    "CustomEmailSender_VerifyUserAttribute": ("verification.html", "verification.txt",  "Verify your email"),
    "CustomEmailSender_AdminCreateUser":  ("welcome.html",        "welcome.txt",        "Welcome to {product_name}"),
    "CustomEmailSender_AccountTakeOverNotification": (
        "security-alert.html", "security-alert.txt", "Security alert for your {product_name} account"
    ),
}


def _decrypt_code(encrypted_b64: str) -> str:
    """Cognito sends the verification code base64-encoded + KMS-encrypted."""
    ciphertext = base64.b64decode(encrypted_b64)
    plaintext, _ = _crypto_client.decrypt(
        source=ciphertext, key_provider=_key_provider
    )
    return plaintext.decode("utf-8")


def _render(template_name: str, context: dict[str, Any]) -> str:
    template = _jinja_env.get_template(template_name)
    return template.render(**_BRAND_CONTEXT, **context)


def lambda_handler(event: dict[str, Any], context: Any) -> dict[str, Any]:
    """Cognito CustomEmailSender entry point.

    Event shape (abbreviated):
      {
        "request": {
          "type": "customEmailSenderRequestV1",
          "code": "<base64 KMS-encrypted code>",
          "userAttributes": {"email": "user@example.com", "name": "Alex", ...},
          "clientMetadata": {...}
        },
        "triggerSource": "CustomEmailSender_SignUp" | "CustomEmailSender_ForgotPassword" | ...
      }
    """
    logger.info("Cognito email trigger", extra={"trigger": event.get("triggerSource")})

    trigger = event["triggerSource"]
    if trigger not in _TEMPLATES:
        logger.warning("Unknown trigger source: %s — skipping", trigger)
        return {}

    user_attrs = event["request"]["userAttributes"]
    encrypted_code = event["request"]["code"]
    code = _decrypt_code(encrypted_code) if encrypted_code else ""

    html_template, txt_template, subject_pattern = _TEMPLATES[trigger]

    context_data = {
        "user_name": user_attrs.get("name") or user_attrs.get("given_name") or "there",
        "verification_code": code,
        "cta_url": user_attrs.get("custom:cta_url", ""),
    }

    html_body = _render(html_template, context_data)
    text_body = _render(txt_template, context_data)
    subject = subject_pattern.format(product_name=_BRAND_CONTEXT["product_name"])

    send_kwargs: dict[str, Any] = {
        "Source": _ses_from,
        "Destination": {"ToAddresses": [user_attrs["email"]]},
        "Message": {
            "Subject": {"Data": subject, "Charset": "UTF-8"},
            "Body": {
                "Html": {"Data": html_body, "Charset": "UTF-8"},
                "Text": {"Data": text_body, "Charset": "UTF-8"},
            },
        },
    }
    if _ses_config_set:
        send_kwargs["ConfigurationSetName"] = _ses_config_set

    response = _ses.send_email(**send_kwargs)
    logger.info(
        "Email sent",
        extra={
            "trigger": trigger,
            "message_id": response["MessageId"],
            "recipient": user_attrs["email"],
        },
    )

    return {}


# ============================================================================
# CDK wiring (reference — put in your stack.py, not here)
# ============================================================================
#
# from aws_cdk import aws_cognito as cognito, aws_kms as kms
# from aws_cdk.aws_lambda_python_alpha import PythonFunction
# from aws_cdk.aws_lambda import Runtime
#
# email_key = kms.Key(self, "CognitoEmailKey", enable_key_rotation=True)
#
# email_lambda = PythonFunction(self, "CognitoEmailHandler",
#     runtime=Runtime.PYTHON_3_14,
#     entry="cdk-backend/lambda/functions/cognito_email",
#     index="cognito_email.py",
#     environment={
#         "KMS_KEY_ID": email_key.key_id,
#         "SES_FROM_ADDRESS": "no-reply@yourdomain.com",
#         "SES_CONFIG_SET": "default",
#         "PRODUCT_NAME": "Acme",
#         "PRIMARY_COLOR": "#1a73e8",
#         "ACCENT_COLOR": "#f0f6ff",
#         "LOGO_URL": "https://cdn.yourdomain.com/logo.png",
#         "SUPPORT_EMAIL": "support@yourdomain.com",
#         "COMPANY_ADDRESS": "Acme Inc., 123 Example St, Calgary, AB",
#         "UNSUBSCRIBE_URL": "https://app.yourdomain.com/preferences",
#     },
# )
# email_key.grant_decrypt(email_lambda)
# email_lambda.add_to_role_policy(iam.PolicyStatement(
#     actions=["ses:SendEmail", "ses:SendRawEmail"],
#     resources=["*"],  # tighten to specific identity ARNs in production
# ))
#
# user_pool = cognito.UserPool(self, "UserPool",
#     lambda_triggers=cognito.UserPoolTriggers(
#         custom_email_sender=cognito.CustomEmailSender(
#             function=email_lambda,
#             kms_key=email_key,
#         ),
#     ),
#     # ... rest of pool config
# )
