"""Bedrock Converse forced-tool-use structured extraction pattern.

Definition-neutral extraction pattern: works for any task shaped like "read
this input and give me back specific fields" -- structured fields from an
image, a document, or a block of text, a classification label with a
confidence score, or any other schema-shaped output.

Verified against anthropic.claude-sonnet-5 via the us.anthropic.claude-sonnet-5
cross-region inference profile. Re-verify the model/profile ID and the
image/document format list if using a different model -- see pitfalls.md
item 5 for the inference-profile requirement and deprecated-field trap.
"""

from __future__ import annotations

from typing import Any

# Bedrock Converse image content blocks accept these formats directly.
IMAGE_FORMATS_BY_CONTENT_TYPE = {
    "image/jpeg": "jpeg",
    "image/png": "png",
    "image/gif": "gif",
    "image/webp": "webp",
    # NOT supported directly as an image block: image/heic. Convert first,
    # or reject at upload time, if the project needs to accept HEIC.
}

# Bedrock Converse document content blocks accept these formats directly.
DOCUMENT_FORMATS_BY_CONTENT_TYPE = {
    "application/pdf": "pdf",
    "application/msword": "doc",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document": "docx",
}

EXTRACT_TOOL_NAME = "record_extraction"


def build_extraction_tool_spec(properties: dict[str, dict[str, Any]], required: list[str]) -> dict[str, Any]:
    """Build a Converse toolSpec for forced structured extraction.

    Args:
        properties: JSON Schema property definitions for each field to extract,
            e.g. {"fieldName": {"type": "string", "description": "..."}, ...}.
        required: Names of properties the model must always populate.

    Returns:
        A toolSpec dict ready to place in `toolConfig.tools`.
    """
    return {
        "toolSpec": {
            "name": EXTRACT_TOOL_NAME,
            "description": "Records the structured fields read from the attached input.",
            "inputSchema": {"json": {"type": "object", "properties": properties, "required": required}},
        }
    }


def build_content_block(content_type: str, raw_bytes: bytes) -> dict[str, Any]:
    """Build the appropriate Converse content block for an image or document.

    Args:
        content_type: The MIME type of the uploaded file.
        raw_bytes: The raw file bytes.

    Returns:
        A content block dict (either `{"image": ...}` or `{"document": ...}`)
        ready to place in a Converse `messages[].content` list.

    Raises:
        ValueError: If the content type is not supported by Converse directly.
    """
    if content_type in IMAGE_FORMATS_BY_CONTENT_TYPE:
        return {
            "image": {
                "format": IMAGE_FORMATS_BY_CONTENT_TYPE[content_type],
                "source": {"bytes": raw_bytes},
            }
        }
    if content_type in DOCUMENT_FORMATS_BY_CONTENT_TYPE:
        return {
            "document": {
                "format": DOCUMENT_FORMATS_BY_CONTENT_TYPE[content_type],
                "name": "attachment",
                "source": {"bytes": raw_bytes},
            }
        }
    raise ValueError(f"Unsupported content type for Converse: {content_type}")


def extract_via_forced_tool_use(
    bedrock_runtime: Any,
    model_id: str,
    content_block: dict[str, Any],
    instruction_text: str,
    tool_spec: dict[str, Any],
) -> dict[str, Any]:
    """Call Converse with forced tool-use and return the extracted fields.

    Args:
        bedrock_runtime: A boto3 bedrock-runtime client.
        model_id: The model ID or inference profile ID to invoke (see
            pitfalls.md item 5a -- often must be an inference profile, not
            the bare model ID).
        content_block: An image or document content block from
            `build_content_block`.
        instruction_text: The instruction telling the model what to read and
            which tool to call.
        tool_spec: A toolSpec dict from `build_extraction_tool_spec`.

    Returns:
        The `input` dict from the model's forced tool-use call, matching the
        tool's input schema exactly.

    Raises:
        ValueError: If the model does not return the expected tool-use block.
    """
    tool_name = tool_spec["toolSpec"]["name"]

    response = bedrock_runtime.converse(
        modelId=model_id,
        messages=[{"role": "user", "content": [content_block, {"text": instruction_text}]}],
        toolConfig={
            "tools": [tool_spec],
            "toolChoice": {"tool": {"name": tool_name}},
        },
        # Deliberately no inferenceConfig -- see pitfalls.md item 5b. Add
        # specific fields back only after confirming the exact model
        # accepts them.
    )

    for block in response["output"]["message"]["content"]:
        tool_use = block.get("toolUse")
        if tool_use and tool_use["name"] == tool_name:
            return tool_use["input"]

    raise ValueError(f"Bedrock did not return the expected {tool_name} tool call.")


# --- Example usage -----------------------------------------------------
#
# tool_spec = build_extraction_tool_spec(
#     properties={
#         "fieldOne": {"type": "string", "description": "First extracted field."},
#         "fieldTwo": {"type": "number", "description": "Second extracted field, numeric."},
#         "confidence": {"type": "number", "description": "Confidence (0.0-1.0) in the extraction."},
#     },
#     required=["fieldOne", "fieldTwo", "confidence"],
# )
# content_block = build_content_block(content_type, raw_bytes)
# fields = extract_via_forced_tool_use(
#     bedrock_runtime, "us.<model-id>", content_block,
#     "Read this input and call record_extraction with fieldOne, fieldTwo, and your confidence.",
#     tool_spec,
# )
