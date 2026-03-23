"""
CLI validator for OCPP payloads using the Python ocpp library.

Usage:
    uv run python validate.py <action> <version> <msg_type> <json_payload>

Arguments:
    action      OCPP action name, e.g. "BootNotification"
    version     OCPP version: "1.6" or "2.0.1"
    msg_type    "request" or "response"
    json_payload  JSON string of the payload dict

Exit codes:
    0  valid
    1  validation error (message printed to stderr)
    2  usage error
"""

import json
import sys

from ocpp.messages import Call, CallResult, _validate_payload


def main() -> int:
    if len(sys.argv) != 5:
        print(
            f"Usage: {sys.argv[0]} <action> <version> <msg_type> <json_payload>",
            file=sys.stderr,
        )
        return 2

    action, version, msg_type, raw = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]

    try:
        payload = json.loads(raw)
    except json.JSONDecodeError as e:
        print(f"Invalid JSON: {e}", file=sys.stderr)
        return 1

    if msg_type == "request":
        message = Call(unique_id="1", action=action, payload=payload)
    elif msg_type == "response":
        message = CallResult(unique_id="1", action=action, payload=payload)
    else:
        print(f"msg_type must be 'request' or 'response', got '{msg_type}'", file=sys.stderr)
        return 2

    try:
        _validate_payload(message, ocpp_version=version)
        return 0
    except Exception as e:
        print(f"{type(e).__name__}: {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
