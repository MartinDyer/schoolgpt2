from __future__ import annotations

import logging
import time
import base64

from reporting.models import EmailMessage
from reporting.runtime import get_settings


class EmailSender:
    def send(self, message: EmailMessage) -> None:  # pragma: no cover - interface only
        raise NotImplementedError


class MockEmailSender(EmailSender):
    def send(self, message: EmailMessage) -> None:
        logging.info("Mock email send", extra={"subject": message.subject, "recipients": list(message.recipients)})


class AzureCommunicationServicesEmailSender(EmailSender):
    def __init__(self, connection_string: str) -> None:
        self.connection_string = connection_string

    def send(self, message: EmailMessage) -> None:
        from azure.communication.email import EmailClient

        settings = get_settings()
        client = EmailClient.from_connection_string(self.connection_string)
        poller = client.begin_send(
            {
                "senderAddress": settings.email_from,
                "recipients": {
                    "to": [{"address": recipient} for recipient in message.recipients],
                },
                "content": {
                    "subject": message.subject,
                    "html": message.html_body,
                },
                "attachments": [
                    {
                        "name": attachment.name,
                        "attachmentType": attachment.content_type,
                        "contentType": attachment.content_type,
                        "contentInBase64": base64.b64encode(attachment.content_bytes).decode("ascii"),
                    }
                    for attachment in message.attachments
                ],
                "headers": {
                    "x-ms-mail-priority": "normal",
                },
            }
        )
        result = poller.result()
        status = getattr(result, "status", None) or getattr(result, "status", "unknown")
        logging.info("ACS email send complete", extra={"subject": message.subject, "status": status})


def send_with_retry(sender: EmailSender, message: EmailMessage, max_attempts: int = 3) -> None:
    last_error: Exception | None = None
    for attempt in range(1, max_attempts + 1):
        try:
            sender.send(message)
            return
        except Exception as exc:  # pragma: no cover - exercised via tests using mocks
            last_error = exc
            logging.warning(
                "Email send attempt failed",
                extra={"attempt": attempt, "max_attempts": max_attempts, "error": str(exc)},
            )
            if attempt < max_attempts:
                time.sleep(2 ** (attempt - 1))
    if last_error is not None:
        raise last_error


def get_email_sender() -> EmailSender:
    settings = get_settings()
    provider = settings.email_provider.lower()
    if provider == "mock":
        return MockEmailSender()
    if provider == "azure_communication_services":
        return AzureCommunicationServicesEmailSender(settings.acs_connection_string)
    raise RuntimeError(f"Unsupported email provider: {settings.email_provider}")
